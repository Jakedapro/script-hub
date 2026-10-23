-- Bundles StarterGui.ScreenGui (every instance, LocalScript and ModuleScript) into one
-- self-contained gui.lua that an executor runs with a single loadstring.
--
-- Run it from the Studio command bar (Edit mode) with build/devserver.py running:
--   local H = game:GetService("HttpService")
--   print(loadstring(H:GetAsync("http://127.0.0.1:8768/build/bundle.luau"))()())
-- It writes gui.lua and build/assets.txt next to this folder and prints a summary.
-- Options: build({root = <ScreenGui>, port = 8768, output = "gui.lua"}).
--
-- What gets recorded: properties Studio itself would save (ReflectionService "Serialized",
-- no special write permission) that differ from a fresh instance of the class, plus attributes,
-- CollectionService tags and the hierarchy. Script sources are embedded as functions, not strings,
-- so the bundle is syntax-checked as a whole.

local HttpService = game:GetService("HttpService")
local ReflectionService = game:GetService("ReflectionService")
local CollectionService = game:GetService("CollectionService")

local SKIP = {Name = true, Parent = true, Source = true, Capabilities = true, Archivable = true}

-- Permits.Write is a SecurityCapabilities; an empty set means any script can write it
local NO_PERMITS = SecurityCapabilities.new()
local function openWrite(prop)
	local write = prop.Permits and prop.Permits.Write
	return write == nil or write == "" or write == NO_PERMITS
end

local propsCache = {}
local function propertiesOf(class)
	if propsCache[class] then
		return propsCache[class]
	end
	local names = {}
	for _, prop in ReflectionService:GetPropertiesOfClass(class) do
		local engineType = prop.Type and prop.Type.EngineType
		if prop.Serialized and not SKIP[prop.Name] and openWrite(prop) and engineType ~= "RefType" then
			table.insert(names, prop.Name)
		end
	end
	table.sort(names)
	propsCache[class] = names
	return names
end

local defaults = {}
local function defaultOf(class)
	if defaults[class] == nil then
		local ok, instance = pcall(Instance.new, class)
		defaults[class] = ok and instance or false
	end
	return defaults[class]
end

local function num(n)
	if n == math.floor(n) and math.abs(n) < 2 ^ 31 then
		return string.format("%d", n)
	end
	return string.format("%.9g", n)
end

local function byte(c)
	local scaled = c * 255
	local rounded = math.floor(scaled + 0.5)
	return math.abs(scaled - rounded) < 1e-4 and rounded or nil
end

local unsupported = {}

-- a Lua expression for a property / attribute value, or nil if the type isn't handled
local function encode(value)
	local kind = typeof(value)
	if kind == "boolean" then
		return tostring(value)
	elseif kind == "number" then
		return num(value)
	elseif kind == "string" then
		return string.format("%q", value)
	elseif kind == "EnumItem" then
		return string.format("E(%q,%q)", tostring(value.EnumType), value.Name)
	elseif kind == "Color3" then
		local r, g, b = byte(value.R), byte(value.G), byte(value.B)
		if r and g and b then
			return string.format("C(%d,%d,%d)", r, g, b)
		end
		return string.format("CF(%s,%s,%s)", num(value.R), num(value.G), num(value.B))
	elseif kind == "UDim" then
		return string.format("U(%s,%s)", num(value.Scale), num(value.Offset))
	elseif kind == "UDim2" then
		return string.format("U2(%s,%s,%s,%s)", num(value.X.Scale), num(value.X.Offset), num(value.Y.Scale), num(value.Y.Offset))
	elseif kind == "Vector2" then
		return string.format("V2(%s,%s)", num(value.X), num(value.Y))
	elseif kind == "Vector3" then
		return string.format("V3(%s,%s,%s)", num(value.X), num(value.Y), num(value.Z))
	elseif kind == "Rect" then
		return string.format("R(%s,%s,%s,%s)", num(value.Min.X), num(value.Min.Y), num(value.Max.X), num(value.Max.Y))
	elseif kind == "Font" then
		return string.format("F(%q,%q,%q)", value.Family, value.Weight.Name, value.Style.Name)
	elseif kind == "NumberRange" then
		return string.format("NR(%s,%s)", num(value.Min), num(value.Max))
	elseif kind == "ColorSequence" then
		local keys = {}
		for _, k in value.Keypoints do
			table.insert(keys, string.format("{%s,%s,%s,%s}", num(k.Time), num(k.Value.R), num(k.Value.G), num(k.Value.B)))
		end
		return "CS(" .. table.concat(keys, ",") .. ")"
	elseif kind == "NumberSequence" then
		local keys = {}
		for _, k in value.Keypoints do
			table.insert(keys, string.format("{%s,%s,%s}", num(k.Time), num(k.Value), num(k.Envelope)))
		end
		return "NS(" .. table.concat(keys, ",") .. ")"
	elseif kind == "BrickColor" then
		return string.format("BrickColor.new(%q)", value.Name)
	end
	unsupported[kind] = (unsupported[kind] or 0) + 1
	return nil
