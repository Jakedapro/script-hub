-- Studio-only test rig for gui.lua. Studio clients can't loadstring and a Script's Source is capped at
-- 200,000 characters, so this cuts gui.lua along its own seams into ModuleScripts (no code is changed:
-- the runtime header + boot, the SOURCES functions, and the TREE literal split at the root's children)
-- and adds a LocalScript that runs the result twice, the second time to check the duplicate guard.
--
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local LIMIT = 190000
local HELPERS = "C, CF, U, U2, V2, V3, R, NR, E, F, CS, NS"

-- start/end offsets of each child node in the root's children list (4th element of the root node)
local function rootChildren(tree)
	local depth, part, inString = 0, 1, false
	local spans, childStart, listOpen, listClose = {}, nil, nil, nil
	local i, n = 1, #tree
	while i <= n do
		local c = string.byte(tree, i)
		if inString then
			if c == 92 then -- backslash: skip the escaped character
				i += 1
			elseif c == 34 then
				inString = false
			end
		elseif c == 34 then
			inString = true
		elseif c == 123 then -- {
			depth += 1
			if depth == 2 and part == 4 then
				listOpen = i
			elseif depth == 3 and listOpen and not listClose then
				childStart = i
			end
		elseif c == 125 then -- }
			if depth == 3 and childStart then
				table.insert(spans, {childStart, i})
				childStart = nil
			elseif depth == 2 and listOpen and not listClose then
				listClose = i
			end
			depth -= 1
		elseif c == 44 and depth == 1 then
			part += 1
		end
		i += 1
	end
	return spans, listOpen, listClose
end

local function module(name, source, parent)
	assert(#source < 200000, name .. " is too big: " .. #source)
	local m = Instance.new("ModuleScript")
	m.Name = name
	m.Source = source
	m.Parent = parent
	return m
end

local harness = {}

function harness.uninstall()
	for _, item in {ReplicatedStorage:FindFirstChild("BundleTest") or false, StarterPlayerScripts:FindFirstChild("BundleRunner") or false} do
		if item then
			item:Destroy()
		end
	end
end

function harness.install(port)
	pcall(harness.uninstall)
	local src = HttpService:GetAsync(string.format("http://127.0.0.1:%d/gui.lua", port or 8768))
	local sourcesAt = assert(src:find("\nlocal SOURCES = {}\n", 1, true))
	local treeAt = assert(src:find("\nlocal TREE = ", 1, true))
	local bootAt = assert(src:find("\n\nlocal problems = {}", 1, true))
	local runtime = src:sub(1, sourcesAt)
	local sourcesText = src:sub(sourcesAt + #"\nlocal SOURCES = {}\n", treeAt)
	local tree = src:sub(treeAt + #"\nlocal TREE = ", bootAt)
	local boot = src:sub(bootAt)

	local folder = Instance.new("Folder")
	folder.Name = "BundleTest"

	-- SOURCES: whole `-- path\nSOURCES[i] = function ... end` blocks, packed under the limit
	local blocks, from = {}, 1
	while true do
		local nextAt = sourcesText:find("\n-- [^\n]+\nSOURCES%[", from + 1)
		table.insert(blocks, sourcesText:sub(from, (nextAt or #sourcesText + 1) - 1))
		if not nextAt then
			break
		end
		from = nextAt
	end
	local sourceParts, current = {}, {}
	local size = 0
	for _, block in blocks do
		if size + #block > LIMIT and #current > 0 then
			table.insert(sourceParts, table.concat(current))
			current, size = {}, 0
		end
		table.insert(current, block)
		size += #block
	end
	table.insert(sourceParts, table.concat(current))
	for i, part in sourceParts do
		module("Sources" .. i, "return function(SOURCES)\n" .. part .. "\nend", folder)
	end

	-- TREE: the root's children go into parts; the root itself stays in the main module
	local spans, listOpen, listClose = rootChildren(tree)
	assert(#spans > 0 and listOpen and listClose, "couldn't find the root's children")
	local treeParts, chunk, chunkSize = {}, {}, 0
	for _, span in spans do
		local text = tree:sub(span[1], span[2])
		if chunkSize + #text > LIMIT and #chunk > 0 then
			table.insert(treeParts, chunk)
			chunk, chunkSize = {}, 0
		end
		table.insert(chunk, text)
		chunkSize += #text
	end
	table.insert(treeParts, chunk)
	for i, part in treeParts do
		module("Tree" .. i, "return function(" .. HELPERS .. ")\nreturn {\n" .. table.concat(part, ",\n") .. "}\nend", folder)
	end

	local loader = {"local SOURCES = {}\nlocal parts = script.Parent\n"}
	for i in sourceParts do
		table.insert(loader, string.format("require(parts.Sources%d)(SOURCES)\n", i))
	end
	table.insert(loader, "local CHILDREN = {}\n")
	for i in treeParts do
		table.insert(loader, string.format("for _, child in require(parts.Tree%d)(%s) do table.insert(CHILDREN, child) end\n", i, HELPERS))
	end
	local rootText = tree:sub(1, listOpen - 1) .. "CHILDREN" .. tree:sub(listClose + 1)
	module("Main", "return function()\n" .. runtime .. table.concat(loader) .. "local TREE = " .. rootText .. boot .. "\nend", folder)
	folder.Parent = ReplicatedStorage

	local runner = Instance.new("LocalScript")
	runner.Name = "BundleRunner"
	runner.Source = [[
local run = require(game:GetService("ReplicatedStorage"):WaitForChild("BundleTest"):WaitForChild("Main"))
local t0 = os.clock()
local ok, gui = pcall(run)
script:SetAttribute("FirstRun", tostring(ok) .. " " .. (ok and gui:GetFullName() or tostring(gui)) .. string.format(" %.3fs", os.clock() - t0))
if script:GetAttribute("Once") then
	return
end
task.wait(4)
local oldBox = gui.main.ScrollingFrame.TextBox
local ok2, gui2 = pcall(run)
script:SetAttribute("SecondRun", tostring(ok2) .. " " .. (ok2 and gui2:GetFullName() or tostring(gui2)))
task.wait(1)
local copies = 0
for _, g in game:GetService("Players").LocalPlayer.PlayerGui:GetChildren() do
	if g:IsA("ScreenGui") and g.Name == "ScreenGui" then
		copies += 1
	end
end
script:SetAttribute("Copies", copies)
script:SetAttribute("FirstDestroyed", gui.Parent == nil)
-- the highlighter hides the real TextBox text while attached and restores it when released
script:SetAttribute("OldHighlighterReleased", oldBox.TextTransparency < 1)
]]
	runner.Parent = StarterPlayerScripts
	return string.format("installed: %d source parts, %d tree parts (%d root children)", #sourceParts, #treeParts, #spans)
end

return harness