end

local function same(a, b)
	if typeof(a) ~= typeof(b) then
		return false
	end
	if typeof(a) == "number" then
		return math.abs(a - b) < 1e-6
	end
	return a == b
end

local RUNTIME = [==[
if not game:IsLoaded() then
	game.Loaded:Wait()
end
local Players = game:GetService("Players")
while not Players.LocalPlayer do
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end
-- gui.lua: the whole hub GUI in one file. Built from StarterGui.ScreenGui by build/bundle.luau;
-- edit the place and rebuild rather than editing this file.
local CollectionService = game:GetService("CollectionService")

-- one copy at a time: running the file again replaces the GUI (its scripts disconnect on Destroying)
local KEY = "__ArtemisHubGui"
local globals = (typeof(getgenv) == "function" and getgenv()) or shared
if globals[KEY] then
	pcall(function()
		globals[KEY]:Destroy()
	end)
	globals[KEY] = nil
end

local C = Color3.fromRGB
local CF = Color3.new
local U = UDim.new
local U2 = UDim2.new
local V2 = Vector2.new
local V3 = Vector3.new
local R = Rect.new
local NR = NumberRange.new
local function E(enum, item)
	return Enum[enum][item]
end
local function F(family, weight, style)
	return Font.new(family, Enum.FontWeight[weight], Enum.FontStyle[style])
end
local function CS(...)
	local keys = {}
	for i, k in {...} do
		keys[i] = ColorSequenceKeypoint.new(k[1], Color3.new(k[2], k[3], k[4]))
	end
	return ColorSequence.new(keys)
end
local function NS(...)
	local keys = {}
	for i, k in {...} do
		keys[i] = NumberSequenceKeypoint.new(k[1], k[2], k[3])
	end
	return NumberSequence.new(keys)
end
]==]

local BOOT = [==[

local problems = {}
local scriptsByIndex = {}

-- node: {class, name, properties?, children?, attributes?, tags?, scriptIndex?}
local function build(node, parent)
	local ok, instance = pcall(Instance.new, node[1])
	if not ok then
		problems[#problems + 1] = "can't create " .. node[1] .. " (" .. node[2] .. "), skipped"
		return nil
	end
	instance.Name = node[2]
	if node[3] then
		for property, value in node[3] do
			local set, err = pcall(function()
				instance[property] = value
			end)
			if not set then
				problems[#problems + 1] = node[1] .. "." .. property .. ": " .. tostring(err)
			end
		end
	end
	if node[5] then
		for key, value in node[5] do
			instance:SetAttribute(key, value)
		end
	end
	if node[6] then
		for _, tag in node[6] do
			CollectionService:AddTag(instance, tag)
		end
	end
	if node[7] then
		scriptsByIndex[node[7]] = instance
		if instance:IsA("BaseScript") then
			instance.Enabled = false -- the bundle runs it; the engine mustn't try to
		end
	end
	if node[4] then
		for _, child in node[4] do
			build(child, instance)
		end
	end
	instance.Parent = parent
	return instance
end

local gui = build(TREE)
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Enabled = false

local placed = false
for _, target in {
	function()
		return typeof(gethui) == "function" and gethui() or nil
	end,
	function()
		return game:GetService("CoreGui")
	end,
	function()
		return Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	end,
} do
	local ok = pcall(function()
		local parent = target()
		if parent then
			gui.Parent = parent
		end
	end)
	if ok and gui.Parent then
		placed = true
		break
	end
end
if not placed then
	warn("[gui] couldn't parent the ScreenGui anywhere")
	return gui
end
globals[KEY] = gui

for _, problem in problems do
	warn("[gui] " .. problem)
end

if globals.__ArtemisNoStart then
	return gui -- build-only mode, used to compare the tree against Studio
end

local modules, locals = {}, {}
for index, instance in scriptsByIndex do
	if instance:IsA("ModuleScript") then
		modules[instance] = SOURCES[index]
	else
		locals[#locals + 1] = {index = index, instance = instance, run = SOURCES[index]}
	end
end

-- require() inside the bundle: GUI modules run once from SOURCES and are cached; anything else
-- (an asset id, a module the bundle doesn't own) goes to the real require
local cache, loading = {}, {}
local function bundleRequire(target)
	local run = typeof(target) == "Instance" and modules[target]
	if not run then
		return require(target)
	end
	if cache[target] then
		return cache[target].value
	end
	if loading[target] then
		error("circular require of " .. target:GetFullName(), 2)
	end
	loading[target] = true
	local ok, result = xpcall(run, debug.traceback, target, bundleRequire)
	loading[target] = nil
	if not ok then
		error(target.Name .. " failed to load: " .. tostring(result), 2)
	end
	cache[target] = {value = result}
	return result
end

for instance in modules do
	local ok, err = pcall(bundleRequire, instance)
	if not ok then
		warn("[gui] " .. tostring(err))
	end
end

-- Splash first: it hides the window before anything else can show it
table.sort(locals, function(a, b)
	local aSplash, bSplash = a.instance.Name == "Splash", b.instance.Name == "Splash"
	if aSplash ~= bSplash then
		return aSplash
	end
	return a.index < b.index
end)
for _, entry in locals do
	task.spawn(function()
		local ok, err = xpcall(entry.run, debug.traceback, entry.instance, bundleRequire)
		if not ok then
			warn("[gui] " .. entry.instance:GetFullName() .. ": " .. tostring(err))
		end
	end)
end
gui.Enabled = true
return gui
]==]

return function(options)
	options = options or {}
	local root = options.root or game:GetService("StarterGui"):FindFirstChild("ScreenGui")
	assert(root and root:IsA("ScreenGui"), "no ScreenGui to bundle")
	local port = options.port or 8768
	local output = options.output or "gui.lua"

	table.clear(unsupported)
	local sources = {}
	local assets = {}
	local counts = {instances = 0, scripts = 0, properties = 0}
	local refs = {}

	local function noteAsset(value, where)
		for id in tostring(value):gmatch("rbxassetid://%d+") do
			assets[id] = assets[id] or where
		end
		for path in tostring(value):gmatch("rbxasset://[%w_/%.%-]+") do
			assets[path] = assets[path] or where
		end
	end

	local function node(instance, depth)
		counts.instances += 1
		local class = instance.ClassName
		local parts = {string.format("%q", class), string.format("%q", instance.Name)}
		local props = {}
		local default = defaultOf(class)
		for _, name in propertiesOf(class) do
			local ok, value = pcall(function()
				return instance[name]
			end)
			if ok and value ~= nil and not (default and same(value, default[name])) then
				local code = encode(value)
				if code then
					counts.properties += 1
					table.insert(props, (name:match("^[%a_][%w_]*$") and name or string.format("[%q]", name)) .. "=" .. code)
					if typeof(value) == "string" or typeof(value) == "Font" then
						noteAsset(typeof(value) == "Font" and value.Family or value, instance:GetFullName() .. "." .. name)
					end
				end
			end
		end
		-- references to other instances (NextSelection*, etc.) aren't recreated; note any that are set
		for _, prop in ReflectionService:GetPropertiesOfClass(class) do
			if prop.Serialized and prop.Type and prop.Type.EngineType == "RefType" then
				local ok, value = pcall(function()
					return instance[prop.Name]
				end)
				if ok and value ~= nil then
					table.insert(refs, instance:GetFullName() .. "." .. prop.Name)
				end
			end
		end
		table.insert(parts, #props > 0 and "{" .. table.concat(props, ",") .. "}" or "false")

		local children = {}
		for _, child in instance:GetChildren() do
			table.insert(children, node(child, depth + 1))
		end
		table.insert(parts, #children > 0 and "{\n" .. string.rep(" ", depth + 1) .. table.concat(children, ",\n" .. string.rep(" ", depth + 1)) .. "}" or "false")

		local attributes = {}
		for key, value in instance:GetAttributes() do
			local code = encode(value)
			if code then
				table.insert(attributes, string.format("[%q]=%s", key, code))
			end
		end
		local tags = {}
		for _, tag in CollectionService:GetTags(instance) do
			table.insert(tags, string.format("%q", tag))
		end
		local scriptIndex
		if instance:IsA("LuaSourceContainer") then
			counts.scripts += 1
			table.insert(sources, {instance = instance, source = instance.Source})
			scriptIndex = #sources
			noteAsset(instance.Source, instance:GetFullName() .. " (source)")
		end
		if #attributes > 0 or #tags > 0 or scriptIndex then
			table.insert(parts, #attributes > 0 and "{" .. table.concat(attributes, ",") .. "}" or "false")
			table.insert(parts, #tags > 0 and "{" .. table.concat(tags, ",") .. "}" or "false")
			if scriptIndex then
				table.insert(parts, tostring(scriptIndex))
			end
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end

	local tree = node(root, 0)

	local chunks = {
		RUNTIME,
		"\nlocal SOURCES = {}\n",
	}
	for index, entry in sources do
		-- each script runs as a function with its own rebuilt instance as `script` and the bundle's require
		table.insert(chunks, string.format("\n-- %s (%s)\nSOURCES[%d] = function(script, require)\n", entry.instance:GetFullName(), entry.instance.ClassName, index))
		table.insert(chunks, entry.source)
		table.insert(chunks, "\nend\n")
	end
	table.insert(chunks, "\nlocal TREE = " .. tree .. "\n")
	table.insert(chunks, BOOT)
	local bundle = table.concat(chunks)

	local compiled, compileErr = loadstring(bundle, "=gui.lua")
	assert(compiled, "bundle doesn't compile: " .. tostring(compileErr))

	local assetLines = {}
	for id, where in assets do
		table.insert(assetLines, id .. "    first used by " .. where)
	end
	table.sort(assetLines)

	local function save(name, body)
		local ok, res = pcall(HttpService.RequestAsync, HttpService, {
			Url = string.format("http://127.0.0.1:%d/save?name=%s", port, HttpService:UrlEncode(name)),
			Method = "POST",
			Body = body,
		})
		return ok and res.StatusCode == 200, ok and res.Body or tostring(res)
	end
	local savedBundle, bundleMessage = save(output, bundle)
	local savedAssets = save("build/assets.txt", table.concat(assetLines, "\n") .. "\n")

	local unsupportedList = {}
	for kind, n in unsupported do
		table.insert(unsupportedList, kind .. " x" .. n)
	end
	return string.format(
		"%s: %d bytes, %d instances, %d properties, %d scripts, %d assets | saved: %s (%s), assets.txt %s | unsupported value types: %s | unrecreated refs: %s",
		output, #bundle, counts.instances, counts.properties, counts.scripts, #assetLines,
		tostring(savedBundle), bundleMessage, tostring(savedAssets),
		#unsupportedList > 0 and table.concat(unsupportedList, ", ") or "none",
		#refs > 0 and table.concat(refs, ", ") or "none"
	), bundle
end
