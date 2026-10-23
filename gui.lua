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

local SOURCES = {}

-- StarterGui.ScreenGui.main.Topbar.AddTabButton.TabManager (LocalScript)
SOURCES[1] = function(script, require)
local AddTabButton = script.Parent
local Topbar = AddTabButton.Parent
local Tabs = Topbar.Tabs
local FakeTabs = Topbar.FakeTabs
local Accent = FakeTabs.TextButton.Accent
local RunService = game:GetService("RunService")

local Gui = Topbar:FindFirstAncestorOfClass("ScreenGui")
local ButtonFx = require(Gui.ButtonFx)
local tween = ButtonFx.tween
local fast = ButtonFx.FAST
-- opening a tab has its own, slightly quicker feel than the page transitions
local smooth = TweenInfo.new(0.35, Enum.EasingStyle.Quint)
local pop = TweenInfo.new(0.4, Enum.EasingStyle.Back)

local REST_BG, SELECTED_BG = 0.985, 0.95
local REST_CONTENT, SELECTED_CONTENT = 0.85, 0.5

local function tabTransparency(selected)
	return selected and SELECTED_BG or REST_BG
end

local function contentTransparency(selected)
	return selected and SELECTED_CONTENT or REST_CONTENT
end

local getScale = ButtonFx.getScale

local function fadeContent(element, t)
	tween(element.Content.TextLabel, fast, {TextTransparency = t})
	tween(element.Content.ImageButton, fast, {ImageTransparency = t})
	tween(element.Content.ImageLabel, fast, {ImageTransparency = t})
end

-- one highlight that glides to the selected tab
local Highlight = Instance.new("Frame")
Highlight.Name = "Highlight"
Highlight.BackgroundColor3 = Color3.new(1, 1, 1)
Highlight.BackgroundTransparency = tabTransparency(true)
Highlight.BorderSizePixel = 0
Highlight.ZIndex = 0
for _, name in {"UICorner", "UIGradient", "UIStroke", "Accent"} do
	FakeTabs.TextButton[name]:Clone().Parent = Highlight
end
Highlight.Parent = Topbar

local openTabs = {}
local selectedTab = nil
local tabCount = 0

local function selectTab(tab, selected)
	tab.Selected = selected
	tween(tab.Element, fast, {BackgroundTransparency = tabTransparency(false)})
	fadeContent(tab.Element, contentTransparency(selected))
	if selected then
		local accent = Highlight.Accent
		accent.Size = UDim2.new(0, 4, 0, 0)
		tween(accent, pop, {Size = Accent.Size})
	end
end

local function createTab(selected, name, content)
	local element = FakeTabs.FakeTab:Clone()
	element.BackgroundTransparency = 1
	element.Content.TextLabel.TextTransparency = 1
	element.Content.TextLabel.Text = name
	element.Content.ImageButton.ImageTransparency = 1
	element.Content.ImageLabel.ImageTransparency = 1
	element.Content.Position = UDim2.fromOffset(0, 8)
	element.ClipsDescendants = true
	element.Parent = Tabs
	tabCount += 1

	local tab = {
		Element = element,
		Name = name,
		Content = content,
		Selected = selected,
		Id = tabCount,
		SetSelected = selectTab,
	}

	-- open from 0 width, then the content rises in
	task.spawn(function()
		RunService.Heartbeat:Wait()
		local width = element.AbsoluteSize.X / getScale()
		element.AutomaticSize = Enum.AutomaticSize.None
		element.Size = UDim2.new(0, 0, 1, 0)
		tween(element, smooth, {Size = UDim2.new(0, width, 1, 0), BackgroundTransparency = tabTransparency(false)}).Completed:Wait()
		element.AutomaticSize = Enum.AutomaticSize.X
		element.Size = UDim2.new(0, 0, 1, 0)
		element.ClipsDescendants = false
		tween(Tabs, smooth, {CanvasPosition = Vector2.new(math.max(0, Tabs.AbsoluteCanvasSize.X - Tabs.AbsoluteWindowSize.X), 0)})
	end)
	tween(element.Content, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new()})
	selectTab(tab, selected)
	return tab
end

local function addTab(tab)
	local element = tab.Element
	element.Activated:Connect(function()
		if selectedTab == tab then
			return
		end
		selectedTab:SetSelected(false)
		tab:SetSelected(true)
		selectedTab = tab
	end)
	element.MouseEnter:Connect(function()
		if not tab.Selected then
			tween(element, fast, {BackgroundTransparency = ButtonFx.hoverBg(REST_BG)})
			fadeContent(element, ButtonFx.hoverContent(REST_CONTENT))
		end
	end)
	element.MouseLeave:Connect(function()
		if not tab.Selected then
			tween(element, fast, {BackgroundTransparency = tabTransparency(false)})
			fadeContent(element, contentTransparency(false))
		end
	end)

	table.insert(openTabs, tab)
	return tab
end

-- highlight follows the selected tab (handles switching, opening and scrolling)
local hlPos, hlSize
local follow = RunService.RenderStepped:Connect(function(dt)
	if not selectedTab then
		return
	end
	local element = selectedTab.Element
	local scale = getScale()
	local pos = (element.AbsolutePosition - Topbar.AbsolutePosition) / scale
	local size = element.AbsoluteSize / scale
	local alpha = 1 - math.exp(-dt * 18)
	hlPos = hlPos and hlPos:Lerp(pos, alpha) or pos
	hlSize = hlSize and hlSize:Lerp(size, alpha) or size
	Highlight.Position = UDim2.fromOffset(hlPos.X, hlPos.Y)
	Highlight.Size = UDim2.fromOffset(hlSize.X, hlSize.Y)
end)
Gui.Destroying:Once(function()
	follow:Disconnect()
end)

selectedTab = addTab(createTab(true, "@imdooted", ""))

-- the + is 36x36; the hit area makes it thumb-sized without changing how it looks
ButtonFx.hitArea(AddTabButton, Vector2.new(44, 44))
ButtonFx.onActivated(AddTabButton, function()
	local tab = createTab(true, "new" .. tostring(#openTabs) .. ".txt", "")
	for _, other in openTabs do
		if other.Selected then
			other:SetSelected(false)
		end
	end
	selectedTab = addTab(tab)
end)

end

-- StarterGui.ScreenGui.main.ScrollingFrame.LocalScript (LocalScript)
SOURCES[2] = function(script, require)
local TextBox = script.Parent.TextBox
local Line = script.Parent.Line
local Highlighter = require(script.Parent.LuaHighlighter)

-- needs monospace
TextBox.Font = Enum.Font.Code
Line.Font = Enum.Font.Code
Line.TextEditable = false

local highlighter = Highlighter.attach(TextBox, {
	scroller = script.Parent,
	lineNumbers = Line,
	fitCanvas = true,
	onGutterResize = function(width)
		TextBox.AnchorPoint = Vector2.new(0, 0)
		TextBox.Position = UDim2.new(0, width, TextBox.Position.Y.Scale, TextBox.Position.Y.Offset)
		TextBox.Size = UDim2.new(1, -width, TextBox.Size.Y.Scale, TextBox.Size.Y.Offset)
	end,
})
-- its input and Heartbeat connections live on services, so release them with the GUI
script:FindFirstAncestorWhichIsA("LayerCollector").Destroying:Once(function()
	highlighter:Destroy()
end)
end

-- StarterGui.ScreenGui.main.ScrollingFrame.LuaHighlighter (ModuleScript)
SOURCES[3] = function(script, require)
-- syntax highlighting for the editor

local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")

local Highlighter = {}

Highlighter.Theme = {
	text = "#CCCCCC",
	keyword = "#F86D7C",
	bool = "#FFC600",
	builtin = "#84D6F7",
	call = "#FDFBAC",
	string = "#ADF195",
	number = "#FFC600",
	comment = "#666666",
	operator = "#CCCCCC",
	caret = "#FFFFFF",
	currentLine = "#FFFFFF",
	selection = "#264F78",
}

local function set(list)
	local t = {}
	for _, v in list do
		t[v] = true
	end
	return t
end

local KEYWORDS = set({
	"and", "break", "do", "else", "elseif", "end", "for", "function", "if", "in",
	"local", "not", "or", "repeat", "return", "then", "until", "while", "continue", "goto",
})

local BOOLS = set({ "true", "false", "nil", "self" })

local BUILTINS = set({
	"game", "workspace", "script", "plugin", "shared", "_G", "_VERSION",
	"print", "warn", "error", "assert", "pcall", "xpcall", "require", "select",
	"pairs", "ipairs", "next", "type", "typeof", "tostring", "tonumber", "unpack",
	"setmetatable", "getmetatable", "rawget", "rawset", "rawequal", "rawlen",
	"newproxy", "gcinfo", "loadstring", "getfenv", "setfenv",
	"wait", "spawn", "delay", "tick", "time", "elapsedTime",
	"table", "string", "math", "task", "coroutine", "os", "debug", "utf8", "bit32", "buffer",
	"Instance", "Enum", "Vector2", "Vector3", "Vector2int16", "Vector3int16", "CFrame",
	"Color3", "BrickColor", "UDim", "UDim2", "Rect", "Ray", "Region3", "TweenInfo",
	"NumberRange", "NumberSequence", "NumberSequenceKeypoint", "ColorSequence",
	"ColorSequenceKeypoint", "PhysicalProperties", "Random", "DateTime", "Font",
	"getgenv", "getrenv", "getreg", "getgc", "gethui", "cloneref",
})

local ESCAPES = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }

local function escape(s)
	return (string.gsub(s, "[&<>]", ESCAPES))
end

local function wrap(kind, s)
	if s == "" then
		return ""
	end
	return '<font color="' .. Highlighter.Theme[kind] .. '">' .. escape(s) .. "</font>"
end

-- multiline state
local function openState(kind, eq)
	return (kind == "comment" and "c" or "s") .. #eq
end

local function readState(state)
	local kind = string.sub(state, 1, 1) == "c" and "comment" or "string"
	return kind, "]" .. string.rep("=", tonumber(string.sub(state, 2))) .. "]"
end

local function lexLine(line, state)
	local out = {}
	local i, n = 1, #line

	if state then
		local kind, close = readState(state)
		local _, e = string.find(line, close, 1, true)
		if not e then
			return wrap(kind, line), state
		end
		out[#out + 1] = wrap(kind, string.sub(line, 1, e))
		i = e + 1
	end

	while i <= n do
		local c = string.sub(line, i, i)

		local ws = string.match(line, "^%s+", i)
		if ws then
			out[#out + 1] = ws
			i += #ws
			continue
		end

		-- comments
		if c == "-" and string.sub(line, i + 1, i + 1) == "-" then
			local eq = string.match(line, "^%[(=*)%[", i + 2)
			if eq then
				local close = "]" .. eq .. "]"
				local _, e = string.find(line, close, i + 4 + #eq, true)
				if e then
					out[#out + 1] = wrap("comment", string.sub(line, i, e))
					i = e + 1
					continue
				end
				out[#out + 1] = wrap("comment", string.sub(line, i))
				return table.concat(out), openState("comment", eq)
			end
			out[#out + 1] = wrap("comment", string.sub(line, i))
			break
		end

		-- long strings
		if c == "[" then
			local eq = string.match(line, "^%[(=*)%[", i)
			if eq then
				local close = "]" .. eq .. "]"
				local _, e = string.find(line, close, i + 2 + #eq, true)
				if e then
					out[#out + 1] = wrap("string", string.sub(line, i, e))
					i = e + 1
					continue
				end
				out[#out + 1] = wrap("string", string.sub(line, i))
				return table.concat(out), openState("string", eq)
			end
		end

		-- strings
		if c == '"' or c == "'" or c == "`" then
			local j = i + 1
			while j <= n do
				local d = string.sub(line, j, j)
				if d == "\\" then
					j += 2
				elseif d == c then
					break
				else
					j += 1
				end
			end
			out[#out + 1] = wrap("string", string.sub(line, i, j))
			i = j + 1
			continue
		end

		-- numbers
		local num = string.match(line, "^0[xX][%x_]+", i)
			or string.match(line, "^0[bB][01_]+", i)
			or string.match(line, "^%d[%d_]*%.?[%d_]*[eE][%+%-]?%d+", i)
			or string.match(line, "^%d[%d_]*%.?[%d_]*", i)
			or string.match(line, "^%.%d[%d_]*", i)
		if num then
			out[#out + 1] = wrap("number", num)
			i += #num
			continue
		end

		-- words
		local id = string.match(line, "^[%a_][%w_]*", i)
		if id then
			local prev = string.sub(line, i - 1, i - 1)
			local kind
			if KEYWORDS[id] then
				kind = "keyword"
			elseif BOOLS[id] then
				kind = "bool"
			elseif string.match(line, "^%s*[%(\"'{`]", i + #id) then
				kind = "call"
			elseif BUILTINS[id] and prev ~= "." and prev ~= ":" then
				kind = "builtin"
			else
				kind = "text"
			end
			out[#out + 1] = wrap(kind, id)
			i += #id
			continue
		end

		-- operators
		local op = string.match(line, "^[^%w%s_\"'`%[%-]+", i) or c
		out[#out + 1] = wrap("operator", op)
		i += #op
	end

	return table.concat(out), nil
end

local function copyTextProps(from, to)
	to.FontFace = from.FontFace
	to.TextSize = from.TextSize
	to.LineHeight = from.LineHeight
end

-- uiscale fix
local function totalScale(gui)
	local scale = 1
	local node = gui
	while node and not node:IsA("LayerCollector") do
		local s = node:FindFirstChildWhichIsA("UIScale")
		if s then
			scale *= s.Scale
		end
		node = node.Parent
	end
	if node then
		local s = node:FindFirstChildWhichIsA("UIScale")
		if s then
			scale *= s.Scale
		end
	end
	return scale
end

-- auto close
local PAIRS = { ["("] = ")", ["["] = "]", ["{"] = "}", ['"'] = '"', ["'"] = "'", ["`"] = "`" }
local CLOSERS = { [")"] = true, ["]"] = true, ["}"] = true, ['"'] = true, ["'"] = true, ["`"] = true }

local function opensBlock(line)
	line = string.gsub(line, "%-%-.*$", "")
	line = string.gsub(line, "%s+$", "")
	if string.match(line, "^%s*else$") or string.match(line, "^%s*elseif%f[%W]") then
		return "indent"
	end
	if string.match(line, "%f[%w_]then$") or string.match(line, "%f[%w_]do$")
		or string.match(line, "%f[%w_]function%f[%W][^%)]*%)$") then
		return "end"
	end
	if string.match(line, "^%s*repeat$") or string.match(line, "[%(%[{]$") then
		return "indent"
	end
	return nil
end

local function autoClose(old, new, c)
	if c < 2 or #new >= 200000 then
		return nil
	end

	if #new == #old + 1 then
		local before, after = string.sub(new, 1, c - 2), string.sub(new, c)
		if string.sub(old, 1, c - 2) ~= before or string.sub(old, c - 1) ~= after then
			return nil
		end
		local ch = string.sub(new, c - 1, c - 1)
		local nextCh = string.sub(after, 1, 1)

		if ch == "\n" then
			local line = string.match(before, "[^\n]*$")
			local indent = string.match(line, "^[ \t]*")
			local kind = opensBlock(line)
			if kind == "end" then
				local rest = string.match(after, "^[^\n]*")
				local needEnd = string.match(rest, "^[%)%]}]*%s*$") ~= nil
				for l in string.gmatch(string.sub(after, #rest + 1, #rest + 4000), "\n([^\n]*)") do
					if string.find(l, "%S") then
						local ni = string.match(l, "^[ \t]*")
						if #ni > #indent or (ni == indent and string.match(l, "^[ \t]*end%f[%W]")) then
							needEnd = false
						end
						break
					end
				end
				if needEnd then
					return before .. "\n" .. indent .. "\t\n" .. indent .. "end" .. after, #before + #indent + 3
				end
			end
			if kind then
				local last = string.sub(before, -1)
				if PAIRS[last] and nextCh == PAIRS[last] then
					return before .. "\n" .. indent .. "\t\n" .. indent .. after, #before + #indent + 3
				end
				return before .. "\n" .. indent .. "\t" .. after, #before + #indent + 3
			end
			if indent ~= "" then
				return before .. "\n" .. indent .. after, #before + #indent + 2
			end
			return nil
		end

		-- skip over closer
		if CLOSERS[ch] and nextCh == ch then
			return old, c
		end

		local close = PAIRS[ch]
		if close then
			local prev = string.sub(before, -1)
			if close == ch and (string.match(prev, "[%w_]") or string.match(nextCh, "[%w_]")) then
				return nil
			end
			if nextCh == "" or string.match(nextCh, "[%s%)%]},;]") then
				return before .. ch .. close .. after, c
			end
		end
		return nil
	end

	-- delete pair
	if #new == #old - 1 then
		local deleted = string.sub(old, c, c)
		local close = PAIRS[deleted]
		if close and string.sub(new, c, c) == close
			and string.sub(old, 1, c - 1) == string.sub(new, 1, c - 1)
			and string.sub(old, c + 1) == string.sub(new, c) then
			return string.sub(new, 1, c - 1) .. string.sub(new, c + 1), c
		end
	end
	return nil
end

function Highlighter.attach(editor, opts)
	opts = opts or {}
	local scroller = opts.scroller or editor:FindFirstAncestorWhichIsA("ScrollingFrame")
	local lineNumbers = opts.lineNumbers
	local gutterGap = opts.gutterGap or 8

	editor.TextWrapped = false
	editor.TextYAlignment = Enum.TextYAlignment.Top
	editor.TextXAlignment = Enum.TextXAlignment.Left
	editor.MultiLine = true
	editor.ClearTextOnFocus = false
	editor.RichText = false

	local originalTransparency = editor.TextTransparency
	editor.TextTransparency = 1

	local overlay = Instance.new("TextLabel")
	overlay.Name = "SyntaxHighlight"
	overlay.BackgroundTransparency = 1
	overlay.RichText = true
	overlay.TextWrapped = false
	overlay.TextXAlignment = Enum.TextXAlignment.Left
	overlay.TextYAlignment = Enum.TextYAlignment.Top
	overlay.TextColor3 = Color3.fromHex(Highlighter.Theme.text)
	overlay.ZIndex = editor.ZIndex + 2
	overlay.Active = false
	copyTextProps(editor, overlay)
	overlay.Parent = editor

	-- line numbers
	local gutter
	if lineNumbers then
		gutter = Instance.new("TextLabel")
		gutter.Name = "LineNumbers"
		gutter.BackgroundTransparency = 1
		gutter.TextWrapped = false
		gutter.TextXAlignment = Enum.TextXAlignment.Right
		gutter.TextYAlignment = Enum.TextYAlignment.Top
		gutter.TextColor3 = lineNumbers.TextColor3
		gutter.TextTransparency = lineNumbers.TextTransparency
		gutter.ZIndex = editor.ZIndex + 1
		copyTextProps(editor, gutter)
		gutter.Parent = editor.Parent
		lineNumbers.Visible = false
	end

	-- caret + selection
	local caret = Instance.new("Frame")
	caret.Name = "Caret"
	caret.BorderSizePixel = 0
	caret.BackgroundColor3 = Color3.fromHex(Highlighter.Theme.caret)
	caret.ZIndex = editor.ZIndex + 3
	caret.Visible = false
	caret.Parent = editor
	Instance.new("UICorner", caret).CornerRadius = UDim.new(0, 1)

	local currentLine = Instance.new("Frame")
	currentLine.Name = "CurrentLine"
	currentLine.BorderSizePixel = 0
	currentLine.BackgroundColor3 = Color3.fromHex(Highlighter.Theme.currentLine)
	currentLine.BackgroundTransparency = 0.95
	currentLine.ZIndex = editor.ZIndex
	currentLine.Visible = false
	currentLine.Parent = editor

	local selectionPool = {}

	local cache = {}
	local lineStart = {}
	local lineCount = 0
	local lineHeight = 0
	local charWidth = 0
	local gutterWidth = 0
	local dirty = true
	local caretOn = false
	local blinkStart = 0
	local follow = false
	local caretPos = Vector2.zero
	local caretTarget = Vector2.zero
	local connections = {}

	local function measure()
		local params = Instance.new("GetTextBoundsParams")
		params.Font = editor.FontFace
		params.Size = editor.TextSize
		params.Width = 1e5
		params.Text = "M"
		local one = TextService:GetTextBoundsAsync(params)
		params.Text = "M\nM"
		local two = TextService:GetTextBoundsAsync(params)
		params.Text = "MMMMMMMMMM"
		local ten = TextService:GetTextBoundsAsync(params)
		lineHeight = two.Y - one.Y
		charWidth = ten.X / 10
	end

	local function rebuild()
		local lines = string.split(editor.Text, "\n")
		local state = nil
		local pos = 1
		for i, raw in lines do
			lineStart[i] = pos
			pos += #raw + 1
			local src = string.gsub(raw, "\r$", "")
			local entry = cache[i]
			if not (entry and entry.src == src and entry.inState == state) then
				local rich, outState = lexLine(src, state)
				entry = { src = src, inState = state, rich = rich, outState = outState }
				cache[i] = entry
			end
			state = entry.outState
		end
		for i = #lines + 1, #cache do
			cache[i] = nil
			lineStart[i] = nil
		end
		lineCount = #lines
	end

	local function visibleRange()
		if not scroller or lineHeight <= 0 then
			return 1, lineCount
		end
		local scale = totalScale(editor)
		local top = (scroller.AbsolutePosition.Y - editor.AbsolutePosition.Y) / scale
		local first = math.max(1, math.floor(top / lineHeight) + 1 - 5)
		local count = math.ceil(scroller.AbsoluteWindowSize.Y / scale / lineHeight) + 10
		return first, math.max(first, math.min(lineCount, first + count))
	end

	local function lineAt(pos)
		local lo, hi = 1, lineCount
		while lo < hi do
			local mid = (lo + hi + 1) // 2
			if lineStart[mid] <= pos then
				lo = mid
			else
				hi = mid - 1
			end
		end
		return lo
	end

	local function xAt(line, pos)
		local prefix = string.sub(cache[line].src, 1, pos - lineStart[line])
		if prefix == "" then
			return 0
		end
		return TextService:GetTextSize(prefix, editor.TextSize, editor.Font, Vector2.new(1e6, 1e6)).X
	end

	local function posAtLineX(line, x)
		local src = cache[line].src
		local starts = {}
		if utf8.len(src) then
			for p in utf8.codes(src) do
				starts[#starts + 1] = p
			end
		else
			for p = 1, #src do
				starts[p] = p
			end
		end
		local prevW = 0
		for i, p in starts do
			local w = xAt(line, lineStart[line] + (starts[i + 1] or #src + 1) - 1)
			if x < (prevW + w) / 2 then
				return lineStart[line] + p - 1
			end
			prevW = w
		end
		return lineStart[line] + #src
	end

	-- mouse pos
	local function posAt(screen)
		local scale = totalScale(editor)
		local x = (screen.X - editor.AbsolutePosition.X) / scale
		local y = (screen.Y - editor.AbsolutePosition.Y) / scale
		return posAtLineX(math.clamp(math.floor(y / lineHeight) + 1, 1, lineCount), x)
	end

	-- arrow keys
	local NAV = { Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.PageUp, Enum.KeyCode.PageDown, Enum.KeyCode.Home, Enum.KeyCode.End }
	local wantX = nil

	local function navKey()
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			return nil
		end
		for _, key in NAV do
			if UserInputService:IsKeyDown(key) then
				return key
			end
		end
		return nil
	end

	local function navTarget(key, from)
		local line = lineAt(from)
		local src, base = cache[line].src, lineStart[line]
		if key == Enum.KeyCode.Home or key == Enum.KeyCode.End then
			wantX = nil
		end
		if key == Enum.KeyCode.Home then
			local first = base + #string.match(src, "^%s*")
			return from == first and base or first
		elseif key == Enum.KeyCode.End then
			return base + #src
		end
		local step = 1
		if key == Enum.KeyCode.PageUp or key == Enum.KeyCode.PageDown then
			local height = scroller and scroller.AbsoluteWindowSize.Y / totalScale(editor) or 320
			step = math.max(1, math.floor(height / lineHeight) - 1)
		end
		if key == Enum.KeyCode.Up or key == Enum.KeyCode.PageUp then
			step = -step
		end
		wantX = wantX or xAt(line, from)
		return posAtLineX(math.clamp(line + step, 1, lineCount), wantX)
	end

	local function drawCursor(first, last)
		local cursor, anchor = editor.CursorPosition, editor.SelectionStart
		local used = 0
		if dirty then
			return
		end
		local wasOn = caretOn
		caretOn = lineCount > 0 and cursor ~= -1 and editor:IsFocused()
		if caretOn then
			local line = lineAt(cursor)
			caretTarget = Vector2.new(xAt(line, cursor), (line - 1) * lineHeight)
			if not wasOn then
				caretPos = caretTarget
				caret.Position = UDim2.fromOffset(caretPos.X, caretPos.Y)
			end
			caret.Size = UDim2.fromOffset(2, lineHeight)

			if anchor ~= -1 and anchor ~= cursor then
				local a, b = math.min(anchor, cursor), math.max(anchor, cursor)
				local la, lb = lineAt(a), lineAt(b)
				for l = math.max(la, first), math.min(lb, last) do
					local x1 = l == la and xAt(l, a) or 0
					local x2 = l == lb and xAt(l, b) or xAt(l, lineStart[l] + #cache[l].src) + charWidth
					used += 1
					local box = selectionPool[used]
					if not box then
						box = Instance.new("Frame")
						box.Name = "Selection"
						box.BorderSizePixel = 0
						box.BackgroundColor3 = Color3.fromHex(Highlighter.Theme.selection)
						box.ZIndex = editor.ZIndex + 1
						box.Parent = editor
						selectionPool[used] = box
					end
					box.Position = UDim2.fromOffset(x1, (l - 1) * lineHeight)
					box.Size = UDim2.fromOffset(math.max(0, x2 - x1), lineHeight)
					box.Visible = true
				end
			end

			-- follow caret
			if follow and scroller then
				follow = false
				local scale = totalScale(editor)
				local y = editor.AbsolutePosition.Y + (line - 1) * lineHeight * scale
				local top = scroller.AbsolutePosition.Y
				local bottom = top + scroller.AbsoluteWindowSize.Y
				if y < top then
					scroller.CanvasPosition -= Vector2.new(0, (top - y) / scale)
				elseif y + lineHeight * scale > bottom then
					scroller.CanvasPosition += Vector2.new(0, (y + lineHeight * scale - bottom) / scale)
				end
			end
		end
		caret.Visible = caretOn
		currentLine.Visible = caretOn
		currentLine.Size = UDim2.new(1, 0, 0, lineHeight)
		for i = used + 1, #selectionPool do
			selectionPool[i].Visible = false
		end
	end

	local function render()
		local first, last = visibleRange()
		local parts = table.create(math.max(0, last - first + 1))
		for i = first, last do
			parts[#parts + 1] = cache[i] and cache[i].rich or ""
		end
		local y = (first - 1) * lineHeight
		local height = math.max(1, last - first + 1) * lineHeight
		overlay.Text = table.concat(parts, "\n")
		overlay.Position = UDim2.fromOffset(0, y)
		overlay.Size = UDim2.new(1, 0, 0, height)
		if gutter then
			local nums = table.create(math.max(0, last - first + 1))
			for i = first, last do
				nums[#nums + 1] = tostring(i)
			end
			gutter.Text = table.concat(nums, "\n")
			gutter.Position = UDim2.new(0, 0, editor.Position.Y.Scale, editor.Position.Y.Offset + y)
			gutter.Size = UDim2.fromOffset(gutterWidth, height)
		end
		drawCursor(first, last)
	end

	local function updateGutter()
		if not gutter then
			return
		end
		local width = math.ceil(math.max(2, #tostring(lineCount)) * charWidth) + 4
		if width ~= gutterWidth then
			gutterWidth = width
			if opts.onGutterResize then
				opts.onGutterResize(gutterWidth + gutterGap)
			end
		end
	end

	local function fitCanvas()
		if not (opts.fitCanvas and scroller) then
			return
		end
		local height = math.max(lineCount * lineHeight + lineHeight, scroller.AbsoluteWindowSize.Y / totalScale(editor))
		editor.AutomaticSize = Enum.AutomaticSize.None
		editor.Size = UDim2.new(editor.Size.X.Scale, editor.Size.X.Offset, 0, height)
		if scroller.AutomaticCanvasSize == Enum.AutomaticSize.None then
			scroller.CanvasSize = UDim2.new(scroller.CanvasSize.X.Scale, scroller.CanvasSize.X.Offset, 0, height)
		end
	end

	local busy = false
	local function fullUpdate()
		if busy then
			dirty = true
			return
		end
		busy = true
		dirty = false
		if lineHeight <= 0 then
			measure()
		end
		local ok, err = pcall(function()
			rebuild()
			updateGutter()
			fitCanvas()
			render()
		end)
		busy = false
		if not ok then
			warn(err)
		end
	end

	local prevText = editor.Text
	table.insert(connections, editor:GetPropertyChangedSignal("Text"):Connect(function()
		dirty = true
		local text = editor.Text
		local old = prevText
		prevText = text
		if opts.autoClose ~= false and text ~= old then
			local newText, newCursor = autoClose(old, text, editor.CursorPosition)
			if newText and #newText < 200000 then
				prevText = newText
				editor.Text = newText
				editor.CursorPosition = newCursor
			end
		end
	end))

	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		if dirty then
			fullUpdate()
		end
		if caretOn then
			-- caret anim
			caretPos = caretPos:Lerp(caretTarget, 1 - math.exp(-dt * 30))
			caret.Position = UDim2.fromOffset(caretPos.X, caretPos.Y)
			currentLine.Position = UDim2.fromOffset(0, caretPos.Y)
			local t = os.clock() - blinkStart
			caret.BackgroundTransparency = t < 0.5 and 0 or (1 - math.cos((t - 0.5) * math.pi * 2)) / 2
		end
	end))

	local dragAnchor = nil
	local lastClick, lastPos = 0, nil

	local known, knownSel = -1, -1

	local function cursorMoved()
		local cur, sel = editor.CursorPosition, editor.SelectionStart
		local key = navKey()
		blinkStart = os.clock()
		follow = dragAnchor == nil and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		if key and known ~= -1 and not dirty then
			-- block native move
			if cur ~= known then
				editor.CursorPosition = known
				return
			end
			if sel ~= knownSel then
				editor.SelectionStart = knownSel
				return
			end
		else
			if cur ~= known then
				wantX = nil
			end
			known, knownSel = cur, sel
		end
		drawCursor(visibleRange())
	end

	local function moveBy(key)
		if dirty or lineCount == 0 or known == -1 then
			return
		end
		local from = known
		local target = navTarget(key, from)
		local newSel = -1
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
			newSel = knownSel ~= -1 and knownSel or from
			if newSel == target then
				newSel = -1
			end
		end
		known, knownSel = target, newSel
		task.defer(function()
			editor.CursorPosition = target
			editor.SelectionStart = newSel
		end)
	end

	local heldKey, nextRepeat = nil, 0
	table.insert(connections, UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard and editor:IsFocused() and table.find(NAV, input.KeyCode) and navKey() then
			heldKey, nextRepeat = input.KeyCode, os.clock() + 0.4
			moveBy(input.KeyCode)
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == heldKey then
			heldKey = nil
		end
	end))
	table.insert(connections, RunService.Heartbeat:Connect(function()
		if heldKey and editor:IsFocused() and os.clock() >= nextRepeat then
			nextRepeat = os.clock() + 0.035
			moveBy(heldKey)
		end
	end))
	for _, prop in { "CursorPosition", "SelectionStart" } do
		table.insert(connections, editor:GetPropertyChangedSignal(prop):Connect(cursorMoved))
	end
	table.insert(connections, editor.Focused:Connect(cursorMoved))
	table.insert(connections, editor.FocusLost:Connect(cursorMoved))

	local function click(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 or dirty or lineCount == 0 then
			return
		end
		-- scrollbars
		if scroller and (input.Position.X > scroller.AbsolutePosition.X + scroller.AbsoluteWindowSize.X
			or input.Position.Y > scroller.AbsolutePosition.Y + scroller.AbsoluteWindowSize.Y) then
			return
		end
		local canvas = scroller and scroller.CanvasPosition
		local pos = posAt(input.Position)
		local anchor = pos
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
			local cur, sel = editor.CursorPosition, editor.SelectionStart
			if cur ~= -1 then
				anchor = sel ~= -1 and sel or cur
			end
		end
		local double = os.clock() - lastClick < 0.35 and pos == lastPos
		lastClick, lastPos = os.clock(), pos
		dragAnchor = anchor
		if not editor:IsFocused() then
			editor:CaptureFocus()
		end
		task.defer(function()
			if canvas then
				scroller.CanvasPosition = canvas
			end
			if double then
				local line = lineAt(pos)
				local src, base = cache[line].src, lineStart[line]
				local s, e = pos - base + 1, pos - base
				while s > 1 and string.match(string.sub(src, s - 1, s - 1), "[%w_]") do
					s -= 1
				end
				while e < #src and string.match(string.sub(src, e + 1, e + 1), "[%w_]") do
					e += 1
				end
				if e >= s then
					dragAnchor = nil
					editor.CursorPosition = base + e
					editor.SelectionStart = base + s - 1
					return
				end
			end
			editor.CursorPosition = pos
			editor.SelectionStart = anchor ~= pos and anchor or -1
		end)
	end
	table.insert(connections, editor.InputBegan:Connect(click))
	if scroller then
		table.insert(connections, scroller.InputBegan:Connect(click))
	end

	-- tab indent
	table.insert(connections, UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.Tab or not editor:IsFocused() or dirty or lineCount == 0 then
			return
		end
		local text, cur, sel = editor.Text, editor.CursorPosition, editor.SelectionStart
		if cur == -1 or #text >= 199000 then
			return
		end
		local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
		local hasSel = sel ~= -1 and sel ~= cur
		local newText, newCur, newSel
		if not hasSel and not shift then
			newText = string.sub(text, 1, cur - 1) .. "\t" .. string.sub(text, cur)
			newCur, newSel = cur + 1, -1
		else
			local a, b = cur, cur
			if hasSel then
				a, b = math.min(sel, cur), math.max(sel, cur)
			end
			local la, lb = lineAt(a), lineAt(b)
			if lb > la and b == lineStart[lb] then
				lb -= 1
			end
			local stop = lineStart[lb + 1] and lineStart[lb + 1] - 1 or #text + 1
			local parts = string.split(string.sub(text, lineStart[la], stop - 1), "\n")
			local firstDelta, delta = 0, 0
			for i, raw in parts do
				local d = 1
				if shift then
					d = -(string.match(raw, "^\t") and 1 or #string.match(raw, "^ ? ? ? ?"))
					parts[i] = string.sub(raw, 1 - d)
				else
					parts[i] = "\t" .. raw
				end
				if i == 1 then
					firstDelta = d
				end
				delta += d
			end
			newText = string.sub(text, 1, lineStart[la] - 1) .. table.concat(parts, "\n") .. string.sub(text, stop)
			local na = math.max(lineStart[la], a + firstDelta)
			local nb = math.max(lineStart[la], b + (hasSel and delta or firstDelta))
			if not hasSel then
				newCur, newSel = na, -1
			elseif sel < cur then
				newCur, newSel = nb, na
			else
				newCur, newSel = na, nb
			end
		end
		if #newText >= 200000 then
			return
		end
		prevText = newText
		editor.Text = newText
		editor.CursorPosition = newCur
		editor.SelectionStart = newSel
	end))

	-- drag select
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragAnchor and input.UserInputType == Enum.UserInputType.MouseMovement and not dirty then
			local pos = posAt(input.Position)
			editor.CursorPosition = pos
			editor.SelectionStart = pos ~= dragAnchor and dragAnchor or -1
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragAnchor = nil
		end
	end))

	for _, prop in { "TextSize", "FontFace", "LineHeight" } do
		table.insert(connections, editor:GetPropertyChangedSignal(prop):Connect(function()
			copyTextProps(editor, overlay)
			if gutter then
				copyTextProps(editor, gutter)
			end
			gutterWidth = 0
			lineHeight = 0
			fullUpdate()
		end))
	end

	-- redraw on scroll
	table.insert(connections, editor:GetPropertyChangedSignal("AbsolutePosition"):Connect(render))
	if scroller then
		table.insert(connections, scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(render))
		table.insert(connections, scroller:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
			fitCanvas()
			render()
		end))
	end

	fullUpdate()

	local handle = {}

	function handle:Refresh()
		table.clear(cache)
		overlay.TextColor3 = Color3.fromHex(Highlighter.Theme.text)
		fullUpdate()
	end

	function handle:Destroy()
		for _, c in connections do
			c:Disconnect()
		end
		overlay:Destroy()
		caret:Destroy()
		currentLine:Destroy()
		for _, box in selectionPool do
			box:Destroy()
		end
		if gutter then
			gutter:Destroy()
			lineNumbers.Visible = true
		end
		editor.TextTransparency = originalTransparency
	end

	return handle
end

return Highlighter

end

-- StarterGui.ScreenGui.Navigation (LocalScript)
SOURCES[4] = function(script, require)
local UserInputService = game:GetService("UserInputService")

local Gui = script.Parent
local Main = Gui.main
local Library = Gui.library
local ButtonFx = require(Gui.ButtonFx)
local Layout = require(Gui.Layout)

local smooth = ButtonFx.SMOOTH
local fast = ButtonFx.FAST
local pop = ButtonFx.POP
local shrink = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)

local ICON_ON, ICON_HOVER, ICON_OFF = 0, 0.6, 0.95
local LOGO = "rbxassetid://106640334752928"

-- icon id -> page
local ROUTES = {
	["10709807111"] = Gui.main,
	["10709806740"] = Gui.scriptstroe,
	["10709811365"] = Gui.output,
	["10734950020"] = Gui.settings,
	["10747373176"] = Gui.accountmanager,
}
local TIPS = {
	["10709807111"] = "Editor",
	["10709782154"] = "Library",
	["10709806740"] = "Scripts",
	["10709811365"] = "Output",
	["10734950020"] = "Settings",
	["10747373176"] = "Accounts",
}
local BOOKMARK, HOME = "10709782154", "10723407389"

local tween = ButtonFx.tween
local scaleOf = ButtonFx.scaleOf

local getScale = ButtonFx.getScale

local function idOf(page)
	for id, p in ROUTES do
		if p == page then
			return id
		end
	end
end

local cover = ButtonFx.cover

-- templates before the sidebars get restyled
local template = Main.SideBar.Content
local SHADOW = template:FindFirstChild("UIShadow", true)
SHADOW = SHADOW and SHADOW:Clone()
local ACCENT, CORNER
for _, tab in template:GetChildren() do
	if tab:FindFirstChild("Accent") then
		ACCENT, CORNER = tab.Accent:Clone(), tab.UICorner:Clone()
		break
	end
end
ACCENT.BackgroundColor3 = Color3.new(1, 1, 1)
ACCENT.Visible = true
local ACCENT_SIZE = ACCENT.Size

local current = Main
local libraryOpen = false
local bars = {}

local function refreshIcons(bar)
	for _, tab in bar.tabs do
		local id = bar.ids[tab]
		local on = ROUTES[id] == current or (id == BOOKMARK and libraryOpen)
		tween(tab.ImageLabel, fast, {ImageTransparency = on and ICON_ON or ICON_OFF})
	end
end

-- where a tab sits inside its sidebar, measured on the visible bar
local function rectOf(id)
	local bar = bars[current]
	local scale = getScale()
	for _, tab in bar.tabs do
		if bar.ids[tab] == id then
			local pos = (tab.AbsolutePosition - bar.content.AbsolutePosition) / scale
			return {
				Position = UDim2.fromOffset(pos.X, pos.Y),
				Size = UDim2.fromOffset(tab.AbsoluteSize.X / scale, tab.AbsoluteSize.Y / scale),
			}
		end
	end
end

local function showTip(tab, show)
	local tip = tab.Tooltip
	local t = show and 0 or 1
	if show then
		tip.Visible = true
		tip.Position = UDim2.new(1, 16, 0.5, 0)
		tip.TextLabel.TextTransparency, tip.TextLabel.BackgroundTransparency = 1, 1
		tip.ImageLabel.ImageTransparency = 1
	end
	tween(tip, fast, {Position = UDim2.new(1, show and 24 or 16, 0.5, 0)})
	tween(tip.TextLabel, fast, {TextTransparency = t, BackgroundTransparency = t})
	tween(tip.ImageLabel, fast, {ImageTransparency = t}).Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and not show then
			tip.Visible = false
		end
	end)
end

local bounce = ButtonFx.bounce

-- beside the window when there's room; otherwise (phones) over the window's right edge, drawn
-- above it, instead of off screen
local function libraryGoal()
	local scale = getScale()
	local right = (current.AbsolutePosition.X + current.AbsoluteSize.X) / scale
	local x = right + 12
	local width = Library.Size.X.Offset
	local _, _, screenRight = Layout.bounds()
	local overlay = x + width > screenRight
	if overlay then
		x = right - width - 8
	end
	Library.ZIndex = overlay and 60 or 0
	return UDim2.fromOffset(x, current.AbsolutePosition.Y / scale)
end

local function toggleLibrary()
	libraryOpen = not libraryOpen
	local goal = libraryGoal()
	local tucked = goal - UDim2.fromOffset(40, 0)
	if libraryOpen then
		Library.Position = tucked
		Library.Visible = true
		scaleOf(Library).Scale = 0.95
		tween(Library, smooth, {Position = goal})
		tween(scaleOf(Library), smooth, {Scale = 1})
		cover(Library, false, 0, 1)
	else
		tween(Library, smooth, {Position = tucked})
		tween(scaleOf(Library), smooth, {Scale = 0.95})
		cover(Library, false, 1, 0, function()
			if not libraryOpen then
				Library.Visible = false
			end
		end)
	end
	refreshIcons(bars[current])
end

local function go(page)
	if page == current then
		return
	end
	local from, to = bars[current], bars[page]

	-- new highlight starts where the old one is, then slides
	local goal = rectOf(idOf(page))
	to.indicator.Position, to.indicator.Size = from.indicator.Position, from.indicator.Size
	to.accent.Size = UDim2.fromOffset(6, 6)

	page.AnchorPoint, page.Position = current.AnchorPoint, current.Position
	page.Visible = true
	current.Visible = false
	current = page

	tween(to.indicator, smooth, goal)
	tween(to.accent, pop, {Size = ACCENT_SIZE})
	cover(page, true, 0, 1)
	refreshIcons(to)
	if libraryOpen then
		tween(Library, smooth, {Position = libraryGoal()})
	end
end

local minimize

local function setupBar(page)
	local content = page.SideBar.Content
	local bar = {content = content, tabs = {}, ids = {}}

	for _, tab in content:GetChildren() do
		local img = tab:FindFirstChild("ImageLabel")
		if tab:FindFirstChild("Hitbox") and img then
			local id = img.Image:match("%d+$")
			if id == HOME then
				tab.Visible = false
			else
				table.insert(bar.tabs, tab)
				bar.ids[tab] = id
				tab.BackgroundTransparency = 1
				if tab:FindFirstChild("Accent") then
					tab.Accent.Visible = false
				end
				local s = tab:FindFirstChildOfClass("UIShadow")
				if s then
					s:Destroy()
				end
				tab.Tooltip.TextLabel.Text = TIPS[id] or tab.Tooltip.TextLabel.Text
			end
		end
	end

	-- one highlight that slides between icons
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.BackgroundColor3 = Color3.new(1, 1, 1)
	indicator.BackgroundTransparency = 0.95
	indicator.BorderSizePixel = 0
	indicator.ZIndex = 0
	CORNER:Clone().Parent = indicator
	if SHADOW then
		SHADOW:Clone().Parent = indicator
	end
	bar.accent = ACCENT:Clone()
	bar.accent.Parent = indicator
	indicator.Parent = page.SideBar
	bar.indicator = indicator

	for _, tab in bar.tabs do
		local id = bar.ids[tab]
		tab.Hitbox.Activated:Connect(function()
			bounce(tab.ImageLabel)
			if id == BOOKMARK then
				toggleLibrary()
			elseif ROUTES[id] then
				go(ROUTES[id])
			end
		end)
		tab.Hitbox.MouseEnter:Connect(function()
			if tab.ImageLabel.ImageTransparency > ICON_HOVER then
				tween(tab.ImageLabel, fast, {ImageTransparency = ICON_HOVER})
			end
			showTip(tab, true)
		end)
		tab.Hitbox.MouseLeave:Connect(function()
			refreshIcons(bar)
			showTip(tab, false)
		end)
	end

	-- logo minimizes
	local holder = content:FindFirstChild("IconHolder")
	if holder then
		local button = Instance.new("TextButton")
		button.Name = "Minimize"
		button.Text = ""
		button.BackgroundTransparency = 1
		button.Size = UDim2.fromScale(1, 1)
		button.Parent = holder
		button.MouseEnter:Connect(function()
			tween(holder.ImageLabel, fast, {Rotation = -12})
		end)
		button.MouseLeave:Connect(function()
			tween(holder.ImageLabel, fast, {Rotation = 0})
		end)
		button.Activated:Connect(function()
			minimize()
		end)
	end

	bars[page] = bar
	refreshIcons(bar)
end

for _, page in ROUTES do
	setupBar(page)
	page.AnchorPoint, page.Position = Main.AnchorPoint, Main.Position
end

local Square = Instance.new("Frame")
Square.Name = "Minimized"
Square.AnchorPoint = Vector2.new(0.5, 0)
Square.Position = UDim2.new(0.5, 0, 0, 12)
Square.Size = UDim2.fromOffset(52, 52)
Square.BackgroundColor3 = Main.BackgroundColor3
Square.BorderSizePixel = 0
Square.Visible = false
Square.ZIndex = 100
Instance.new("UICorner", Square).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Square)
stroke.Color = Color3.fromRGB(48, 48, 48)
if SHADOW then
	SHADOW:Clone().Parent = Square
end
local logo = Instance.new("ImageLabel")
logo.Image = LOGO
logo.BackgroundTransparency = 1
logo.AnchorPoint = Vector2.new(0.5, 0.5)
logo.Position = UDim2.fromScale(0.5, 0.5)
logo.Size = UDim2.fromOffset(28, 28)
logo.ZIndex = 101
logo.Parent = Square
Square.Parent = Gui

local minimized, reopenLibrary, savedPos = false, false, nil

function minimize()
	if minimized then
		return
	end
	minimized = true
	reopenLibrary = libraryOpen
	if libraryOpen then
		toggleLibrary()
	end

	local page = current
	savedPos = page.Position
	tween(page, shrink, {Position = Square.Position + UDim2.fromOffset(0, 26)})
	tween(scaleOf(page), shrink, {Scale = 0.1})
	cover(page, false, 1, 0, function()
		if minimized then
			page.Visible = false
		end
	end)

	Square.Visible = true
	scaleOf(Square).Scale = 0
	logo.Rotation = -90
	task.delay(0.2, function()
		tween(scaleOf(Square), pop, {Scale = 1})
		tween(logo, pop, {Rotation = 0})
	end)
end

local function restore()
	if not minimized then
		return
	end
	minimized = false
	tween(scaleOf(Square), shrink, {Scale = 0}).Completed:Connect(function()
		if not minimized then
			Square.Visible = false
		end
	end)

	local page = current
	page.Visible = true
	tween(page, smooth, {Position = savedPos})
	tween(scaleOf(page), pop, {Scale = 1})
	cover(page, false, 0, 1)
	if reopenLibrary then
		task.delay(smooth.Time, toggleLibrary)
	end
end

-- drag the square, click to restore
local dragStart, startPos, moved
Square.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragStart, startPos, moved = input.Position, Square.Position, false
	end
end)
Square.MouseEnter:Connect(function()
	tween(logo, fast, {Rotation = -12, Size = UDim2.fromOffset(32, 32)})
end)
Square.MouseLeave:Connect(function()
	tween(logo, fast, {Rotation = 0, Size = UDim2.fromOffset(28, 28)})
end)
local dragChanged = UserInputService.InputChanged:Connect(function(input)
	if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		if delta.Magnitude > 4 then
			moved = true
		end
		local scale = getScale()
		Square.Position = startPos + UDim2.fromOffset(delta.X / scale, delta.Y / scale)
	end
end)
local dragEnded = UserInputService.InputEnded:Connect(function(input)
	if dragStart and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		dragStart = nil
		if not moved then
			restore()
		end
	end
end)
Gui.Destroying:Once(function()
	dragChanged:Disconnect()
	dragEnded:Disconnect()
end)

-- park every highlight on its page's icon after the first layout pass, and again whenever the
-- phone layout resizes the sidebar; an open Library follows the window
local function park()
	for page, bar in bars do
		local goal = rectOf(idOf(page))
		bar.indicator.Position, bar.indicator.Size = goal.Position, goal.Size
	end
	if libraryOpen then
		Library.Position = libraryGoal()
	end
end
Library.ZIndex = 0
task.defer(park)
local relaid = Layout.applied:Connect(function()
	task.defer(park)
end)

-- other scripts open a page by setting the "OpenPage" attribute to its name (Run opens Output)
local requested = Gui:GetAttributeChangedSignal("OpenPage"):Connect(function()
	local name = Gui:GetAttribute("OpenPage")
	if name == nil then
		return
	end
	Gui:SetAttribute("OpenPage", nil)
	local page = Gui:FindFirstChild(name)
	if page and bars[page] and not minimized then
		go(page)
	end
end)
Gui.Destroying:Once(function()
	relaid:Disconnect()
	requested:Disconnect()
end)

end

-- StarterGui.ScreenGui.ScriptStoreClient (LocalScript)
SOURCES[5] = function(script, require)
-- editor Save prompt + the Library panel (MY SCRIPTS / FAVORITES), all backed by Storage
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local gui = script.Parent
local Storage = require(gui.Storage)
local ButtonFx = require(gui.ButtonFx)
local ScriptActions = require(gui.ScriptActions)
local Layout = require(gui.Layout)
local Settings = require(gui.Settings)
local notify = require(gui.Toast).notify
local editor = gui.main.ScrollingFrame.TextBox
local library = gui.library

local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
local BG = Color3.fromRGB(13, 14, 17)
local DANGER = ButtonFx.DANGER
local FAV = ButtonFx.FAV

local sections = {}
local template
for _, section in library.ScrollingFrame:GetChildren() do
	local topbar = section:FindFirstChild("Topbar")
	if topbar then
		local list = section:FindFirstChild("Frame")
		sections[topbar.TextLabel.Text] = {list = list, topbar = topbar}
		section.Name = topbar.TextLabel.Text:gsub("%W", "") .. "Section"
		for _, item in list:GetChildren() do
			if item:IsA("TextButton") then
				template = template or item:Clone()
				item:Destroy()
			end
		end
	end
end
template.Accent.Visible = false
template.Content.ImageButton.Size = UDim2.fromOffset(20, 20) -- the 12px menu icon is too small to tap on a phone
template.Content.ImageButton.Visible = true -- hidden in the design file, which left the row menu unreachable
local mine, favorites = sections.ONLINE, sections.FAVORITES
mine.topbar.TextLabel.Text = "MY SCRIPTS"
mine.list.Parent.Name = "MyScriptsSection"


local WHITE = Color3.new(1, 1, 1)
local PRIMARY = Color3.fromRGB(236, 237, 241)
local BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local DIM = 0.45
local ICONS = {
	run = "rbxassetid://10734934585",
	load = "rbxassetid://10709807111",
	favorite = "rbxassetid://10709782154",
	delete = "rbxassetid://10747362241",
}
local SAVE_HINTS = {
	native = "Saved by your executor to this Roblox account",
	files = "Saved in your executor's workspace for this account",
	memory = "No file access here: saves last until you leave",
}

local function label(parent, value, size, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.FontFace = font or FONT
	l.TextSize = size
	l.TextColor3 = WHITE
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Size = UDim2.new(1, 0, 0, size + 4)
	l.Text = value
	l.ZIndex = 41
	l.Parent = parent
	return l
end

local function column(parent, gap, order)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1, 0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.LayoutOrder = order
	f.ZIndex = 41
	local list = Instance.new("UIListLayout", f)
	list.Padding = UDim.new(0, gap)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	f.Parent = parent
	return f
end

local function actionRow(parent, order)
	local row = Instance.new("Frame")
	row.Name = "Actions"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 40)
	row.LayoutOrder = order
	row.ZIndex = 41
	local list = Instance.new("UIListLayout", row)
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 8)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = parent
	return row
end

-- Cancel is an outlined ghost button, Save the bright solid one
local function dialogButton(parent, value, primary, order)
	local b = Instance.new("TextButton")
	b.Name = value:gsub("%W", "") .. "Button"
	b.AutomaticSize = Enum.AutomaticSize.X
	b.Size = UDim2.fromOffset(0, Layout.compact and Layout.TAP or 40)
	b.FontFace = FONT
	b.TextSize = 15
	b.Text = value
	b.LayoutOrder = order
	b.ZIndex = 41
	if primary then
		b.BackgroundColor3 = PRIMARY
		b.BackgroundTransparency = 0
		b.TextColor3 = BG
	else
		b.BackgroundColor3 = WHITE
		b.BackgroundTransparency = 0.97
		b.TextColor3 = WHITE
		b.TextTransparency = 0.25
	end
	ButtonFx.styleControl(b, 8)
	local pad = Instance.new("UIPadding", b)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 18), UDim.new(0, 18)
	b.Parent = parent
	ButtonFx.bind(b)
	return b
end

-- a full-width row in the script menu: icon + label, lit on hover
local function menuRow(parent, value, icon, color, order)
	local b = Instance.new("TextButton")
	b.Name = value:gsub("%W", "") .. "Button"
	b.Size = UDim2.new(1, 0, 0, 44)
	b.BackgroundColor3 = WHITE
	b.BackgroundTransparency = 1
	b.AutoButtonColor = false
	b.FontFace = FONT
	b.TextSize = 15
	b.Text = value
	b.TextColor3 = color or WHITE
	b.TextTransparency = 0.15
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.LayoutOrder = order
	b.ZIndex = 41
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	local pad = Instance.new("UIPadding", b)
	pad.PaddingLeft = UDim.new(0, 44)
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Image = icon
	image.ImageColor3 = color or WHITE
	image.ImageTransparency = 0.15
	image.AnchorPoint = Vector2.new(0, 0.5)
	image.Position = UDim2.new(0, -30, 0.5, 0) -- back into the left padding
	image.Size = UDim2.fromOffset(18, 18)
	image.ZIndex = 42
	image.Parent = b
	b.Parent = parent
	ButtonFx.bind(b, {hoverBg = 0.94, hoverContentMax = 0, iconHover = 1.12})
	return b
end

local activeModal -- {backdrop, group}
local function closeModal()
	local modal = activeModal
	if not modal then
		return
	end
	activeModal = nil
	-- it stays on screen while it fades, so stop it taking taps right away
	modal.backdrop.Interactable = false
	for _, descendant in modal.backdrop:GetDescendants() do
		if descendant:IsA("GuiButton") or descendant:IsA("TextBox") then
			descendant.Interactable = false
		end
	end
	ButtonFx.tween(modal.backdrop, ButtonFx.FAST, {BackgroundTransparency = 1})
	ButtonFx.tween(modal.group, ButtonFx.FAST, {GroupTransparency = 1}).Completed:Once(function()
		modal.backdrop:Destroy()
	end)
end

-- dimmed backdrop + centered card that fades and scales in; tapping the backdrop cancels
local function openModal(title, subtitle)
	closeModal()
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Dialog"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.ZIndex = 40
	backdrop:SetAttribute("NoFx", true)
	backdrop.Activated:Connect(closeModal)

	-- a CanvasGroup so the whole card fades as one; the padding keeps the card's border inside it
	local group = Instance.new("CanvasGroup")
	group.Name = "DialogGroup"
	group.AnchorPoint = Vector2.new(0.5, 0.5)
	group.Position = UDim2.fromScale(0.5, 0.5)
	group.Size = UDim2.new(0.8, 0, 0, 0)
	group.AutomaticSize = Enum.AutomaticSize.Y
	group.BackgroundTransparency = 1
	group.GroupTransparency = 1
	group.ZIndex = 41
	local limit = Instance.new("UISizeConstraint", group)
	limit.MaxSize = Vector2.new(380, math.huge)
	local groupPad = Instance.new("UIPadding", group)
	for _, side in {"PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom"} do
		groupPad[side] = UDim.new(0, 2)
	end
	local grow = Instance.new("UIScale", group)
	grow.Scale = 0.95

	local card = Instance.new("TextButton") -- a button so taps on it don't hit the backdrop
	card.Name = "DialogCard"
	card.Size = UDim2.fromScale(1, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = BG
	card.Text = ""
	card.AutoButtonColor = false
	card.ZIndex = 41
	card:SetAttribute("NoFx", true)
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
	local border = Instance.new("UIStroke", card)
	border.Color = ButtonFx.STROKE
	border.Transparency = 0.5
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local pad = Instance.new("UIPadding", card)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 20), UDim.new(0, 20)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 18), UDim.new(0, 18)
	local layout = Instance.new("UIListLayout", card)
	layout.Padding = UDim.new(0, 16)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	local header = column(card, 4, 1)
	label(header, title, 18, BOLD)
	if subtitle then
		label(header, subtitle, 13).TextTransparency = 0.5
	end

	card.Parent = group
	group.Parent = backdrop
	backdrop.Parent = gui
	activeModal = {backdrop = backdrop, group = group}
	ButtonFx.tween(backdrop, ButtonFx.SMOOTH, {BackgroundTransparency = DIM})
	ButtonFx.tween(group, ButtonFx.SMOOTH, {GroupTransparency = 0})
	ButtonFx.tween(grow, ButtonFx.SMOOTH, {Scale = 1})
	return card
end

local function currentName()
	return editor:GetAttribute("ScriptName")
end

local function nextFreeName()
	local taken = {}
	for _, row in Storage.list() do
		taken[row.name] = true
	end
	local i = 1
	while taken["Script " .. i] do
		i += 1
	end
	return "Script " .. i
end

local function nameTaken(name)
	for _, row in Storage.list() do
		if row.name == name then
			return true
		end
	end
	return false
end

local SAVE_LABEL = "Save"
local saveButtons = {}
local feedbackToken = 0

-- toolbar Save: "Saved" + accent flash for 1.5s, or a shake + red flash. Each call resets the
-- label first so a failure right after a success can't leave "Saved" showing.
local function saveFeedback(ok)
	feedbackToken += 1
	local token = feedbackToken
	for _, b in saveButtons do
		b.TextLabel.Text = ok and "Saved" or SAVE_LABEL
		if ok then
			ButtonFx.flash(b, ButtonFx.ACCENT, 1.5)
		else
			ButtonFx.shake(b)
			ButtonFx.flash(b, DANGER, 0.5)
		end
	end
	if ok then
		task.delay(1.5, function()
			if feedbackToken == token then
				for _, b in saveButtons do
					b.TextLabel.Text = SAVE_LABEL
				end
			end
		end)
	end
end

local function trim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function openSavePrompt()
	local card = openModal("Save script", SAVE_HINTS[Storage.backend])

	local field = column(card, 6, 2)
	local labelRow = Instance.new("Frame")
	labelRow.BackgroundTransparency = 1
	labelRow.Size = UDim2.new(1, 0, 0, 16)
	labelRow.LayoutOrder = 1
	labelRow.ZIndex = 41
	labelRow.Parent = field
	local caption = label(labelRow, "NAME", 12)
	caption.Size = UDim2.fromScale(0.5, 1)
	caption.TextTransparency = 0.5
	local counter = label(labelRow, "", 12)
	counter.AnchorPoint = Vector2.new(1, 0)
	counter.Position = UDim2.fromScale(1, 0)
	counter.Size = UDim2.fromScale(0.5, 1)
	counter.TextXAlignment = Enum.TextXAlignment.Right
	counter.TextTransparency = 0.5

	local nameBox = Instance.new("TextBox")
	nameBox.Name = "NameBox"
	nameBox.Size = UDim2.new(1, 0, 0, 44)
	nameBox.BackgroundColor3 = WHITE
	nameBox.BackgroundTransparency = 0.97
	nameBox.TextColor3 = WHITE
	nameBox.PlaceholderText = "Script name"
	nameBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
	nameBox.FontFace = FONT
	nameBox.TextSize = 16
	nameBox.TextXAlignment = Enum.TextXAlignment.Left
	nameBox.ClearTextOnFocus = false
	nameBox.ClipsDescendants = true -- long names would otherwise run past the field
	nameBox.Text = currentName() or nextFreeName()
	nameBox.LayoutOrder = 2
	nameBox.ZIndex = 41
	Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 8)
	local fieldBorder = Instance.new("UIStroke", nameBox)
	fieldBorder.Color = ButtonFx.STROKE
	fieldBorder.Transparency = 0.5
	fieldBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local boxPad = Instance.new("UIPadding", nameBox)
	boxPad.PaddingLeft, boxPad.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
	nameBox.Parent = field

	local message = label(field, "", 13)
	message.Name = "Message"
	message.LayoutOrder = 3
	message.Visible = false

	local actions = actionRow(card, 3)
	local cancelButton = dialogButton(actions, "Cancel", false, 1)
	local saveButton = dialogButton(actions, "Save", true, 2)
	local saveHandle = ButtonFx.handleOf(saveButton)

	local focused = false
	local function restBorder()
		ButtonFx.tween(fieldBorder, ButtonFx.FAST, {
			Color = focused and ButtonFx.ACCENT or ButtonFx.STROKE,
			Transparency = focused and 0.2 or 0.5,
		})
	end
	local function showMessage(text, isError)
		message.Text = text
		message.TextColor3 = isError and DANGER or WHITE
		message.TextTransparency = isError and 0 or 0.4
		message.Visible = text ~= ""
	end
	local function updateCounter()
		local length = utf8.len(trim(nameBox.Text)) or #nameBox.Text
		counter.Text = length .. " / 64"
		counter.TextColor3 = length > 64 and DANGER or WHITE
		counter.TextTransparency = length > 64 and 0 or 0.5
	end
	updateCounter()

	-- Saving over a different existing script asks first: Save turns into a red Overwrite and a
	-- second tap replaces it. Editing the name cancels that. A failed save keeps the dialog open
	-- with the reason under the field.
	local overwriting = false
	local saving = false
	local function cancelOverwrite()
		if overwriting then
			overwriting = false
			saveButton.Text = "Save"
			saveButton.TextColor3 = BG
			saveHandle:setFill(PRIMARY)
			showMessage("")
		end
	end

	local function fail(text)
		showMessage(text, true)
		ButtonFx.shake(nameBox)
		ButtonFx.shake(saveButton)
		ButtonFx.tween(fieldBorder, ButtonFx.FAST, {Color = DANGER, Transparency = 0})
		task.delay(0.6, restBorder)
		saveFeedback(false)
	end

	local function trySave()
		if saving then
			return
		end
		local name = trim(nameBox.Text)
		if name == "" then
			fail("Give it a name first")
			return
		end
		if not overwriting and name ~= currentName() and nameTaken(name) then
			overwriting = true
			saveButton.Text = "Overwrite"
			saveButton.TextColor3 = WHITE
			saveHandle:setFill(DANGER)
			showMessage("\"" .. name .. "\" already exists. Tap Overwrite to replace it.")
			return
		end
		saving = true
		local ok, err = Storage.save(name, editor.Text)
		saving = false
		if not ok then
			cancelOverwrite()
			fail(tostring(err))
			return
		end
		closeModal()
		editor:SetAttribute("ScriptName", name)
		notify("Saved \"" .. name .. "\"")
		saveFeedback(true)
	end

	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		updateCounter()
		cancelOverwrite()
		if message.TextColor3 == DANGER then
			showMessage("")
		end
	end)
	nameBox.Focused:Connect(function()
		focused = true
		restBorder()
	end)
	nameBox.FocusLost:Connect(function(enterPressed)
		focused = false
		restBorder()
		if enterPressed then
			trySave()
		end
	end)
	saveButton.Activated:Connect(trySave)
	cancelButton.Activated:Connect(closeModal)
	if not UserInputService.TouchEnabled then
		task.defer(nameBox.CaptureFocus, nameBox) -- phones would pop the keyboard over the dialog
	end
end

local function openItemMenu(row)
	local name = row.name
	local card = openModal(name, row.favorite and "Favorite" or "Saved script")
	local list = column(card, 2, 2)

	menuRow(list, "Run", ICONS.run, nil, 1).Activated:Connect(function()
		closeModal()
		task.spawn(ScriptActions.run, name, notify)
	end)
	menuRow(list, "Load into editor", ICONS.load, nil, 2).Activated:Connect(function()
		closeModal()
		ScriptActions.load(name, notify)
	end)
	menuRow(list, row.favorite and "Unfavorite" or "Favorite", ICONS.favorite, row.favorite and FAV or nil, 3).Activated:Connect(function()
		closeModal()
		ScriptActions.toggleFavorite(name, not row.favorite, notify)
	end)
	ButtonFx.twoStep(menuRow(list, "Delete", ICONS.delete, DANGER, 4), function()
		closeModal()
		ScriptActions.delete(name, notify)
	end)

	dialogButton(actionRow(card, 3), "Cancel", false, 1).Activated:Connect(closeModal)
end

local function addItem(section, row, order)
	local item = template:Clone()
	item.Name = "Row" .. order
	item.LayoutOrder = order
	item.Content.TextLabel.Text = row.name
	item.Content.TextLabel.TextTruncate = Enum.TextTruncate.AtEnd
	item.Accent.Visible = row.name == currentName()
	if row.favorite then
		item.Content.ImageLabel.ImageColor3 = FAV
	end
	item.Activated:Connect(function()
		ScriptActions.load(row.name, notify)
	end)
	-- rows are 32 tall with 4px gaps, so the menu's hit area stops at the row's height; it grows
	-- leftward because the library clips everything right of the icon
	ButtonFx.hitArea(item.Content.ImageButton, Vector2.new(44, item.Size.Y.Offset), Vector2.new(1, 0.5))
	ButtonFx.onActivated(item.Content.ImageButton, function()
		openItemMenu(row)
	end)
	item.Parent = section.list
	ButtonFx.bind(item)
	ButtonFx.bind(item.Content.ImageButton)
end

local function clear(section)
	for _, child in section.list:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function render()
	clear(mine)
	clear(favorites)
	for i, row in Storage.list() do
		addItem(mine, row, i)
		if row.favorite then
			addItem(favorites, row, i)
		end
	end
end

-- a save, delete or import can fire several changes in one frame; redraw once
local renderQueued = false
local function queueRender()
	if renderQueued then
		return
	end
	renderQueued = true
	task.defer(function()
		renderQueued = false
		render()
	end)
end

local connections = {
	Storage.changed:Connect(queueRender),
	editor:GetAttributeChangedSignal("ScriptName"):Connect(queueRender),
}
gui.Destroying:Once(function()
	for _, connection in connections do
		connection:Disconnect()
	end
end)

local setClipboard = setclipboard or toclipboard
local getClipboard = getclipboard or fromclipboard

-- the rest of the editor toolbar; Run goes through the same execute as saved scripts and cards
local EDITOR_ACTIONS = {
	Run = function()
		if not loadstring then
			notify("Run needs an executor (no loadstring here)", true)
			return
		end
		if trim(editor.Text) == "" then
			notify("Nothing to run", true)
			return
		end
		if Settings.get("openOutputOnRun") then
			gui:SetAttribute("OpenPage", "output") -- Navigation switches to it
		end
		task.spawn(ScriptActions.execute, editor.Text, currentName() or "Editor", notify)
	end,
	Clear = function()
		editor.Text = ""
	end,
	Copy = function()
		if not setClipboard then
			notify("No clipboard here", true)
			return
		end
		setClipboard(editor.Text)
		notify("Copied")
	end,
	Paste = function()
		local ok, text = pcall(function()
			return getClipboard and getClipboard()
		end)
		if not (ok and type(text) == "string") then
			notify("Your executor can't read the clipboard: paste with Ctrl+V in the editor", true)
			return
		end
		editor.Text = text
	end,
}

for _, b in gui.main.Toolbar2:GetChildren() do
	local label = b:IsA("TextButton") and b:FindFirstChild("TextLabel")
	if label and label.Text == SAVE_LABEL then
		table.insert(saveButtons, b) -- Buttons gives it the toolbar animation
		b.Activated:Connect(openSavePrompt)
	elseif label and EDITOR_ACTIONS[label.Text] then
		b.Activated:Connect(EDITOR_ACTIONS[label.Text])
	end
end

-- header icons are 14x16 at the library's clipped right edge; the hit areas grow leftward and
-- stay inside the 24px header so they don't cover the rows
local refreshIcon, foldIcon = mine.topbar.ImageButton, favorites.topbar.ImageButton
ButtonFx.hitArea(refreshIcon, Vector2.new(44, 24), Vector2.new(1, 0.5))
ButtonFx.hitArea(foldIcon, Vector2.new(44, 24), Vector2.new(1, 0.5))
ButtonFx.bind(refreshIcon)
ButtonFx.bind(foldIcon)

ButtonFx.onActivated(refreshIcon, function()
	render()
	notify("Refreshed")
end)

-- on a phone the headers and rows grow to a full tap height so their icons' hit areas reach
-- 44x44; a large screen keeps the design's 24 / 32
local ROW, HEADER = template.Size, mine.topbar.Size
local function relayout()
	local compact = Layout.compact
	template.Size = compact and UDim2.new(ROW.X.Scale, ROW.X.Offset, 0, Layout.TAP) or ROW
	local header = compact and UDim2.new(HEADER.X.Scale, HEADER.X.Offset, 0, Layout.TAP) or HEADER
	for _, section in sections do
		section.topbar.Size = header
	end
	for _, icon in {refreshIcon, foldIcon} do
		ButtonFx.hitArea(icon, Vector2.zero).Size = UDim2.fromOffset(44, header.Y.Offset)
	end
	render()
end
connections[#connections + 1] = Layout.applied:Connect(function()
	task.defer(relayout)
end)

local favoritesOpen = true
ButtonFx.onActivated(foldIcon, function()
	favoritesOpen = not favoritesOpen
	favorites.list.Visible = favoritesOpen
	ButtonFx.tween(foldIcon, ButtonFx.FAST, {Rotation = favoritesOpen and 0 or -90})
end)

Storage.setAccount(Players.LocalPlayer.UserId)
render()

end

-- StarterGui.ScreenGui.ScriptBlox (LocalScript)
SOURCES[6] = function(script, require)
-- Scripts page: ScriptBlox browser (HOME / SEARCH / TRENDING) and this account's saved scripts (MY SCRIPTS)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local gui = script.Parent
local Storage = require(gui.Storage)
local ButtonFx = require(gui.ButtonFx)
local ScriptActions = require(gui.ScriptActions)
local Layout = require(gui.Layout)
local page = gui.scriptstroe
local results = page.ScrollingFrame
local editor = gui.main.ScrollingFrame:FindFirstChild("TextBox")

local API = "https://scriptblox.com/api"
local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
local WHITE = Color3.new(1, 1, 1)
local DANGER = ButtonFx.DANGER
local FAV = ButtonFx.FAV
local ACCENT = ButtonFx.ACCENT

local SORTS = {
	{label = "Updated", key = "updatedAt"},
	{label = "Newest", key = "createdAt"},
	{label = "Most viewed", key = "views"},
	{label = "Most liked", key = "likeCount"},
	{label = "Accuracy", key = "accuracy"}, -- search only
}
local FILTERS = {
	{key = "free", label = "Free only"},
	{key = "keyless", label = "Keyless"},
	{key = "verified", label = "Verified"},
	{key = "working", label = "Working"},
	{key = "thisGame", label = "This game only"},
}

local state = {tab = "home", page = 1, totalPages = 1, sort = 1, query = ""}
local filters = {}
local requestId = 0
local rawCache = {}

local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)
local clipboard = setclipboard or toclipboard
local proxy -- ScriptBloxProxy's remote, for plain Studio where the client can't make HTTP calls

-- ok, body, status code. All client-side: the executor's request function, then game:HttpGet.
-- The ScriptBloxProxy relay is only a last resort inside Studio; an executor has no server scripts.
local function httpGet(url)
	if httpRequest then
		local ok, res = pcall(httpRequest, {Url = url, Method = "GET"})
		if ok and type(res) == "table" then
			return true, res.Body or "", res.StatusCode or 200
		end
	end
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok then
		return true, body, 200
	end
	local message = tostring(body)
	if RunService:IsStudio() then
		proxy = proxy or ReplicatedStorage:FindFirstChild("ScriptBloxHttp")
		if proxy then
			local invoked, success, proxied, code = pcall(proxy.InvokeServer, proxy, url)
			if invoked then
				return success, tostring(proxied), code or 0
			end
		end
	end
	-- HttpGet throws on non-2xx, the code is somewhere in the message
	return false, message, tonumber(message:match("(%d%d%d)")) or 0
end

local function encode(params)
	local parts = {}
	for k, v in params do
		table.insert(parts, k .. "=" .. HttpService:UrlEncode(tostring(v)))
	end
	return table.concat(parts, "&")
end

-- decoded table, or nil + error message; errors come back as {message = "..."}
local function getJson(path, params)
	local url = API .. path
	if params and next(params) then
		url ..= "?" .. encode(params)
	end
	local ok, body, code = httpGet(url)
	local decoded, payload = pcall(HttpService.JSONDecode, HttpService, body)
	if decoded and type(payload) == "table" then
		if payload.message and not payload.result then
			return nil, tostring(payload.message), code
		end
		return payload, nil, code
	end
	if not ok then
		return nil, "Request failed (" .. code .. "): " .. body, code
	end
	return nil, "Bad response from ScriptBlox", code
end

-- /script/raw is plain text, not JSON
local function getRaw(slug)
	if rawCache[slug] then
		return rawCache[slug]
	end
	local ok, body, code = httpGet(API .. "/script/raw/" .. HttpService:UrlEncode(slug))
	local decoded, payload = pcall(HttpService.JSONDecode, HttpService, body)
	if decoded and type(payload) == "table" and payload.message then
		return nil, tostring(payload.message)
	end
	if not ok or code >= 400 then
		return nil, "Couldn't fetch script (" .. code .. ")"
	end
	if body == "" then
		return nil, "Script is empty"
	end
	rawCache[slug] = body
	return body
end

-- thumbnails: ImageLabels only load Roblox content, so a ScriptBlox image has to be saved to disk
-- (executor only); otherwise fall back to the Roblox game's own thumbnail
local customAsset = getcustomasset or getsynasset
local canCacheImages = customAsset and writefile and isfile and makefolder and isfolder

local function scriptImage(path)
	if not canCacheImages or type(path) ~= "string" or not (path:match("%.png$") or path:match("%.jpe?g$")) then
		return nil -- Roblox can't decode webp
	end
	local file = "ScriptBlox/" .. (path:gsub("[^%w%.%-]", "_"))
	local ok, asset = pcall(function()
		if not isfolder("ScriptBlox") then
			makefolder("ScriptBlox")
		end
		if not isfile(file) then
			local fetched, body, code = httpGet("https://scriptblox.com" .. (path:sub(1, 1) == "/" and path or "/" .. path))
			if not fetched or code >= 400 then
				error("download failed")
			end
			writefile(file, body)
		end
		return customAsset(file)
	end)
	return ok and asset or nil
end

local function gameThumbnail(s)
	local id = tonumber(s.game and s.game.gameId)
	if id and id > 0 then -- universal scripts and hubs use 0 / -1
		return "rbxthumb://type=GameThumbnail&id=" .. id .. "&w=768&h=432"
	end
end

-- 1234567 -> 1.2M
local function short(n)
	n = tonumber(n) or 0
	for _, unit in {{1e9, "B"}, {1e6, "M"}, {1e3, "K"}} do
		if n >= unit[1] then
			return (string.format("%.1f", n / unit[1]):gsub("%.0$", "")) .. unit[2]
		end
	end
	return tostring(math.floor(n))
end

local function rounded(obj, radius)
	Instance.new("UICorner", obj).CornerRadius = UDim.new(0, radius)
end

local function stroked(obj)
	local stroke = Instance.new("UIStroke", obj)
	stroke.Color = ButtonFx.STROKE
	stroke.Transparency = 0.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

local function padX(obj, px)
	local pad = Instance.new("UIPadding", obj)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, px), UDim.new(0, px)
end

local function hlist(obj, gap)
	local layout = Instance.new("UIListLayout", obj)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, gap)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	return layout
end

-- a pill row that scrolls sideways when it doesn't fit (phones); on a large screen it never has to.
-- The 2px padding keeps the pills' borders clear of the clipping edge.
local function scroller(parent, name)
	local s = Instance.new("ScrollingFrame")
	s.Name = name
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.X
	s.ScrollingDirection = Enum.ScrollingDirection.X
	s.ScrollBarThickness = 0
	local pad = Instance.new("UIPadding", s)
	for _, side in {"PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom"} do
		pad[side] = UDim.new(0, 2)
	end
	s.Parent = parent
	return s
end

local function strip(parent, position, size)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Position = position
	f.Size = size
	f.Parent = parent
	return f
end

-- same look as the topbar tabs: faint fill, dim text, brightens when on
local function pill(parent, text, order)
	local b = Instance.new("TextButton")
	b.AutomaticSize = Enum.AutomaticSize.X
	b.Size = UDim2.fromScale(0, 1)
	b.BackgroundColor3 = WHITE
	b.BackgroundTransparency = 0.985
	b.AutoButtonColor = false
	b.FontFace = FONT
	b.TextSize = 16
	b.TextColor3 = WHITE
	b.TextTransparency = 0.5
	b.Name = text:gsub("%W", "") .. "Pill"
	b.Text = text
	b.LayoutOrder = order or 0
	ButtonFx.styleControl(b)
	padX(b, 12)
	b.Parent = parent
	ButtonFx.bind(b)
	return b
end

local function setOn(b, on)
	ButtonFx.handleOf(b):set({selected = on})
end

local function setDisabled(b, disabled)
	ButtonFx.handleOf(b):set({disabled = disabled})
end

local function label(parent, text, size)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.FontFace = FONT
	l.TextSize = size or 14
	l.TextColor3 = WHITE
	l.TextTransparency = 0.5
	l.Text = text
	l.Parent = parent
	return l
end

local function badge(parent, text, color)
	local b = label(parent, text, 12)
	b.AutomaticSize = Enum.AutomaticSize.X
	b.Size = UDim2.fromScale(0, 1)
	b.BackgroundColor3 = color
	b.BackgroundTransparency = 0.85
	b.TextColor3 = color
	b.TextTransparency = 0
	rounded(b, 6)
	padX(b, 8)
end

-- sidebar is 64 wide + 8 gap, so everything sits at x = 72

local topbar = strip(page, UDim2.fromOffset(72, 0), UDim2.new(1, -72, 0, 36))
topbar.Name = "ScriptBloxTopbar"
local tabsRow = scroller(topbar, "TabRow")
hlist(tabsRow, 8)

local powered = label(topbar, "Powered by ScriptBlox.com")
powered.AnchorPoint = Vector2.new(1, 0)
powered.Position = UDim2.new(1, -44, 0, 0)
powered.Size = UDim2.fromScale(0, 1)
powered.AutomaticSize = Enum.AutomaticSize.X

local close = pill(topbar, "×")
close.AutomaticSize = Enum.AutomaticSize.None
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.fromScale(1, 0)
close.Size = UDim2.fromOffset(36, 36)
close.TextSize = 20

local searchRow = strip(page, UDim2.fromOffset(72, 44), UDim2.new(1, -72, 0, 36))
hlist(searchRow, 8)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -266, 1, 0)
box.BackgroundColor3 = WHITE
box.BackgroundTransparency = 0.985
box.TextColor3 = WHITE
box.PlaceholderText = "Search ScriptBlox..."
box.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
box.FontFace = FONT
box.TextSize = 16
box.TextXAlignment = Enum.TextXAlignment.Left
box.ClearTextOnFocus = false
box.Text = ""
rounded(box, 6)
stroked(box)
padX(box, 12)
box.Parent = searchRow

local searchButton = pill(searchRow, "Search", 1)
searchButton.AutomaticSize = Enum.AutomaticSize.None
searchButton.Size = UDim2.new(0, 90, 1, 0)
setOn(searchButton, true)

local sortButton = pill(searchRow, "", 2)
sortButton.AutomaticSize = Enum.AutomaticSize.None
sortButton.Size = UDim2.new(0, 160, 1, 0)

searchRow.Name = "SearchRow"
local filterRow = scroller(page, "FilterRow")
hlist(filterRow, 8)

-- MY SCRIPTS swaps the search and filter rows for these
local mineRow = strip(page, UDim2.fromOffset(72, 44), UDim2.new(1, -72, 0, 36))
mineRow.Name = "MineRow"
mineRow.Visible = false
hlist(mineRow, 8)
local exportButton = pill(mineRow, "Export", 1)
local importButton = pill(mineRow, "Import", 2)
local mineHint = label(mineRow, "Import reads an export from the Editor tab")
mineHint.LayoutOrder = 3
mineHint.AutomaticSize = Enum.AutomaticSize.X
mineHint.Size = UDim2.fromScale(0, 1)

local notice = label(page, "")
notice.Position = UDim2.fromOffset(72, 88)
notice.Size = UDim2.new(1, -72, 0, 36)
notice.TextXAlignment = Enum.TextXAlignment.Left
notice.TextTruncate = Enum.TextTruncate.AtEnd
notice.Visible = false

local footer = strip(page, UDim2.new(0, 72, 1, 0), UDim2.new(1, -72, 0, 36))
footer.Name = "Footer"
footer.AnchorPoint = Vector2.new(0, 1)

local status = label(footer, "")
status.Size = UDim2.new(1, -240, 1, 0)
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd

local pager = strip(footer, UDim2.fromScale(1, 0), UDim2.fromScale(0, 1))
pager.Name = "Pager"
pager.AnchorPoint = Vector2.new(1, 0)
pager.AutomaticSize = Enum.AutomaticSize.X
hlist(pager, 8)
local prevButton = pill(pager, "Prev", 1)
local pageLabel = label(pager, "Page 1 / 1")
pageLabel.LayoutOrder = 2
pageLabel.AutomaticSize = Enum.AutomaticSize.X
pageLabel.Size = UDim2.fromScale(0, 1)
local nextButton = pill(pager, "Next", 3)

-- results fill the space between the filter row and the footer
results.Position = UDim2.new(1, 0, 1, -44)
results.Size = UDim2.new(1, -72, 1, -176)
results.CanvasSize = UDim2.new()
results.AutomaticCanvasSize = Enum.AutomaticSize.Y
results.ScrollingDirection = Enum.ScrollingDirection.Y
results.ScrollBarThickness = 4
results.ScrollBarImageColor3 = WHITE
results.ScrollBarImageTransparency = 0.8

local function setStatus(text, isError)
	status.Text = text
	status.TextColor3 = isError and DANGER or WHITE
	status.TextTransparency = isError and 0 or 0.5
end

-- the page ships with placeholder cards; keep one as the template

local template
for _, child in results:GetChildren() do
	if child:IsA("Frame") and child:FindFirstChild("TextContainer") then
		template = template or child:Clone()
		child:Destroy()
	end
end

local text = template.TextContainer
text.Position = UDim2.new(0, 0, 1, -48) -- sit above the buttons
text.Size = UDim2.new(1, 0, 0, 100)
text.UIPadding.PaddingRight = UDim.new(0, 16)
for _, l in text:GetChildren() do
	if l:IsA("TextLabel") then
		l.TextTruncate = Enum.TextTruncate.AtEnd
		if l.LayoutOrder == 1 then
			l.Name = "Title"
			l.AutomaticSize = Enum.AutomaticSize.None
			l.Size = UDim2.new(1, 0, 0, 48) -- two lines max
			l.TextWrapped = true
			l.TextYAlignment = Enum.TextYAlignment.Bottom
		else
			l.Name = "Info"
			l.Size = UDim2.fromScale(1, 0)
			l.TextTransparency = 0.5
		end
	end
end

-- The design dims card buttons to 0.85 like an inactive tab, which reads as disabled on an action,
-- so they rest at the pills' 0.5. Every one gets an icon, 44px height, and the main action (Execute /
-- Run) the brighter background.
local CARD_ICONS = {
	Execute = "rbxassetid://10734934585",
	Run = "rbxassetid://10734934585",
	Copy = "rbxassetid://10709812159",
	Load = "rbxassetid://10709807111",
	Delete = "rbxassetid://10747362241",
}
local PRIMARY_BG = 0.95

local function setCardButton(b, label)
	b.Name, b.TextLabel.Text = label, label
	b.ImageLabel.Image = CARD_ICONS[label]
end

template.ButtonContainer.UIPadding.PaddingBottom = UDim.new(0, 4)
for _, b in template.ButtonContainer:GetChildren() do
	if b:IsA("TextButton") then
		ButtonFx.styleControl(b)
		b.TextLabel.TextTransparency = 0.5
		b.ImageLabel.ImageTransparency = 0.5
		b.ImageLabel.Visible = true
		if b.TextLabel.Text == "Run" then
			setCardButton(b, "Execute")
			b.LayoutOrder = 1
			b.BackgroundTransparency = PRIMARY_BG
		else
			setCardButton(b, "Copy")
			b.LayoutOrder = 2
		end
	end
end

local badges = strip(template, UDim2.fromOffset(16, 16), UDim2.new(1, -32, 0, 20))
badges.Name = "Badges"
hlist(badges, 6)

local function runScript(slug, title)
	if not loadstring then
		setStatus("Execute needs an executor (no loadstring here)", true)
		return
	end
	setStatus("Fetching " .. title .. "...")
	local code, err = getRaw(slug)
	if not code then
		setStatus(err, true)
		return
	end
	ScriptActions.execute(code, title, setStatus)
end

-- no setclipboard (plain Studio): drop the code into the Editor tab instead
local function copyScript(slug, title)
	if not clipboard and not editor then
		setStatus("Copy needs an executor (no setclipboard here)", true)
		return
	end
	setStatus("Fetching " .. title .. "...")
	local code, err = getRaw(slug)
	if not code then
		setStatus(err, true)
		return
	end
	if clipboard then
		clipboard(code)
		setStatus("Copied " .. title)
	else
		editor.Text = code
		setStatus("Loaded " .. title .. " into the Editor tab")
	end
end

local ago = ScriptActions.ago

local function addCard(s, order)
	local card = template:Clone()
	card.Name = "Card" .. order
	card.LayoutOrder = order
	local slug = s.slug or s._id
	local title = s.title or "Untitled"
	local where = s.isUniversal and "Universal" or (s.game and s.game.name) or "Unknown game"
	card.TextContainer.Title.Text = title
	card.TextContainer.Info.Text = where .. "  ·  " .. short(s.views) .. " views"

	if s.verified then
		badge(card.Badges, "Verified", ACCENT)
	end
	if s.key then
		badge(card.Badges, "Key", FAV)
	end
	if s.isPatched then
		badge(card.Badges, "Patched", DANGER)
	end
	if s.isUniversal then
		badge(card.Badges, "Universal", WHITE)
	end

	ButtonFx.twoStep(card.ButtonContainer.Execute, function()
		task.spawn(runScript, slug, title)
	end)
	ButtonFx.bind(card.ButtonContainer.Copy)
	card.ButtonContainer.Copy.Activated:Connect(function()
		task.spawn(copyScript, slug, title)
	end)

	card.Parent = results

	-- the card's backdrop image; its gradient overlay already fades it out behind the text
	task.spawn(function()
		local image = scriptImage(s.image) or gameThumbnail(s)
		if image and card.Parent then
			card.ImageLabel.Image = image
			card.ImageLabel.ImageTransparency = 0.2
			card.ImageLabel.ScaleType = Enum.ScaleType.Crop
		end
	end)
end

local function addSavedCard(row, order)
	local card = template:Clone()
	card.Name = "Saved" .. order
	card.LayoutOrder = order
	card.TextContainer.Title.Text = row.name
	card.TextContainer.Info.Text = "Saved " .. ago(row.updated)

	local buttons = card.ButtonContainer
	local run, loadButton = buttons.Execute, buttons.Copy
	setCardButton(run, "Run")
	setCardButton(loadButton, "Load")
	local delete = loadButton:Clone()
	setCardButton(delete, "Delete")
	delete.LayoutOrder = 3
	delete.Parent = buttons

	ButtonFx.bind(run)
	run.Activated:Connect(function()
		task.spawn(ScriptActions.run, row.name, setStatus)
	end)
	ButtonFx.bind(loadButton)
	loadButton.Activated:Connect(function()
		ScriptActions.load(row.name, setStatus)
	end)
	ButtonFx.twoStep(delete, function()
		ScriptActions.delete(row.name, setStatus)
	end)

	card.Parent = results
end

local function clearCards()
	for _, child in results:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function buildParams()
	local params = {page = state.page}
	if state.tab == "search" then
		params.q = state.query
	end
	local sort = SORTS[state.sort].key
	if sort ~= "accuracy" or state.tab == "search" then
		params.sortBy = sort
	end
	if filters.free then
		params.mode = "free"
	end
	if filters.keyless then
		params.key = 0
	end
	if filters.verified then
		params.verified = 1
	end
	if filters.working then
		params.patched = 0
	end
	if filters.thisGame then
		params.placeId = game.PlaceId
	end
	return params
end

-- trending takes no params, so the toggles filter it locally
local function passes(s)
	return not (filters.free and s.scriptType == "paid")
		and not (filters.keyless and s.key)
		and not (filters.verified and not s.verified)
		and not (filters.working and s.isPatched)
		and not (filters.thisGame and tostring(s.game and s.game.gameId) ~= tostring(game.PlaceId))
end

local function updatePager()
	pager.Visible = state.tab == "home" or state.tab == "search"
	pageLabel.Text = "Page " .. state.page .. " / " .. state.totalPages
	setDisabled(prevButton, state.page <= 1)
	setDisabled(nextButton, state.page >= state.totalPages)
end

-- keepStatus: a refresh after save / delete shouldn't wipe the message that action just showed
local function loadMine(keepStatus)
	clearCards()
	updatePager()
	local rows, err = Storage.list()
	if err then
		setStatus(err, true)
		return
	end
	for i, row in rows do
		addSavedCard(row, i)
	end
	results.CanvasPosition = Vector2.zero
	if #rows == 0 then
		setStatus("No saved scripts yet")
	elseif not keepStatus then
		setStatus(#rows .. (#rows == 1 and " saved script" or " saved scripts"))
	end
end

local function load()
	requestId += 1
	local id = requestId
	local tab = state.tab
	if tab == "mine" then
		loadMine(false)
		return
	end
	clearCards()
	updatePager()
	if tab == "search" and state.query == "" then
		setStatus("Type something and press Search")
		return
	end
	setStatus("Loading...")

	task.spawn(function()
		local path = tab == "trending" and "/script/trending" or tab == "search" and "/script/search" or "/script/fetch"
		local response, err, code = getJson(path, tab ~= "trending" and buildParams() or nil)
		if id ~= requestId then
			return -- user moved on
		end

		local scripts = response and type(response.result) == "table" and response.result.scripts
		if not scripts then
			if tab == "search" and code == 404 then
				state.totalPages = 1
				updatePager()
				setStatus("No results")
			else
				setStatus(err or "Unexpected response from ScriptBlox", true)
			end
			return
		end

		local shown = {}
		for _, s in scripts do
			if tab ~= "trending" or passes(s) then
				table.insert(shown, s)
			end
		end

		state.totalPages = math.max(1, tonumber(response.result.totalPages) or 1)
		clearCards()
		for i, s in shown do
			addCard(s, i)
		end
		results.CanvasPosition = Vector2.zero
		updatePager()
		setStatus(#shown == 0 and "No results" or #shown .. " scripts")
	end)
end

local tabButtons = {}
local connections = {}

local function track(connection)
	table.insert(connections, connection)
	return connection
end

local function updateSort()
	sortButton.Text = "Sort: " .. SORTS[state.sort].label
	sortButton.Visible = state.tab ~= "trending"
end

local function selectTab(tab)
	state.tab = tab
	state.page = 1
	if tab ~= "search" and SORTS[state.sort].key == "accuracy" then
		state.sort = 1
	end
	for name, b in tabButtons do
		setOn(b, name == tab)
	end
	local mine = tab == "mine"
	searchRow.Visible = not mine
	filterRow.Visible = not mine
	mineRow.Visible = mine
	notice.Visible = mine
	updateSort()
	load()
end

local function search()
	state.query = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
	selectTab("search")
end

for i, tab in {{"home", "Home"}, {"search", "Search"}, {"trending", "Trending"}, {"mine", "My Scripts"}} do
	local b = pill(tabsRow, tab[2], i)
	tabButtons[tab[1]] = b
	b.Activated:Connect(function()
		if tab[1] == "search" then
			search()
		else
			selectTab(tab[1])
		end
	end)
end

searchButton.Activated:Connect(search)
box.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		search()
	end
end)

sortButton.Activated:Connect(function()
	repeat
		state.sort = state.sort % #SORTS + 1
	until SORTS[state.sort].key ~= "accuracy" or state.tab == "search"
	state.page = 1
	updateSort()
	load()
end)

for i, f in FILTERS do
	local b = pill(filterRow, f.label, i)
	b.Activated:Connect(function()
		filters[f.key] = not filters[f.key]
		setOn(b, filters[f.key])
		state.page = 1
		load()
	end)
end

prevButton.Activated:Connect(function()
	if state.page > 1 then
		state.page -= 1
		load()
	end
end)
nextButton.Activated:Connect(function()
	if state.page < state.totalPages then
		state.page += 1
		load()
	end
end)

exportButton.Activated:Connect(function()
	ScriptActions.export(setStatus)
end)

importButton.Activated:Connect(function()
	ScriptActions.import(setStatus)
end)

-- coalesce: an import fires once, but save + account switch can land in the same frame
local refreshQueued = false
track(Storage.changed:Connect(function()
	if state.tab ~= "mine" or refreshQueued then
		return
	end
	refreshQueued = true
	task.defer(function()
		refreshQueued = false
		if state.tab == "mine" then
			loadMine(true)
		end
	end)
end))

-- close hides the whole hub; RightControl brings it back
close.Activated:Connect(function()
	gui.Enabled = false
end)
track(UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.RightControl then
		gui.Enabled = not gui.Enabled
	end
end))

-- drag by the topbar; the library panel follows if it's open
local dragStart, startPos, libraryStart
topbar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragStart, startPos = input.Position, page.Position
		libraryStart = gui.library.Visible and gui.library.Position
	end
end)
track(UserInputService.InputChanged:Connect(function(input)
	if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = (input.Position - dragStart) / ButtonFx.getScale()
		local offset = UDim2.fromOffset(delta.X, delta.Y)
		page.Position = startPos + offset
		if libraryStart then
			gui.library.Position = libraryStart + offset
		end
	end
end))
track(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragStart = nil
	end
end))

-- set by Splash when startup init fails; the window still opens, so say what went wrong here
track(gui:GetAttributeChangedSignal("StartupError"):Connect(function()
	setStatus("Startup problem: " .. tostring(gui:GetAttribute("StartupError")), true)
end))

-- Rows are stacked from the control height: the design's 36, or 44 on a phone so every pill is a
-- full tap target. At 36 this reproduces the original positions exactly.
local grid = results:FindFirstChildOfClass("UIGridLayout")
local function fitCard(card)
	-- narrow screens show one column of shorter cards with a one-line title
	local title = card:FindFirstChild("TextContainer") and card.TextContainer:FindFirstChild("Title")
	if title then
		local short = grid.CellSize.X.Scale == 1
		title.Size = UDim2.new(1, 0, 0, short and 24 or 48)
		title.TextWrapped = not short
	end
end

local function relayout()
	local h = Layout.control()
	local scale = ButtonFx.getScale()
	topbar.Size = UDim2.new(1, -72, 0, h)
	close.Size = UDim2.fromOffset(h, h)
	powered.Position = UDim2.new(1, -(h + 8), 0, 0)
	local poweredWidth = powered.AbsoluteSize.X / scale
	tabsRow.Position = UDim2.fromOffset(-2, -2)
	tabsRow.Size = UDim2.new(1, -(h + poweredWidth + 16) + 4, 1, 4)
	for _, row in {searchRow, mineRow} do
		row.Position = UDim2.fromOffset(72, h + 8)
		row.Size = UDim2.new(1, -72, 0, h)
	end
	filterRow.Position = UDim2.fromOffset(72 - 2, 2 * h + 16 - 2)
	filterRow.Size = UDim2.new(1, -72 + 4, 0, h + 4)
	notice.Position = UDim2.fromOffset(72, 2 * h + 16)
	notice.Size = UDim2.new(1, -72, 0, h)
	footer.Size = UDim2.new(1, -72, 0, h)
	results.Position = UDim2.new(1, 0, 1, -(h + 8))
	results.Size = UDim2.new(1, -72, 1, -(4 * h + 32))
	local oneColumn = results.AbsoluteSize.X / scale < 560
	grid.CellSize = oneColumn and UDim2.new(1, 0, 0, 136) or UDim2.new(0.5, -6, 0, 200)
	for _, card in results:GetChildren() do
		if card:IsA("Frame") then
			fitCard(card)
		end
	end
end
track(Layout.applied:Connect(function()
	task.defer(relayout)
end))
track(powered:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout))
track(results.ChildAdded:Connect(function(card)
	if card:IsA("Frame") then
		fitCard(card)
	end
end))
relayout()

-- the GUI can be destroyed without this script dying with it (executors), so let go of the globals
gui.Destroying:Once(function()
	for _, connection in connections do
		connection:Disconnect()
	end
	ButtonFx.cleanup()
end)

Storage.setAccount(Players.LocalPlayer.UserId)
local NOTICES = {
	native = "Saved by your executor, separately for each Roblox account",
	files = "Saved in your executor's workspace under accounts/" .. tostring(Storage.getAccount()) .. "/scripts",
	memory = "No file access here: saved scripts only last until you leave the game",
}
notice.Text = NOTICES[Storage.backend]
if Storage.backend == "memory" then
	notice.TextColor3 = FAV
	notice.TextTransparency = 0
end

selectTab("home")

end

-- StarterGui.ScreenGui.Storage (ModuleScript)
SOURCES[7] = function(script, require)
-- per-account saved scripts. One backend is picked when the module loads:
--   native  the executor's bridge (SetAccount / ListScripts / SaveScript / LoadScript / DeleteScript)
--   files   writefile & co, under accounts/<userId>/scripts with an index.json for names and times
--   memory  this session only (kept in `shared`, so it survives the GUI being rebuilt on respawn)
-- Every call returns a value or false + message; nothing here throws at the caller.
-- Storage.create(env) builds a separate instance against a given set of globals (used by the tests).
local HttpService = game:GetService("HttpService")

local MAX_NAME = 64
local MAX_CODE = 500 * 1024
local MAX_SCRIPTS = 500
local FAVORITES = ".favorites" -- hidden record with the account's favorite names; names can't start with "."

local NATIVE = {"SetAccount", "ListScripts", "SaveScript", "LoadScript", "DeleteScript"}
local FILES = {"writefile", "readfile", "isfile", "isfolder", "makefolder", "listfiles", "delfile"}

local function provides(env, names)
	for _, name in names do
		if type(env[name]) ~= "function" then
			return false
		end
	end
	return true
end

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function checkName(name)
	if type(name) ~= "string" then
		return nil, "Name must be text"
	end
	name = trim(name)
	local length = utf8.len(name)
	if name == "" then
		return nil, "Name can't be empty"
	elseif not length then
		return nil, "Name isn't valid text"
	elseif length > MAX_NAME then
		return nil, "Name is too long (max " .. MAX_NAME .. " characters)"
	elseif name:find("[/\\]") or name:find("..", 1, true) then
		return nil, "Name can't contain / \\ or .."
	elseif name:find("%c") then
		return nil, "Name can't contain line breaks or control characters"
	elseif name:sub(1, 1) == "." then
		return nil, "Name can't start with a dot"
	end
	return name
end

local function byNewest(a, b)
	if a.updated ~= b.updated then
		return a.updated > b.updated
	end
	return a.name < b.name
end

-- backends: list(uid), read(uid, name), write(uid, name, code, updated), remove(uid, name), open(uid).
-- They may throw; the public functions below catch it.

local function nativeBackend(env)
	return {
		open = function(uid)
			env.SetAccount(uid)
		end,
		list = function()
			local rows = {}
			local listed = env.ListScripts()
			if type(listed) == "table" then
				for _, row in listed do
					if type(row) == "table" and type(row.name) == "string" then
						table.insert(rows, {name = row.name, updated = tonumber(row.updated) or 0})
					end
				end
			end
			return rows
		end,
		read = function(_, name)
			local code = env.LoadScript(name)
			return type(code) == "string" and code or nil
		end,
		-- the bridge stamps its own time, so imports can't carry their original one over
		write = function(_, name, code)
			local ok, err = env.SaveScript(name, code)
			if ok ~= true then
				error(err or "SaveScript failed", 0)
			end
		end,
		remove = function(_, name)
			return env.DeleteScript(name) == true
		end,
		-- the bridge only exposes the signed-in account
		accounts = function()
			return {}
		end,
	}
end

local function filesBackend(env)
	local indexes = {} -- [uid] = {[name] = {file, updated}}

	local function folder(uid)
		return "accounts/" .. uid
	end

	local function ensure(path)
		if not env.isfolder(path) then
			env.makefolder(path)
		end
	end

	local function index(uid)
		if indexes[uid] then
			return indexes[uid]
		end
		local path = folder(uid) .. "/index.json"
		local entries = {}
		if env.isfile(path) then
			local raw = env.readfile(path)
			local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
			if ok and type(decoded) == "table" then
				for name, entry in decoded do
					if type(name) == "string" and type(entry) == "table" and type(entry.file) == "string" then
						entries[name] = {file = entry.file, updated = tonumber(entry.updated) or 0}
					end
				end
			else
				-- keep the broken index around instead of overwriting it on the next save
				env.writefile(path .. ".bad", raw)
			end
		end
		indexes[uid] = entries
		return entries
	end

	local function writeIndex(uid)
		ensure("accounts")
		ensure(folder(uid))
		env.writefile(folder(uid) .. "/index.json", HttpService:JSONEncode(indexes[uid]))
	end

	-- readable file names where the name allows it; otherwise (emoji, quotes, a case-only clash on
	-- case-insensitive storage) a generated one. The index is what maps names to files.
	local function fileFor(entries, name)
		local file = name .. ".lua"
		if name:match("^[%w _%-%(%)]+$") then
			local clash = false
			for _, entry in entries do
				if entry.file:lower() == file:lower() then
					clash = true
					break
				end
			end
			if not clash then
				return file
			end
		end
		return HttpService:GenerateGUID(false) .. ".lua"
	end

	return {
		open = function(uid)
			index(uid)
		end,
		list = function(uid)
			local rows = {}
			for name, entry in index(uid) do
				table.insert(rows, {name = name, updated = entry.updated})
			end
			return rows
		end,
		read = function(uid, name)
			local entry = index(uid)[name]
			local path = entry and folder(uid) .. "/scripts/" .. entry.file
			if path and env.isfile(path) then
				return env.readfile(path)
			end
			return nil
		end,
		write = function(uid, name, code, updated)
			local entries = index(uid)
			local file = entries[name] and entries[name].file or fileFor(entries, name)
			ensure("accounts")
			ensure(folder(uid))
			ensure(folder(uid) .. "/scripts")
			env.writefile(folder(uid) .. "/scripts/" .. file, code)
			entries[name] = {file = file, updated = updated}
			writeIndex(uid)
		end,
		remove = function(uid, name)
			local entries = index(uid)
			local entry = entries[name]
			if not entry then
				return false
			end
			local path = folder(uid) .. "/scripts/" .. entry.file
			if env.isfile(path) then
				env.delfile(path)
			end
			entries[name] = nil
			writeIndex(uid)
			return true
		end,
		accounts = function()
			local ids = {}
			if env.isfolder("accounts") then
				for _, path in env.listfiles("accounts") do
					-- executors return "accounts/123" or "accounts\\123"
					local id = tonumber(tostring(path):match("accounts[/\\](%-?%d+)"))
					if id then
						table.insert(ids, id)
					end
				end
			end
			return ids
		end,
	}
end

local function memoryBackend(accounts)
	accounts = accounts or {} -- [uid] = {[name] = {code, updated}}

	local function scripts(uid)
		accounts[uid] = accounts[uid] or {}
		return accounts[uid]
	end

	return {
		open = function() end,
		list = function(uid)
			local rows = {}
			for name, entry in scripts(uid) do
				table.insert(rows, {name = name, updated = entry.updated})
			end
			return rows
		end,
		read = function(uid, name)
			local entry = scripts(uid)[name]
			return entry and entry.code
		end,
		write = function(uid, name, code, updated)
			scripts(uid)[name] = {code = code, updated = updated}
		end,
		remove = function(uid, name)
			local existed = scripts(uid)[name] ~= nil
			scripts(uid)[name] = nil
			return existed
		end,
		accounts = function()
			local ids = {}
			for uid in accounts do
				table.insert(ids, uid)
			end
			return ids
		end,
	}
end

local function create(env)
	local Storage = {}
	local backend
	if provides(env, NATIVE) then
		Storage.backend, backend = "native", nativeBackend(env)
	elseif provides(env, FILES) then
		Storage.backend, backend = "files", filesBackend(env)
	else
		Storage.backend, backend = "memory", memoryBackend(env.memory)
	end

	local account
	local changed = Instance.new("BindableEvent")
	Storage.changed = changed.Event -- fires after save / delete / import / account switch

	-- true + results, or false + message
	local function call(fn, ...)
		local ok, result = pcall(fn, ...)
		if not ok then
			return false, "Storage error: " .. tostring(result)
		end
		return true, result
	end

	local function favoritesOf(uid)
		local favorites = {}
		local ok, raw = call(backend.read, uid, FAVORITES)
		if ok and type(raw) == "string" then
			local decoded, names = pcall(HttpService.JSONDecode, HttpService, raw)
			if decoded and type(names) == "table" then
				for _, name in names do
					if type(name) == "string" then
						favorites[name] = true
					end
				end
			end
		end
		return favorites
	end

	local function writeFavorites(uid, favorites)
		local names = {}
		for name in favorites do
			table.insert(names, name)
		end
		table.sort(names)
		return call(backend.write, uid, FAVORITES, HttpService:JSONEncode(names), os.time())
	end

	local function rows(uid)
		local ok, listed = call(backend.list, uid)
		if not ok then
			return nil, listed
		end
		local favorites = favoritesOf(uid)
		local visible = {}
		for _, row in listed do
			if row.name ~= FAVORITES then
				row.favorite = favorites[row.name] == true
				table.insert(visible, row)
			end
		end
		table.sort(visible, byNewest)
		return visible
	end

	function Storage.setAccount(userId)
		local uid = tonumber(userId)
		if not uid or uid ~= math.floor(uid) or math.abs(uid) == math.huge then
			return false, "Account id must be a whole number"
		end
		if uid == account then
			return true
		end
		local ok, err = call(backend.open, uid)
		if not ok then
			return false, err
		end
		account = uid
		changed:Fire()
		return true
	end

	function Storage.getAccount()
		return account
	end

	function Storage.list()
		if not account then
			return {}, "No account set"
		end
		local listed, err = rows(account)
		if not listed then
			return {}, err
		end
		return listed
	end

	function Storage.save(name, code)
		if not account then
			return false, "No account set"
		end
		local uid = account -- an account switch mid-save mustn't move the script
		local clean, err = checkName(name)
		if not clean then
			return false, err
		end
		if type(code) ~= "string" then
			return false, "Code must be text"
		end
		if #code > MAX_CODE then
			return false, "Script is too big (max 500 KB)"
		end
		local listed, listErr = rows(uid)
		if not listed then
			return false, listErr
		end
		local exists = false
		for _, row in listed do
			if row.name == clean then
				exists = true
				break
			end
		end
		if not exists and #listed >= MAX_SCRIPTS then
			return false, "You can save up to " .. MAX_SCRIPTS .. " scripts"
		end
		local ok, writeErr = call(backend.write, uid, clean, code, os.time())
		if not ok then
			return false, writeErr
		end
		changed:Fire()
		return true
	end

	function Storage.load(name)
		if not account then
			return nil, "No account set"
		end
		local clean, err = checkName(name)
		if not clean then
			return nil, err
		end
		local ok, code = call(backend.read, account, clean)
		if not ok then
			return nil, code
		end
		return code
	end

	function Storage.delete(name)
		if not account then
			return false, "No account set"
		end
		local clean, err = checkName(name)
		if not clean then
			return false, err
		end
		local ok, removed = call(backend.remove, account, clean)
		if not ok then
			return false, removed
		end
		if not removed then
			return false, "No script called \"" .. clean .. "\""
		end
		local favorites = favoritesOf(account)
		if favorites[clean] then
			favorites[clean] = nil
			writeFavorites(account, favorites)
		end
		changed:Fire()
		return true
	end

	function Storage.setFavorite(name, favorite)
		if not account then
			return false, "No account set"
		end
		local uid = account
		local clean, err = checkName(name)
		if not clean then
			return false, err
		end
		local listed, listErr = rows(uid)
		if not listed then
			return false, listErr
		end
		local exists = false
		for _, row in listed do
			if row.name == clean then
				exists = true
				break
			end
		end
		if not exists then
			return false, "No script called \"" .. clean .. "\""
		end
		local favorites = favoritesOf(uid)
		favorites[clean] = favorite == true or nil
		local ok, writeErr = writeFavorites(uid, favorites)
		if not ok then
			return false, writeErr
		end
		changed:Fire()
		return true
	end

	local function exportFor(uid)
		local listed, err = rows(uid)
		if not listed then
			return nil, err
		end
		local scripts = {}
		for _, row in listed do
			local ok, code = call(backend.read, uid, row.name)
			if not ok then
				return nil, code
			end
			if code then
				table.insert(scripts, {name = row.name, updated = row.updated, code = code, favorite = row.favorite})
			end
		end
		local ok, json = pcall(HttpService.JSONEncode, HttpService, {version = 1, account = uid, scripts = scripts})
		if not ok then
			return nil, "Couldn't encode export: " .. tostring(json)
		end
		return json
	end

	function Storage.exportAll()
		if not account then
			return nil, "No account set"
		end
		return exportFor(account)
	end

	-- merges an exportAll() string; the newer `updated` wins per name. Returns the count written,
	-- plus a message when entries were skipped or nothing could be read.
	function Storage.importAll(json)
		if not account then
			return 0, "No account set"
		end
		if type(json) ~= "string" then
			return 0, "Import needs the export JSON as text"
		end
		local decodedOk, export = pcall(HttpService.JSONDecode, HttpService, json)
		if not decodedOk or type(export) ~= "table" or type(export.scripts) ~= "table" then
			return 0, "That isn't a script export"
		end
		local uid = account
		local listed, err = rows(uid)
		if not listed then
			return 0, err
		end
		local current = {}
		for _, row in listed do
			current[row.name] = row.updated
		end

		local imported, skipped, total = 0, 0, #listed
		local wantFavorite = {}
		for _, entry in export.scripts do
			if type(entry) == "table" and entry.favorite == true and type(entry.name) == "string" then
				wantFavorite[trim(entry.name)] = true
			end
		end
		for _, entry in export.scripts do
			local name = type(entry) == "table" and checkName(entry.name)
			local code = type(entry) == "table" and entry.code
			local updated = type(entry) == "table" and tonumber(entry.updated) or 0
			if not name or type(code) ~= "string" or #code > MAX_CODE then
				skipped += 1
			elseif current[name] and current[name] >= updated then
				continue -- ours is as new or newer
			elseif not current[name] and total >= MAX_SCRIPTS then
				skipped += 1
			elseif call(backend.write, uid, name, code, updated) then
				if not current[name] then
					total += 1
				end
				current[name] = updated
				imported += 1
			else
				skipped += 1
			end
		end
		-- favorites merge as a union: anything starred in the export and present here gets starred
		local favorites = favoritesOf(uid)
		local starred = false
		for name in wantFavorite do
			if current[name] and not favorites[name] then
				favorites[name] = true
				starred = true
			end
		end
		if starred then
			writeFavorites(uid, favorites)
		end
		if imported > 0 or starred then
			changed:Fire()
		end
		return imported, skipped > 0 and skipped .. " skipped (bad entry, too big, or list full)" or nil
	end

	-- Roblox accounts with saves on this device: the signed-in one first (even when empty), then
	-- any other that still has scripts. {userId, count, updated, current}
	function Storage.accounts()
		local found = {}
		local seen = {}
		local function add(uid)
			if seen[uid] then
				return
			end
			seen[uid] = true
			local listed = rows(uid) or {}
			local newest = 0
			for _, row in listed do
				newest = math.max(newest, row.updated)
			end
			if uid == account or #listed > 0 then
				table.insert(found, {userId = uid, count = #listed, updated = newest, current = uid == account})
			end
		end
		if account then
			add(account)
		end
		local ok, ids = call(backend.accounts)
		if ok and type(ids) == "table" then
			for _, uid in ids do
				add(uid)
			end
		end
		return found
	end

	-- merges another account's scripts into the signed-in one (newest wins, like importAll)
	function Storage.copyFrom(userId)
		if not account then
			return 0, "No account set"
		end
		local uid = tonumber(userId)
		if Storage.backend == "native" then
			return 0, "The executor only shares the signed-in account's scripts"
		end
		if not uid or uid == account then
			return 0, "Pick another account to copy from"
		end
		local json, err = exportFor(uid)
		if not json then
			return 0, err
		end
		return Storage.importAll(json)
	end

	-- deletes every script (and the favorites) saved for an account; returns true + how many went
	function Storage.clearAccount(userId)
		if not account then
			return false, "No account set"
		end
		local uid = tonumber(userId) or account
		if Storage.backend == "native" and uid ~= account then
			return false, "The executor only shares the signed-in account's scripts"
		end
		local listed, err = rows(uid)
		if not listed then
			return false, err
		end
		local removed = 0
		for _, row in listed do
			local ok, didRemove = call(backend.remove, uid, row.name)
			if ok and didRemove then
				removed += 1
			end
		end
		call(backend.remove, uid, FAVORITES)
		changed:Fire()
		return true, removed
	end

	return Storage
end

local Storage = create({
	SetAccount = SetAccount,
	ListScripts = ListScripts,
	SaveScript = SaveScript,
	LoadScript = LoadScript,
	DeleteScript = DeleteScript,
	writefile = writefile,
	readfile = readfile,
	isfile = isfile,
	isfolder = isfolder,
	makefolder = makefolder,
	listfiles = listfiles,
	delfile = delfile,
	memory = (function()
		shared.ScriptHubSavedScripts = shared.ScriptHubSavedScripts or {}
		return shared.ScriptHubSavedScripts
	end)(),
})
Storage.create = create
return Storage

end

-- StarterGui.ScreenGui.ButtonFx (ModuleScript)
SOURCES[8] = function(script, require)
-- button motion shared by every page, taken from the sidebar / editor tabs so one place sets the feel:
-- FAST fades for hover and state, a Back bounce for presses, and the tabs' hover values
-- (background 0.985 -> 0.97, content 0.85 -> 0.65) generalised to any resting look
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ButtonFx = {}

ButtonFx.FAST = TweenInfo.new(0.2, Enum.EasingStyle.Quint)
ButtonFx.SMOOTH = TweenInfo.new(0.4, Enum.EasingStyle.Quint)
ButtonFx.POP = TweenInfo.new(0.45, Enum.EasingStyle.Back)
ButtonFx.DANGER = Color3.fromRGB(255, 115, 141)
ButtonFx.ACCENT = Color3.fromRGB(119, 207, 255)
ButtonFx.FAV = Color3.fromRGB(255, 210, 90)
ButtonFx.STROKE = Color3.fromRGB(48, 48, 48)

local SELECTED_BG = 0.95
local PRESS_SCALE = 0.94

-- the ScreenGui's UIScale; pixel math (drags, highlight positions) has to divide by it
function ButtonFx.getScale()
	local uiScale = script.Parent:FindFirstChildOfClass("UIScale")
	return uiScale and uiScale.Scale or 1
end

-- a new tween on the same object and properties replaces the old one instead of stacking
local running = {} -- [obj] = {[propsKey] = Tween}

function ButtonFx.tween(obj, info, props)
	local keys = {}
	for key in props do
		table.insert(keys, key)
	end
	table.sort(keys)
	local key = table.concat(keys, ",")
	local byObj = running[obj]
	if not byObj then
		byObj = {}
		running[obj] = byObj
	end
	if byObj[key] then
		byObj[key]:Cancel()
	end
	local playing = TweenService:Create(obj, info, props)
	byObj[key] = playing
	playing.Completed:Once(function()
		if byObj[key] == playing then
			byObj[key] = nil
			if next(byObj) == nil and running[obj] == byObj then
				running[obj] = nil
			end
		end
	end)
	playing:Play()
	return playing
end

function ButtonFx.hoverBg(rest)
	return math.max(0, rest - 0.015)
end

function ButtonFx.hoverContent(rest)
	return rest * 0.65 / 0.85
end

function ButtonFx.scaleOf(obj)
	local s = obj:FindFirstChild("NavScale")
	if not s then
		s = Instance.new("UIScale")
		s.Name = "NavScale"
		s.Parent = obj
	end
	return s
end

-- A flat panel in the frame's own color laid over it, faded from -> to over SMOOTH; how pages fade
-- in and out. skipSidebar leaves the sidebar uncovered. Returns the panel.
function ButtonFx.cover(frame, skipSidebar, from, to, done)
	local panel = Instance.new("Frame")
	panel.Name = "Cover"
	panel.BackgroundColor3 = frame.BackgroundColor3
	panel.BackgroundTransparency = from
	panel.BorderSizePixel = 0
	panel.ZIndex = 50
	local corner = frame:FindFirstChildOfClass("UICorner")
	if corner then
		corner:Clone().Parent = panel
	end

	local pad = frame:FindFirstChildOfClass("UIPadding")
	local l, r, t, b = 0, 0, 0, 0
	if pad then
		l, r, t, b = pad.PaddingLeft.Offset, pad.PaddingRight.Offset, pad.PaddingTop.Offset, pad.PaddingBottom.Offset
	end
	local x = skipSidebar and frame.SideBar.Size.X.Offset or -l
	panel.Position = UDim2.fromOffset(x, -t)
	panel.Size = UDim2.new(1, r - x, 1, t + b)
	panel.Parent = frame

	ButtonFx.tween(panel, ButtonFx.SMOOTH, {BackgroundTransparency = to}).Completed:Connect(function()
		panel:Destroy()
		if done then
			done()
		end
	end)
	return panel
end

function ButtonFx.bounce(obj, from)
	local s = ButtonFx.scaleOf(obj)
	s.Scale = from or 0.75
	ButtonFx.tween(s, ButtonFx.POP, {Scale = 1})
end

local handles = {} -- [button] = handle
local hitAreas = {} -- [button] = invisible larger TextButton that also counts as the button

-- the tab look for a control: 6px corners and the faint border stroke. Colors are left alone.
function ButtonFx.styleControl(button, radius)
	local corner = button:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", button)
	corner.CornerRadius = UDim.new(0, radius or 6)
	local stroke = button:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", button)
	stroke.Color = ButtonFx.STROKE
	stroke.Transparency = 0.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	button.AutoButtonColor = false -- ButtonFx does the hover/press; AutoButtonColor would stack on it
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- Hover / press / selected / disabled / confirm for one button. Resting values are read from the
-- button when it's bound, so bind before changing its state. Binding twice returns the same handle.
-- handle:set({selected =, disabled =, confirm =}) changes state; handle:destroy() disconnects.
-- options: hoverBg (fixed hover background), hoverContentMax (hover at least this bright),
-- pressScale, iconHover (icon grows to this on hover), iconTint (icon color while pressed),
-- bounce (the icon does the sidebar bounce when tapped). Buttons with a UIStroke also light the
-- border on hover, which is what makes hover readable on the faint pills and cards.
function ButtonFx.bind(button, options)
	if handles[button] then
		return handles[button]
	end
	options = options or {}
	local onContent = options.onContent or 0
	local restBg = button.BackgroundTransparency
	-- solid buttons (dialogs) can't get lighter through transparency, so they tint their fill
	-- instead, and keep their text color so a red button never hides its own label
	local solid = restBg < 0.5
	local restColor = button.BackgroundColor3

	local targets = {}
	local function add(obj)
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			table.insert(targets, {obj = obj, prop = "TextTransparency", rest = obj.TextTransparency, color = obj.TextColor3})
		elseif obj:IsA("ImageLabel") then
			table.insert(targets, {obj = obj, prop = "ImageTransparency", rest = obj.ImageTransparency})
		end
	end
	if button:IsA("TextButton") and button.Text ~= "" and button.TextTransparency < 1 then
		add(button)
	end
	-- labels inside the button, but not inside nested buttons (those animate themselves)
	local function scan(parent)
		for _, child in parent:GetChildren() do
			if child:IsA("TextLabel") or child:IsA("ImageLabel") then
				add(child)
			elseif child:IsA("Frame") then
				scan(child)
			end
		end
	end
	scan(button)

	local stroke = button:FindFirstChildOfClass("UIStroke")
	local strokeRest = stroke and stroke.Transparency
	local icon = (options.iconHover or options.iconTint) and button:FindFirstChildWhichIsA("ImageLabel")
	local iconScale = icon and ButtonFx.scaleOf(icon)
	local iconColor = icon and icon.ImageColor3
	local pressScale = options.pressScale or PRESS_SCALE

	local state = {hovered = false, pressed = false, selected = false, disabled = false, confirm = false, flash = false}
	local scale = ButtonFx.scaleOf(button)
	local connections = {}
	local release
	local alive = true

	local function apply()
		if not alive then
			return
		end
		local hovered = state.hovered and not state.disabled
		if solid then
			local fill = restColor
			if state.flash then
				fill = restColor:Lerp(state.flash, 0.6)
			elseif state.confirm then
				fill = restColor:Lerp(Color3.new(1, 1, 1), 0.2)
			elseif state.selected or hovered then
				fill = restColor:Lerp(Color3.new(1, 1, 1), state.selected and 0.12 or 0.08)
			end
			ButtonFx.tween(button, ButtonFx.FAST, {BackgroundColor3 = fill})
		else
			local hoverBg = options.hoverBg or ButtonFx.hoverBg(restBg)
			local bg = state.selected and SELECTED_BG or hovered and hoverBg or restBg
			ButtonFx.tween(button, ButtonFx.FAST, {BackgroundTransparency = bg})
		end
		for _, target in targets do
			local value = target.rest
			if state.disabled then
				value = target.rest + (1 - target.rest) * 0.7
			elseif state.selected then
				value = math.min(target.rest, onContent)
			elseif hovered then
				value = ButtonFx.hoverContent(target.rest)
				if options.hoverContentMax then
					value = math.min(value, options.hoverContentMax)
				end
			end
			ButtonFx.tween(target.obj, ButtonFx.FAST, {[target.prop] = value})
			if target.color and not solid then
				local color = state.flash or state.confirm and ButtonFx.DANGER or target.color
				ButtonFx.tween(target.obj, ButtonFx.FAST, {TextColor3 = color})
			end
		end
		if stroke then
			local lit = (hovered or state.selected) and not state.disabled
			ButtonFx.tween(stroke, ButtonFx.FAST, {Transparency = lit and math.min(strokeRest, 0.2) or strokeRest})
		end
		local pressed = state.pressed and not state.disabled
		ButtonFx.tween(scale, pressed and ButtonFx.FAST or ButtonFx.POP, {Scale = pressed and pressScale or 1})
		if iconScale and options.iconHover then
			ButtonFx.tween(iconScale, ButtonFx.POP, {Scale = hovered and options.iconHover or 1})
		end
		if icon and options.iconTint then
			ButtonFx.tween(icon, ButtonFx.FAST, {ImageColor3 = pressed and options.iconTint or iconColor})
		end
	end

	local handle = {}

	-- recolor a solid button (Save -> red Overwrite) without losing its hover / press feel
	function handle:setFill(color)
		restColor = color
		apply()
	end

	function handle:set(changes)
		local dirty = false
		for key, value in changes do
			if state[key] ~= value then
				state[key] = value
				dirty = true
			end
		end
		if dirty then
			apply()
		end
	end

	function handle:destroy()
		if not alive then
			return
		end
		alive = false
		for _, connection in connections do
			connection:Disconnect()
		end
		if release then
			release:Disconnect()
		end
		if handles[button] == handle then
			handles[button] = nil
		end
	end

	-- the button and its hit area (if it has one) both drive the same state
	local function listen(target)
		table.insert(connections, target.MouseEnter:Connect(function()
			-- touch fires MouseEnter on tap with no MouseLeave after; touch hover comes from press/release
			if UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch then
				handle:set({hovered = true})
			end
		end))
		table.insert(connections, target.MouseLeave:Connect(function()
			handle:set({hovered = false})
		end))
		table.insert(connections, target.InputBegan:Connect(function(input)
			if not isPress(input) or state.disabled then
				return
			end
			local touch = input.UserInputType == Enum.UserInputType.Touch
			handle:set(touch and {pressed = true, hovered = true} or {pressed = true})
			-- listen globally so a finger that slides off the button still releases it
			if release then
				release:Disconnect()
			end
			release = UserInputService.InputEnded:Connect(function(ended)
				if ended == input or ended.UserInputType == input.UserInputType and not touch then
					release:Disconnect()
					release = nil
					handle:set(touch and {pressed = false, hovered = false} or {pressed = false})
				end
			end)
		end))
	end
	handle.listen = listen
	listen(button)
	if hitAreas[button] then
		listen(hitAreas[button])
	end
	if options.bounce then
		local icon = button:FindFirstChildWhichIsA("ImageLabel")
		if icon then
			table.insert(connections, button.Activated:Connect(function()
				if not state.disabled then
					ButtonFx.bounce(icon)
				end
			end))
		end
	end
	table.insert(connections, button.Destroying:Connect(function()
		handle:destroy()
	end))

	handles[button] = handle
	return handle
end

function ButtonFx.handleOf(button)
	return handles[button]
end

-- An invisible hit area of `size` on a small button so it's tappable on a phone without changing
-- how it looks or shifting the layout. `anchor` is where it attaches on the button: centered by
-- default, (1, 0.5) to grow leftward from the right edge when the right side is clipped.
-- Connect clicks with ButtonFx.onActivated so taps on either count.
function ButtonFx.hitArea(button, size, anchor)
	if hitAreas[button] then
		return hitAreas[button]
	end
	anchor = anchor or Vector2.new(0.5, 0.5)
	local area = Instance.new("TextButton")
	area.Name = "HitArea"
	area.Text = ""
	area.BackgroundTransparency = 1
	area.AnchorPoint = anchor
	area.Position = UDim2.fromScale(anchor.X, anchor.Y)
	area.Size = UDim2.fromOffset(size.X, size.Y)
	area.ZIndex = button.ZIndex + 1
	area.Parent = button
	hitAreas[button] = area
	button.Destroying:Once(function()
		hitAreas[button] = nil
	end)
	local handle = handles[button]
	if handle then
		handle.listen(area)
	end
	return area
end

-- a short color flash on the button's text (or its fill, for solid buttons); a newer flash on the
-- same button takes over, so overlapping ones never leave it tinted
local flashes = setmetatable({}, {__mode = "k"})
function ButtonFx.flash(button, color, duration)
	local handle = ButtonFx.bind(button)
	local token = {}
	flashes[button] = token
	handle:set({flash = color})
	task.delay(duration, function()
		if flashes[button] == token then
			flashes[button] = nil
			handle:set({flash = false})
		end
	end)
end

-- A quick horizontal shake. It moves the content through the button's own padding, because
-- buttons inside list layouts can't be moved by Position; left + right always add up the same,
-- so the button's size doesn't change.
local SHAKE_STEP = TweenInfo.new(0.05, Enum.EasingStyle.Quint)
local shaking = setmetatable({}, {__mode = "k"})
function ButtonFx.shake(button)
	local pad = button:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding", button)
	local base = shaking[button] and shaking[button].base or {pad.PaddingLeft, pad.PaddingRight}
	local token = {}
	shaking[button] = {base = base, token = token}
	task.spawn(function()
		for _, offset in {6, -6, 4, -4, 2, 0} do
			if not shaking[button] or shaking[button].token ~= token then
				return
			end
			local shift = UDim.new(0, offset)
			ButtonFx.tween(pad, SHAKE_STEP, {PaddingLeft = base[1] + shift, PaddingRight = base[2] - shift})
			task.wait(SHAKE_STEP.Time)
		end
		if shaking[button] and shaking[button].token == token then
			shaking[button] = nil
		end
	end)
end

function ButtonFx.onActivated(button, fn)
	local connections = {button.Activated:Connect(fn)}
	if hitAreas[button] then
		table.insert(connections, hitAreas[button].Activated:Connect(fn))
	end
	return connections
end

-- First tap arms the button for 3s and shows "Confirm?" (icon-only buttons turn their icon red
-- instead); a second tap in that window runs onConfirm. Taps within 0.3s of arming are ignored so
-- an accidental double tap can't confirm. onArm, if given, runs on the first tap so the caller can
-- say what the second one will do.
function ButtonFx.twoStep(button, onConfirm, onArm)
	local handle = ButtonFx.bind(button)
	local label = button:FindFirstChild("TextLabel") or (button:IsA("TextButton") and button.Text ~= "" and button) or nil
	local icon = not label and button:FindFirstChildWhichIsA("ImageLabel")
	local idleText = label and label.Text
	local idleColor = icon and icon.ImageColor3
	local armedAt
	local function disarm()
		armedAt = nil
		if label then
			label.Text = idleText
		elseif icon then
			ButtonFx.tween(icon, ButtonFx.FAST, {ImageColor3 = idleColor})
		end
		handle:set({confirm = false})
	end
	return button.Activated:Connect(function()
		local now = os.clock()
		if armedAt and now - armedAt < 0.3 then
			return
		end
		if armedAt and now - armedAt < 3 then
			disarm()
			onConfirm()
			return
		end
		armedAt = now
		if label then
			label.Text = "Confirm?"
		elseif icon then
			ButtonFx.tween(icon, ButtonFx.FAST, {ImageColor3 = ButtonFx.DANGER})
		end
		handle:set({confirm = true})
		if onArm then
			onArm()
		end
		task.delay(3, function()
			if armedAt == now then
				disarm()
			end
		end)
	end)
end

-- disconnect everything when the GUI goes away; safe to call more than once
function ButtonFx.cleanup()
	for _, handle in handles do
		handle:destroy()
	end
	for _, byObj in running do
		for _, playing in byObj do
			playing:Cancel()
		end
	end
	table.clear(running)
end

return ButtonFx

end

-- StarterGui.ScreenGui.ScriptActions (ModuleScript)
SOURCES[9] = function(script, require)
-- Run / Load / Delete / Favorite for saved scripts, shared by Scripts > My Scripts and the Library.
-- Each takes report(text, isError) so the caller shows it in its own status line or toast.
local gui = script.Parent
local Storage = require(gui.Storage)
local OutputLog = require(gui.OutputLog)
local editor = gui.main.ScrollingFrame:FindFirstChild("TextBox")

local ScriptActions = {}

-- loadstring is pcalled because some environments (Studio included) throw from it instead of
-- returning nil + error. Every run is written to the Output page: start, finish, or the error with
-- where it happened.
function ScriptActions.execute(code, title, report)
	local compiled, fn, compileErr = pcall(loadstring, code, "=" .. title)
	if not compiled then
		fn, compileErr = nil, fn
	end
	if not fn then
		OutputLog.add("error", title .. " didn't compile: " .. tostring(compileErr))
		report("Couldn't compile: " .. tostring(compileErr), true)
		return
	end
	report("Running " .. title)
	OutputLog.add("run", "Running " .. title)
	local started = os.clock()
	local ok, runErr = xpcall(fn, function(err)
		return debug.traceback(tostring(err), 2)
	end)
	if ok then
		OutputLog.add("run", string.format("%s finished in %.2fs", title, os.clock() - started))
	else
		OutputLog.add("error", title .. " errored: " .. tostring(runErr))
		report("Script errored: " .. tostring(runErr):match("^[^\n]*"), true)
	end
end

local function loadCode(name, report)
	local code, err = Storage.load(name)
	if not code then
		report(err or "\"" .. name .. "\" wasn't found", true)
	end
	return code
end

-- yields while the script runs; callers task.spawn it
function ScriptActions.run(name, report)
	if not loadstring then
		report("Run needs an executor (no loadstring here)", true)
		return
	end
	local code = loadCode(name, report)
	if code then
		ScriptActions.execute(code, name, report)
	end
end

function ScriptActions.load(name, report)
	if not editor then
		report("There's no editor to load into", true)
		return
	end
	local code = loadCode(name, report)
	if code then
		editor.Text = code
		editor:SetAttribute("ScriptName", name) -- the Save prompt prefills from this
		report("Loaded \"" .. name .. "\" into the Editor tab")
	end
end

function ScriptActions.delete(name, report)
	local ok, err = Storage.delete(name)
	report(ok and "Deleted \"" .. name .. "\"" or err, not ok)
	return ok
end

function ScriptActions.toggleFavorite(name, favorite, report)
	local ok, err = Storage.setFavorite(name, favorite)
	if not ok then
		report("Couldn't update favorites: " .. tostring(err), true)
	end
	return ok
end

local clipboard = setclipboard or toclipboard

-- no clipboard (plain Studio): the export goes into the Editor tab so it can still be copied
function ScriptActions.export(report)
	local json, err = Storage.exportAll()
	if not json then
		report(err, true)
		return
	end
	local count = #Storage.list()
	if clipboard then
		clipboard(json)
		report("Copied " .. count .. (count == 1 and " script" or " scripts") .. " as JSON")
	elseif editor then
		editor.Text = json
		editor:SetAttribute("ScriptName", nil)
		report("No clipboard here: the export is in the Editor tab")
	else
		report("Nowhere to put the export", true)
	end
end

-- reads an export from the Editor tab and merges it in
function ScriptActions.import(report)
	if not editor then
		report("There's no editor to import from", true)
		return
	end
	local count, err = Storage.importAll(editor.Text)
	if count == 0 then
		report(err or "Nothing newer to import", err ~= nil)
	else
		report("Imported " .. count .. (count == 1 and " script" or " scripts") .. (err and " (" .. err .. ")" or ""))
	end
end

-- 1700000000 -> "3h ago"
function ScriptActions.ago(t)
	t = tonumber(t) or 0
	local seconds = os.time() - t
	if seconds < 60 then
		return "just now"
	elseif seconds < 3600 then
		return math.floor(seconds / 60) .. "m ago"
	elseif seconds < 86400 then
		return math.floor(seconds / 3600) .. "h ago"
	elseif seconds < 86400 * 30 then
		return math.floor(seconds / 86400) .. "d ago"
	end
	return os.date("%d %b %Y", t)
end

return ScriptActions

end

-- StarterGui.ScreenGui.Splash (LocalScript)
SOURCES[10] = function(script, require)
-- Startup, once per GUI load, in the GUI's own motion: the minimized square pops in at the centre
-- (the same square, logo and spin Navigation uses for minimize), a thin line under it follows the
-- modules actually initialising, then the square shrinks away and the window grows out of it the
-- way restore does. Any tap skips to the end. If init fails the window still shows and the error
-- lands in the Scripts page status line (the StartupError attribute).
local Players = game:GetService("Players")

local Gui = script.Parent
local Main = Gui.main
local ButtonFx = require(Gui.ButtonFx)

local LOGO = "rbxassetid://106640334752928"
local MIN_SHOW = 1
local SHRINK = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)

local tween = ButtonFx.tween

local pages = {}
for _, child in Gui:GetChildren() do
	if child:IsA("Frame") and child.Visible and child:FindFirstChild("SideBar") then
		table.insert(pages, child)
		child.Visible = false
	end
end

-- invisible, full screen: only there so any tap skips
local overlay = Instance.new("TextButton")
overlay.Name = "SplashOverlay"
overlay:SetAttribute("NoFx", true)
overlay.Text = ""
overlay.AutoButtonColor = false
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundTransparency = 1
overlay.ZIndex = 200

local square = Instance.new("Frame")
square.AnchorPoint = Vector2.new(0.5, 0.5)
square.Position = UDim2.fromScale(0.5, 0.5)
square.Size = UDim2.fromOffset(60, 60)
square.BackgroundColor3 = Main.BackgroundColor3
square.BorderSizePixel = 0
Instance.new("UICorner", square).CornerRadius = UDim.new(0, 12)
local border = Instance.new("UIStroke", square)
border.Color = Color3.fromRGB(48, 48, 48)
local shadow = Main:FindFirstChildOfClass("UIShadow")
if shadow then
	shadow:Clone().Parent = square
end
local squareScale = Instance.new("UIScale", square)
squareScale.Scale = 0
square.Parent = overlay

local logo = Instance.new("ImageLabel")
logo.Image = LOGO
logo.BackgroundTransparency = 1
logo.AnchorPoint = Vector2.new(0.5, 0.5)
logo.Position = UDim2.fromScale(0.5, 0.5)
logo.Size = UDim2.fromOffset(32, 32)
logo.Rotation = -90
logo.Parent = square

local track = Instance.new("Frame")
track.AnchorPoint = Vector2.new(0.5, 0)
track.Position = UDim2.new(0.5, 0, 1, 12)
track.Size = UDim2.fromOffset(60, 2)
track.BackgroundColor3 = Color3.new(1, 1, 1)
track.BackgroundTransparency = 1
track.BorderSizePixel = 0
Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
track.Parent = square
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.new(1, 1, 1)
fill.BackgroundTransparency = 1
fill.BorderSizePixel = 0
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
fill.Parent = track

overlay.Parent = Gui

local function progress(fraction)
	tween(fill, ButtonFx.SMOOTH, {Size = UDim2.fromScale(fraction, 1)})
end

-- the same calls the page scripts make; modules are cached, so this is the real first load
local function init()
	local Storage = require(Gui.Storage)
	progress(0.4)
	require(Gui.ScriptActions)
	progress(0.7)
	local ok, err = Storage.setAccount(Players.LocalPlayer.UserId)
	if not ok then
		error(err, 0)
	end
	assert(Storage.backend, "Storage has no backend")
	progress(1)
end

local finished = false
local initError

local function finish(animated)
	if finished then
		return
	end
	finished = true
	if initError then
		Gui:SetAttribute("StartupError", initError)
	end
	for _, page in pages do
		page.Visible = true
	end
	if not animated then
		overlay:Destroy()
		return
	end
	-- restore: the square shrinks away while the window grows out of where it was
	tween(squareScale, SHRINK, {Scale = 0}).Completed:Once(function()
		overlay:Destroy()
	end)
	for _, page in pages do
		local home = page.Position
		local scale = ButtonFx.scaleOf(page)
		page.Position = square.Position
		scale.Scale = 0.1
		tween(page, ButtonFx.SMOOTH, {Position = home})
		tween(scale, ButtonFx.POP, {Scale = 1})
		ButtonFx.cover(page, false, 0, 1)
	end
end

overlay.Activated:Connect(function()
	finish(false)
end)

-- whatever happens below, the window comes back
task.delay(5, finish, false)

task.spawn(function()
	local started = os.clock()
	local shown = pcall(function()
		tween(squareScale, ButtonFx.POP, {Scale = 1})
		tween(logo, ButtonFx.POP, {Rotation = 0})
		tween(track, ButtonFx.FAST, {BackgroundTransparency = 0.8})
		tween(fill, ButtonFx.FAST, {BackgroundTransparency = 0.15})
		local ok, err = pcall(init)
		if not ok then
			initError = tostring(err)
		end
		local remaining = MIN_SHOW - (os.clock() - started)
		if remaining > 0 then
			task.wait(remaining)
		end
		if finished then
			return
		end
		tween(track, ButtonFx.FAST, {BackgroundTransparency = 1})
		tween(fill, ButtonFx.FAST, {BackgroundTransparency = 1})
		finish(true)
	end)
	if not shown then
		finish(false)
	end
end)

end

-- StarterGui.ScreenGui.Accounts (LocalScript)
SOURCES[11] = function(script, require)
-- Accounts page: the Roblox accounts with saved scripts on this device, signed-in one first. Another
-- account's scripts can be copied into yours, or its saves deleted. Launching or switching
-- accounts (and showing Robux) would need the .ROBLOSECURITY cookie, which this hub never touches.
local Players = game:GetService("Players")

local Gui = script.Parent
local Storage = require(Gui.Storage)
local ButtonFx = require(Gui.ButtonFx)
local ScriptActions = require(Gui.ScriptActions)

local page = Gui.accountmanager
local list = page.ScrollingFrame
local player = Players.LocalPlayer

local WHITE = Color3.new(1, 1, 1)
local COPY_ICON = "rbxassetid://10709812159"
local SORTS = {"Recent", "Most scripts", "Name"}
local ONLY_ONE = "Only this account has saves on this device"

local connections = {}
local function track(connection)
	table.insert(connections, connection)
	return connection
end

-- the page ships with five copies of a placeholder account; keep one as the row template
local template
for _, child in list:GetChildren() do
	if child:IsA("Frame") then
		template = template or child:Clone()
		child:Destroy()
	end
end

local function linesOf(container)
	local primary, secondary
	for _, child in container:GetChildren() do
		if child:IsA("TextLabel") then
			if child.TextSize >= 20 then
				primary = child
			else
				secondary = child
			end
		end
	end
	return primary, secondary
end

for _, child in template:GetChildren() do
	if child.Name == "TextContainer" then
		local primary, secondary = linesOf(child)
		child.Name = secondary.Text:sub(1, 1) == "@" and "Identity" or "Saves"
		primary.Name, secondary.Name = "Primary", "Secondary"
		primary.TextTruncate = Enum.TextTruncate.AtEnd
		secondary.TextTruncate = Enum.TextTruncate.AtEnd
	end
end
-- the placeholder's second column was a green Robux balance; it's muted info text now
template.Saves.Secondary.TextColor3 = WHITE
template.Saves.Secondary.TextTransparency = 0.5

local tiles = {}
for _, child in template.buttoncontainer:GetChildren() do
	if child:IsA("TextButton") then
		table.insert(tiles, child)
	end
end
-- launch / switch / remove in the design; switching needs the cookie, so that tile goes
tiles[1].Name = "Copy"
tiles[1].ImageLabel.Image = COPY_ICON
tiles[2]:Destroy()
tiles[3].Name = "Delete"

-- the last row used to sit under the toolbar with no way to scroll it clear
local listPad = list:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding", list)
listPad.PaddingBottom = UDim.new(0, 56)

local status = Instance.new("TextLabel")
status.Name = "Status"
status.BackgroundTransparency = 1
status.AnchorPoint = Vector2.new(0, 1)
status.Position = UDim2.new(0, 72, 1, 0)
status.Size = UDim2.new(1, -460, 0, 36)
status.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
status.TextSize = 14
status.TextColor3 = WHITE
status.TextTransparency = 0.5
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd
status.Text = ""
status.Parent = page

local function setStatus(text, isError)
	status.Text = text or ""
	status.TextColor3 = isError and ButtonFx.DANGER or WHITE
	status.TextTransparency = isError and 0 or 0.5
end

local function plural(count, word)
	return count .. " " .. word .. (count == 1 and "" or "s")
end

-- usernames for other accounts come from Roblox once and are cached for the session
local usernames = {}
local function withNames(uid, apply)
	if uid == player.UserId then
		apply(player.DisplayName, player.Name)
		return
	end
	if usernames[uid] then
		apply(usernames[uid], usernames[uid])
		return
	end
	apply("Account " .. uid, tostring(uid))
	task.spawn(function()
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, uid)
		if ok and name then
			usernames[uid] = name
			apply(name, name)
		end
	end)
end

local sortMode = 1
local query = ""
local rows = {} -- {frame, search}

local function applyFilter()
	local needle = query:lower()
	for _, row in rows do
		row.frame.Visible = needle == "" or row.search():lower():find(needle, 1, true) ~= nil
	end
end

local render -- forward, the row actions refresh the list

local function addRow(info, order)
	local frame = template:Clone()
	frame.Name = "Account" .. info.userId
	frame.LayoutOrder = order
	frame.ImageLabel.Image = "rbxthumb://type=AvatarHeadShot&id=" .. info.userId .. "&w=150&h=150"
	local identity, saves = frame.Identity, frame.Saves

	local names = {display = "", user = ""}
	withNames(info.userId, function(display, user)
		names.display, names.user = display, user
		identity.Primary.Text = display
		identity.Secondary.Text = "@" .. user
	end)

	saves.Primary.Text = info.count == 0 and "No scripts" or plural(info.count, "script")
	saves.Secondary.Text = info.current and "Signed in" or "Last saved " .. ScriptActions.ago(info.updated)
	if info.current then
		frame.UIStroke.Transparency = 0.1 -- the signed-in row stands out a little
	end

	local tileRow = frame.buttoncontainer
	local copy, delete = tileRow.Copy, tileRow.Delete
	if info.current then
		copy:Destroy() -- nothing to copy into yourself
	else
		ButtonFx.bind(copy)
		copy.Activated:Connect(function()
			local count, err = Storage.copyFrom(info.userId)
			if count > 0 then
				setStatus("Copied " .. plural(count, "script") .. " from @" .. names.user .. (err and " (" .. err .. ")" or ""))
			else
				setStatus(err or "You already have everything from @" .. names.user, err ~= nil)
			end
		end)
	end

	if info.count == 0 then
		delete.Visible = false
	else
		ButtonFx.twoStep(delete, function()
			local ok, result = Storage.clearAccount(info.userId)
			if ok then
				setStatus("Deleted " .. plural(result, "script") .. (info.current and " from your account" or " saved for @" .. names.user))
			else
				setStatus(result, true)
			end
		end, function()
			setStatus("Tap again to delete " .. plural(info.count, "script") .. (info.current and " from your account" or " saved for @" .. names.user))
		end)
	end

	frame.Parent = list
	table.insert(rows, {
		frame = frame,
		search = function()
			return names.display .. " " .. names.user .. " " .. info.userId
		end,
	})
end

local SORTERS = {
	function(a, b)
		return a.updated > b.updated
	end,
	function(a, b)
		return a.count > b.count
	end,
	function(a, b)
		return (usernames[a.userId] or tostring(a.userId)):lower() < (usernames[b.userId] or tostring(b.userId)):lower()
	end,
}

render = function()
	for _, row in rows do
		row.frame:Destroy()
	end
	table.clear(rows)
	local accounts = Storage.accounts()
	local signedIn = table.remove(accounts, 1)
	table.sort(accounts, SORTERS[sortMode])
	if signedIn then
		table.insert(accounts, 1, signedIn)
	end
	for i, info in accounts do
		addRow(info, i)
	end
	applyFilter()
	if #accounts <= 1 then
		setStatus(ONLY_ONE)
	elseif status.Text == ONLY_ONE then
		setStatus("")
	end
end

-- the Search bar was a placeholder button; a TextBox inside it makes it filter the list
local searchBar = page:FindFirstChild("TextButton")
if searchBar then
	local placeholder = searchBar:FindFirstChildOfClass("TextLabel")
	local box = Instance.new("TextBox")
	box.Name = "SearchBox"
	box.BackgroundTransparency = 1
	box.Size = UDim2.new(1, -28, 1, 0)
	box.LayoutOrder = placeholder and placeholder.LayoutOrder or 2
	box.FontFace = placeholder and placeholder.FontFace or status.FontFace
	box.TextSize = 16
	box.TextColor3 = WHITE
	box.PlaceholderText = "Search accounts..."
	box.PlaceholderColor3 = Color3.fromRGB(110, 112, 120)
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false
	box.Text = ""
	if placeholder then
		placeholder.Visible = false
	end
	box.Parent = searchBar
	track(box:GetPropertyChangedSignal("Text"):Connect(function()
		query = box.Text
		applyFilter()
	end))
	track(searchBar.Activated:Connect(function()
		box:CaptureFocus()
	end))
end

for _, b in page.Toolbar2:GetChildren() do
	local label = b:IsA("TextButton") and b:FindFirstChild("TextLabel")
	if label then
		if label.Text == "Export" then
			b.Activated:Connect(function()
				ScriptActions.export(setStatus)
			end)
		elseif label.Text == "Import" then
			b.Activated:Connect(function()
				ScriptActions.import(setStatus)
			end)
		elseif label.Text == "Clear" then
			ButtonFx.twoStep(b, function()
				local ok, result = Storage.clearAccount()
				setStatus(ok and "Deleted " .. plural(result, "script") .. " from your account" or result, not ok)
			end, function()
				setStatus("Tap again to delete all of your saved scripts")
			end)
		elseif label.Text == "Filter" then
			label.Text = SORTS[sortMode]
			b.Activated:Connect(function()
				sortMode = sortMode % #SORTS + 1
				label.Text = SORTS[sortMode]
				render()
				setStatus("Sorted by " .. SORTS[sortMode]:lower())
			end)
		end
	end
end

-- redraw when anything is saved or deleted, and when the page is opened
local queued = false
local function queueRender()
	if queued then
		return
	end
	queued = true
	task.defer(function()
		queued = false
		render()
	end)
end
track(Storage.changed:Connect(queueRender))
track(page:GetPropertyChangedSignal("Visible"):Connect(function()
	if page.Visible then
		queueRender()
	end
end))

Gui.Destroying:Once(function()
	for _, connection in connections do
		connection:Disconnect()
	end
end)

Storage.setAccount(player.UserId)
render()

end

-- StarterGui.ScreenGui.Layout (ModuleScript)
SOURCES[12] = function(script, require)
-- Screen size in GUI units (points on a phone) and whether the GUI uses its compact phone layout.
-- Short or narrow screens get compact controls (44pt tap targets); larger screens keep the original
-- 800x502 design untouched. Set the ScreenGui attribute EmulateViewport (a Vector2) to preview a
-- phone size in Studio.
local Gui = script.Parent

local Layout = {}
Layout.TAP = 44
local WINDOW = Vector2.new(800, 502)
local FILL = 0.92

local changed = Instance.new("BindableEvent")
Layout.changed = changed.Event -- viewport or compact mode changed
local applied = Instance.new("BindableEvent")
Layout.applied = applied.Event -- Responsive finished resizing things; positions can be measured again

local function uiScale()
	local s = Gui:FindFirstChildOfClass("UIScale")
	return s and s.Scale or 1
end

-- the whole ScreenGui in GUI units
function Layout.screen()
	return Gui.AbsoluteSize / uiScale()
end

local function measure()
	local emulated = Gui:GetAttribute("EmulateViewport")
	if typeof(emulated) == "Vector2" then
		return emulated
	end
	return Layout.screen()
end

-- the window's size: 92% of the viewport, never bigger than the original design
function Layout.window()
	local v = Layout.viewport
	return Vector2.new(math.min(math.floor(v.X * FILL), WINDOW.X), math.min(math.floor(v.Y * FILL), WINDOW.Y))
end

-- the viewport's edges in the ScreenGui's GUI units; an emulated viewport sits in the middle
function Layout.bounds()
	local screen = Layout.screen()
	local offset = (screen - Layout.viewport) / 2
	return offset.X, offset.Y, offset.X + Layout.viewport.X, offset.Y + Layout.viewport.Y
end

function Layout.refresh()
	local viewport = measure()
	if viewport.X <= 0 or viewport.Y <= 0 then
		return -- not on screen yet
	end
	local compact = viewport.X < 1000 or viewport.Y < 600
	if viewport ~= Layout.viewport or compact ~= Layout.compact then
		Layout.viewport = viewport
		Layout.compact = compact
		changed:Fire()
	end
end

function Layout.markApplied()
	applied:Fire()
end

-- the height for a row of controls: the design's 36, or a full tap target on a phone
function Layout.control()
	return Layout.compact and Layout.TAP or 36
end

Layout.viewport = WINDOW
Layout.compact = false
Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(Layout.refresh)
Gui:GetAttributeChangedSignal("EmulateViewport"):Connect(Layout.refresh)
Layout.refresh()

return Layout

end

-- StarterGui.ScreenGui.Responsive (LocalScript)
SOURCES[13] = function(script, require)
-- Applies Layout to the shared parts of the GUI: window size and position, the sidebar, the page
-- toolbars, the Library panel and the fixed-height search bars and toggles. Large screens keep the
-- original design exactly; on a phone the window fits the screen instead of shrinking, and the
-- controls grow to full 44pt tap targets.
local Gui = script.Parent
local Layout = require(Gui.Layout)

local PAGES = {Gui.main, Gui.scriptstroe, Gui.output, Gui.settings, Gui.accountmanager}
local library = Gui.library
local TAP = Layout.TAP

-- design values, recorded once so leaving compact mode puts everything back exactly
local original = {}
local function remember(obj, props)
	local saved = original[obj] or {}
	original[obj] = saved
	for _, prop in props do
		if saved[prop] == nil then
			saved[prop] = obj[prop]
		end
	end
	return saved
end

local function setHeight(obj, compact)
	local saved = remember(obj, {"Size"})
	local size = saved.Size
	obj.Size = compact and UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, math.max(size.Y.Offset, TAP)) or size
end

local function sidebar(page, compact)
	local bar = page:FindFirstChild("SideBar")
	if not bar then
		return
	end
	local pad = bar:FindFirstChildOfClass("UIPadding")
	local savedPad = remember(pad, {"PaddingTop", "PaddingBottom"})
	-- seven 44pt icons need 308pt; trimming the padding and gaps makes that fit a 360pt-tall phone
	pad.PaddingTop = compact and UDim.new(0, 2) or savedPad.PaddingTop
	pad.PaddingBottom = compact and UDim.new(0, 2) or savedPad.PaddingBottom
	local content = bar:FindFirstChild("Content")
	local list = content and content:FindFirstChildOfClass("UIListLayout")
	if not list then
		return
	end
	local savedList = remember(list, {"Padding", "HorizontalAlignment"})
	list.Padding = compact and UDim.new(0, 0) or savedList.Padding
	list.HorizontalAlignment = compact and Enum.HorizontalAlignment.Center or savedList.HorizontalAlignment
	for _, item in content:GetChildren() do
		if item:IsA("GuiObject") then
			local limit = item:FindFirstChild("CompactSize")
			if compact and not limit then
				limit = Instance.new("UISizeConstraint")
				limit.Name = "CompactSize"
				limit.MaxSize = Vector2.new(TAP, TAP)
				limit.Parent = item
			elseif not compact and limit then
				limit:Destroy()
			end
		end
	end
end

-- toolbars stay on one line when they fit and wrap onto a second row when they don't
local function toolbar(page, compact)
	local bar = page:FindFirstChild("Toolbar2")
	if not bar then
		return
	end
	local list = bar:FindFirstChildOfClass("UIListLayout")
	local scale = bar:FindFirstChildOfClass("UIScale")
	local saved = remember(bar, {"Size", "AutomaticSize"})
	local savedList = remember(list, {"Wraps"})
	local savedScale = scale and remember(scale, {"Scale"})
	if scale then
		-- the Accounts toolbar is scaled to 1.13 (36pt tall); a phone needs it at a full tap height
		scale.Scale = compact and math.max(savedScale.Scale, TAP / saved.Size.Y.Offset) or savedScale.Scale
	end
	bar.AutomaticSize = saved.AutomaticSize
	bar.Size = saved.Size
	list.Wraps = savedList.Wraps
	-- buttons are "100% of the bar's height"; once a wrapping bar sizes itself to its buttons that
	-- feeds back on itself, so wrapped buttons and dividers get a fixed height instead
	local items = {}
	for _, item in bar:GetChildren() do
		if item:IsA("GuiObject") then
			items[item] = remember(item, {"Size"}).Size
			item.Size = items[item]
		end
	end
	if not compact then
		return
	end
	task.wait() -- let it lay out at its natural width first
	local k = scale and scale.Scale or 1
	local guiScale = Layout.screen().X > 0 and Gui.AbsoluteSize.X / Layout.screen().X or 1
	local pagePad = page:FindFirstChildOfClass("UIPadding")
	local inner = page.AbsoluteSize.X / guiScale - pagePad.PaddingLeft.Offset - pagePad.PaddingRight.Offset
	local available = inner - 72
	if bar.AbsoluteSize.X / guiScale > available then
		local rowHeight = saved.Size.Y.Offset
		for item, size in items do
			item.Size = UDim2.new(size.X.Scale, size.X.Offset, 0, math.floor(rowHeight * size.Y.Scale + size.Y.Offset))
		end
		bar.AutomaticSize = Enum.AutomaticSize.Y
		bar.Size = UDim2.fromOffset(available / k, rowHeight)
		list.Wraps = true
	end
end

local home -- the design's window position, for going back to a large screen
local wasCompact = false

local function apply()
	local compact = Layout.compact
	local window = Layout.window()
	home = home or {anchor = Gui.main.AnchorPoint, position = Gui.main.Position}
	for _, page in PAGES do
		page.Size = UDim2.fromOffset(window.X, window.Y)
		if compact then
			page.AnchorPoint = Vector2.new(0.5, 0.5)
			page.Position = UDim2.fromScale(0.5, 0.5)
		elseif wasCompact then
			page.AnchorPoint, page.Position = home.anchor, home.position
		end
		local pad = page:FindFirstChildOfClass("UIPadding")
		if pad then
			local saved = remember(pad, {"PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom"})
			for side, value in saved do
				pad[side] = compact and UDim.new(0, 8) or value
			end
		end
		sidebar(page, compact)
		-- the page-level search bars (Accounts, Settings) are 36 tall in the design
		local search = page:FindFirstChild("TextButton")
		if search and search:FindFirstChild("TextLabel") then
			setHeight(search, compact)
		end
	end
	-- the editor's file tabs (and the + beside them) take their height from this row
	setHeight(Gui.main.Topbar, compact)
	library.Size = UDim2.fromOffset(library.Size.X.Offset, window.Y)
	for _, button in {library:FindFirstChild("TextButton"), library.ScrollingFrame:FindFirstChild("TextButton")} do
		setHeight(button, compact)
	end
	for _, row in Gui.settings.ScrollingFrame:GetChildren() do
		local buttons = row:FindFirstChild("ButtonContainer")
		if buttons then
			for _, toggle in buttons:GetChildren() do
				if toggle:IsA("TextButton") then
					setHeight(toggle, compact)
				end
			end
		end
	end
	wasCompact = compact
	for _, page in PAGES do
		toolbar(page, compact)
	end
	Layout.markApplied()
end

local running, again = false, false
local function schedule()
	if running then
		again = true
		return
	end
	running = true
	task.defer(function()
		repeat
			again = false
			apply()
		until not again
		running = false
	end)
end

local changed = Layout.changed:Connect(schedule)
Gui.Destroying:Once(function()
	changed:Disconnect()
end)
schedule()

end

-- StarterGui.ScreenGui.OutputLog (ModuleScript)
SOURCES[14] = function(script, require)
-- what the Output page shows: the game's console (LogService) plus the hub's own lines when it runs a
-- script. Entries are {time, kind, text, hub}; kind is print / info / warn / error / run, and `hub`
-- marks lines the hub wrote itself.
local LogService = game:GetService("LogService")

local Gui = script.Parent
local Settings = require(Gui.Settings)

local MAX_TEXT = 4000
local BACKFILL = 100 -- console lines from before the GUI loaded

local KINDS = {
	[Enum.MessageType.MessageOutput] = "print",
	[Enum.MessageType.MessageInfo] = "info",
	[Enum.MessageType.MessageWarning] = "warn",
	[Enum.MessageType.MessageError] = "error",
}

local OutputLog = {}

OutputLog.FILTERS = {
	{name = "All", match = function()
		return true
	end},
	{name = "Errors", match = function(entry)
		return entry.kind == "error"
	end},
	{name = "Warnings", match = function(entry)
		return entry.kind == "warn"
	end},
	{name = "Prints", match = function(entry)
		return entry.kind == "print" or entry.kind == "info"
	end},
	{name = "Runs", match = function(entry)
		return entry.hub == true
	end},
}

local entries = {}
local changed = Instance.new("BindableEvent")
OutputLog.changed = changed.Event -- ("add", entry), ("remove", entry) or ("clear")

local function trim()
	local limit = Settings.get("outputHistory")
	while #entries > limit do
		changed:Fire("remove", table.remove(entries, 1))
	end
end

local function push(kind, text, time, hub)
	text = tostring(text)
	if #text > MAX_TEXT then
		text = text:sub(1, MAX_TEXT) .. " ..."
	end
	local entry = {time = time or os.time(), kind = kind, text = text, hub = hub}
	table.insert(entries, entry)
	changed:Fire("add", entry)
	trim()
	return entry
end

function OutputLog.add(kind, text)
	return push(kind, text, nil, true)
end

function OutputLog.clear()
	table.clear(entries)
	changed:Fire("clear")
end

function OutputLog.entries()
	return entries
end

-- plain text for Copy / Save, optionally only what a filter shows
function OutputLog.text(filter)
	local lines = {}
	for _, entry in entries do
		if not filter or filter.match(entry) then
			table.insert(lines, os.date("%H:%M:%S", entry.time) .. "  " .. entry.kind:upper() .. "  " .. entry.text)
		end
	end
	return table.concat(lines, "\n"), #lines
end

local ok, history = pcall(LogService.GetLogHistory, LogService)
if ok and type(history) == "table" then
	for i = math.max(1, #history - BACKFILL + 1), #history do
		local line = history[i]
		push(KINDS[line.messageType] or "print", line.message, math.floor(tonumber(line.timestamp) or os.time()))
	end
end

local connections = {
	LogService.MessageOut:Connect(function(message, messageType)
		push(KINDS[messageType] or "print", message)
	end),
	Settings.changed:Connect(function(key)
		if key == nil or key == "outputHistory" then
			trim()
		end
	end),
}
Gui.Destroying:Once(function()
	for _, connection in connections do
		connection:Disconnect()
	end
end)

return OutputLog

end

-- StarterGui.ScreenGui.Settings (ModuleScript)
SOURCES[15] = function(script, require)
-- the hub's settings. Saved to hub_settings.json in the executor's workspace when it has file
-- access; otherwise they last for the session (kept in `shared`, like memory saves).
local HttpService = game:GetService("HttpService")

local FILE = "hub_settings.json"
local DEFAULTS = {
	autoScroll = true,
	openOutputOnRun = true,
	editorTextSize = 16,
	outputTextSize = 14,
	outputHistory = 500,
}

local Settings = {DEFAULTS = DEFAULTS}
local changed = Instance.new("BindableEvent")
Settings.changed = changed.Event -- (key, value); key is nil after a reset or import

local files = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
shared.ScriptHubSettings = shared.ScriptHubSettings or {}
local values = shared.ScriptHubSettings

local function valid(key, value)
	return DEFAULTS[key] ~= nil and type(value) == type(DEFAULTS[key])
end

-- takes the known keys from a decoded table; returns how many were usable
local function apply(source)
	local count = 0
	if type(source) == "table" then
		for key in DEFAULTS do
			if valid(key, source[key]) then
				values[key] = source[key]
				count += 1
			end
		end
	end
	return count
end

local function persist()
	if files then
		pcall(writefile, FILE, HttpService:JSONEncode(values))
	end
end

if files then
	local ok, raw = pcall(function()
		return isfile(FILE) and readfile(FILE)
	end)
	if ok and type(raw) == "string" then
		local decoded, saved = pcall(HttpService.JSONDecode, HttpService, raw)
		if decoded then
			apply(saved)
		end
	end
end

function Settings.get(key)
	local value = values[key]
	if value == nil then
		return DEFAULTS[key]
	end
	return value
end

function Settings.isDefault(key)
	return Settings.get(key) == DEFAULTS[key]
end

function Settings.set(key, value)
	if not valid(key, value) then
		return false
	end
	if Settings.get(key) == value then
		return true
	end
	values[key] = value
	persist()
	changed:Fire(key, value)
	return true
end

function Settings.reset()
	table.clear(values)
	persist()
	changed:Fire(nil)
end

function Settings.export()
	local current = {}
	for key in DEFAULTS do
		current[key] = Settings.get(key)
	end
	return HttpService:JSONEncode({settings = current})
end

-- an export() string (or the bare table inside it); returns how many settings it changed
function Settings.import(json)
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, tostring(json))
	if not ok or type(decoded) ~= "table" then
		return 0, "That isn't a settings export"
	end
	local count = apply(type(decoded.settings) == "table" and decoded.settings or decoded)
	if count == 0 then
		return 0, "That isn't a settings export"
	end
	persist()
	changed:Fire(nil)
	return count
end

return Settings

end

-- StarterGui.ScreenGui.Toast (ModuleScript)
SOURCES[16] = function(script, require)
-- the small message that pops up at the bottom of the window; one at a time, the newest wins
local Gui = script.Parent
local ButtonFx = require(Gui.ButtonFx)

local Toast = {}

local label = Instance.new("TextLabel")
label.Name = "Toast"
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 1, -24)
label.AutomaticSize = Enum.AutomaticSize.XY
label.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
label.TextColor3 = Color3.new(1, 1, 1)
label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
label.TextSize = 16
label.Visible = false
label.ZIndex = 50
Instance.new("UICorner", label)
local pad = Instance.new("UIPadding", label)
pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 14), UDim.new(0, 14)
pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
label.Parent = Gui

local current = 0
function Toast.notify(text, isError)
	current += 1
	local id = current
	label.Text = text
	label.TextColor3 = isError and ButtonFx.DANGER or Color3.new(1, 1, 1)
	label.Visible = true
	task.delay(2.5, function()
		if current == id then
			label.Visible = false
		end
	end)
end

return Toast

end

-- StarterGui.ScreenGui.SettingsPage (LocalScript)
SOURCES[17] = function(script, require)
-- Settings page: the design's placeholder rows become the hub's settings (the Settings module).
-- Toggles flip on tap; sliders drag (or tap a spot on the track).
local UserInputService = game:GetService("UserInputService")

local Gui = script.Parent
local ButtonFx = require(Gui.ButtonFx)
local Settings = require(Gui.Settings)
local notify = require(Gui.Toast).notify

local page = Gui.settings
local list = page.ScrollingFrame
local editor = Gui.main.ScrollingFrame.TextBox

local WHITE = Color3.new(1, 1, 1)
local setClipboard = setclipboard or toclipboard
local getClipboard = getclipboard or fromclipboard

local ROWS = {
	{key = "autoScroll", kind = "toggle", name = "Auto-scroll output",
		info = "Keep the newest line in view on the Output page"},
	{key = "openOutputOnRun", kind = "toggle", name = "Open Output on Run",
		info = "Switch to Output when you run the Editor's script"},
	{key = "editorTextSize", kind = "slider", name = "Editor text size",
		info = "Size of the code in the Editor", min = 12, max = 24, step = 1, unit = " px", live = true},
	{key = "outputTextSize", kind = "slider", name = "Output text size",
		info = "Size of the lines on the Output page", min = 12, max = 20, step = 1, unit = " px", live = true},
	{key = "outputHistory", kind = "slider", name = "Output history",
		info = "Lines Output keeps before dropping the oldest", min = 100, max = 1000, step = 50, unit = " lines"},
}

local connections = {}
local function track(connection)
	table.insert(connections, connection)
	return connection
end

local function linesOf(container)
	local primary, secondary
	for _, child in container:GetChildren() do
		if child:IsA("TextLabel") then
			if child.TextSize >= 20 then
				primary = child
			else
				secondary = child
			end
		end
	end
	return primary, secondary
end

-- the design has two toggle rows and three slider rows, in that order: reuse them in place
local toggleRows, sliderRows = {}, {}
for _, row in list:GetChildren() do
	if row:IsA("Frame") then
		if row:FindFirstChild("ButtonContainer") then
			table.insert(toggleRows, row)
		elseif row:FindFirstChild("Slider") then
			table.insert(sliderRows, row)
		end
	end
end

local rows = {} -- {frame, spec, show(value, animate)}

local function label(row, spec)
	-- the left text column was 100 wide with 200-wide labels spilling out of it
	local left
	for _, child in row:GetChildren() do
		if child.Name == "TextContainer" and child.AnchorPoint.X == 0 then
			left = child
		end
	end
	left.Size = UDim2.new(1, -140, left.Size.Y.Scale, left.Size.Y.Offset)
	local primary, secondary = linesOf(left)
	for _, l in {primary, secondary} do
		l.Size = UDim2.fromScale(1, 0)
		l.TextTruncate = Enum.TextTruncate.AtEnd
	end
	primary.Text = spec.name
	secondary.Text = spec.info
end

local function setupToggle(row, spec)
	label(row, spec)
	local button = row.ButtonContainer:FindFirstChildOfClass("TextButton")
	local knob = button.In
	local function show(on, animate)
		local goal = {BackgroundTransparency = on and 0 or 0.95}
		if animate then
			ButtonFx.tween(knob, ButtonFx.FAST, goal)
			ButtonFx.bounce(knob)
		else
			knob.BackgroundTransparency = goal.BackgroundTransparency
		end
	end
	track(button.Activated:Connect(function()
		Settings.set(spec.key, not Settings.get(spec.key))
	end))
	return show
end

local function format(spec, value)
	return tostring(value) .. spec.unit
end

local function setupSlider(row, spec)
	label(row, spec)
	local bar = row.Slider
	local fill, marker = bar.FillWrap, bar.Marker
	local value
	for _, child in row:GetChildren() do
		if child.Name == "TextContainer" and child.AnchorPoint.X == 1 then
			value = linesOf(child)
		end
	end

	local function show(v, animate)
		local alpha = (v - spec.min) / (spec.max - spec.min)
		local goals = {{fill, {Size = UDim2.fromScale(alpha, 1)}}, {marker, {Position = UDim2.fromScale(alpha, 0.5)}}}
		for _, goal in goals do
			if animate then
				ButtonFx.tween(goal[1], ButtonFx.FAST, goal[2])
			else
				for property, target in goal[2] do
					goal[1][property] = target
				end
			end
		end
		value.Text = format(spec, v)
	end

	-- the track is 8px tall; a taller invisible strip takes the drag
	local grab = Instance.new("TextButton")
	grab.Name = "Grab"
	grab:SetAttribute("NoFx", true)
	grab.Text = ""
	grab.BackgroundTransparency = 1
	grab.AnchorPoint = Vector2.new(0.5, 0.5)
	grab.Position = UDim2.fromScale(0.5, 0.5)
	grab.Size = UDim2.new(1, 24, 0, 44)
	grab.ZIndex = marker.ZIndex + 1
	grab.Parent = bar

	local dragging, pending = false, nil
	local function at(x)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
		return spec.min + math.floor(alpha * (spec.max - spec.min) / spec.step + 0.5) * spec.step
	end
	local function move(x)
		local v = at(x)
		if v == pending then
			return
		end
		pending = v
		show(v, false)
		if spec.live then
			Settings.set(spec.key, v)
		end
	end
	local function isPress(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	track(grab.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging, pending = true, nil
			ButtonFx.tween(ButtonFx.scaleOf(marker), ButtonFx.FAST, {Scale = 1.3})
			move(input.Position.X)
		end
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			move(input.Position.X)
		end
	end))
	track(UserInputService.InputEnded:Connect(function(input)
		if dragging and isPress(input) then
			dragging = false
			ButtonFx.tween(ButtonFx.scaleOf(marker), ButtonFx.POP, {Scale = 1})
			if pending then
				Settings.set(spec.key, pending)
			end
		end
	end))
	return show
end

for i, spec in ROWS do
	local frame = table.remove(spec.kind == "toggle" and toggleRows or sliderRows, 1)
	if frame then
		frame.Name = spec.key
		frame.LayoutOrder = i
		local show = spec.kind == "toggle" and setupToggle(frame, spec) or setupSlider(frame, spec)
		show(Settings.get(spec.key), false)
		table.insert(rows, {frame = frame, spec = spec, show = show})
	end
end
-- any spare placeholder rows (none in the design) would only confuse
for _, frame in toggleRows do
	frame:Destroy()
end
for _, frame in sliderRows do
	frame:Destroy()
end

-- what the settings do outside Output (which reads its own)
local function applyEditor()
	editor.TextSize = Settings.get("editorTextSize")
end
applyEditor()

local query, changedOnly = "", false
local function applyFilter()
	local needle = query:lower()
	for _, row in rows do
		local text = (row.spec.name .. " " .. row.spec.info):lower()
		row.frame.Visible = (needle == "" or text:find(needle, 1, true) ~= nil)
			and (not changedOnly or not Settings.isDefault(row.spec.key))
	end
end

track(Settings.changed:Connect(function(key)
	for _, row in rows do
		if key == nil or row.spec.key == key then
			row.show(Settings.get(row.spec.key), true)
		end
	end
	if key == nil or key == "editorTextSize" then
		applyEditor()
	end
	applyFilter()
end))

-- the Search bar was a placeholder button; a TextBox inside it filters the rows
local searchBar = page:FindFirstChild("TextButton")
if searchBar then
	local placeholder = searchBar:FindFirstChildOfClass("TextLabel")
	local box = Instance.new("TextBox")
	box.Name = "SearchBox"
	box.BackgroundTransparency = 1
	box.Size = UDim2.new(1, -28, 1, 0)
	box.LayoutOrder = placeholder and placeholder.LayoutOrder or 2
	box.FontFace = placeholder and placeholder.FontFace or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
	box.TextSize = 16
	box.TextColor3 = WHITE
	box.PlaceholderText = "Search settings..."
	box.PlaceholderColor3 = Color3.fromRGB(110, 112, 120)
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false
	box.Text = ""
	if placeholder then
		placeholder.Visible = false
	end
	box.Parent = searchBar
	track(box:GetPropertyChangedSignal("Text"):Connect(function()
		query = box.Text
		applyFilter()
	end))
	track(searchBar.Activated:Connect(function()
		box:CaptureFocus()
	end))
end

local function importFrom(text)
	if type(text) ~= "string" or text == "" then
		return 0, nil
	end
	return Settings.import(text)
end

for _, b in page.Toolbar2:GetChildren() do
	local label = b:IsA("TextButton") and b:FindFirstChild("TextLabel")
	if label then
		if label.Text == "Reset" then
			ButtonFx.twoStep(b, function()
				Settings.reset()
				notify("Settings reset")
			end, function()
				notify("Tap again to reset every setting")
			end)
		elseif label.Text == "Export" then
			b.Activated:Connect(function()
				local json = Settings.export()
				if setClipboard then
					setClipboard(json)
					notify("Copied your settings")
				else
					editor.Text = json
					editor:SetAttribute("ScriptName", nil)
					notify("No clipboard here: the export is in the Editor tab")
				end
			end)
		elseif label.Text == "Import" then
			-- from the clipboard when the executor can read it, otherwise from the Editor tab
			b.Activated:Connect(function()
				local ok, clip = pcall(function()
					return getClipboard and getClipboard()
				end)
				local count, err = importFrom(ok and clip or nil)
				if count == 0 then
					count, err = importFrom(editor.Text)
				end
				if count > 0 then
					notify("Imported " .. count .. (count == 1 and " setting" or " settings"))
				else
					notify(err or "Copy a settings export first", true)
				end
			end)
		elseif label.Text == "Filter" then
			label.Text = "All"
			b.Activated:Connect(function()
				changedOnly = not changedOnly
				label.Text = changedOnly and "Changed" or "All"
				applyFilter()
				notify(changedOnly and "Showing settings you've changed" or "Showing every setting")
			end)
		end
	end
end

Gui.Destroying:Once(function()
	for _, connection in connections do
		connection:Disconnect()
	end
end)

end

-- StarterGui.ScreenGui.Output (LocalScript)
SOURCES[18] = function(script, require)
-- Output page: a live log of the game's console and of what Run / Execute did (OutputLog), newest
-- at the bottom. Tap a line to copy it.
local Gui = script.Parent
local ButtonFx = require(Gui.ButtonFx)
local OutputLog = require(Gui.OutputLog)
local Settings = require(Gui.Settings)
local notify = require(Gui.Toast).notify

local page = Gui.output
local scroller = page.ScrollingFrame

local WHITE = Color3.new(1, 1, 1)
local TEXT_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local STATUS_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
local STYLE = {
	print = {WHITE, 0.15},
	info = {WHITE, 0.45},
	warn = {ButtonFx.FAV, 0},
	error = {ButtonFx.DANGER, 0},
	run = {ButtonFx.ACCENT, 0},
}
local GUTTER = 72
local EMPTY = "Nothing here yet.\nRun a script and what it prints shows up here."
local FILTERS = OutputLog.FILTERS
local setClipboard = setclipboard or toclipboard

local connections = {}
local function track(connection)
	table.insert(connections, connection)
	return connection
end

-- the design's sample line and timestamp gutter go; the gutter's font stays for the times
local gutter = scroller:FindFirstChild("Gutter")
local sample = gutter and gutter:FindFirstChildOfClass("TextLabel")
local TIME_FONT = sample and sample.FontFace or TEXT_FONT
for _, child in scroller:GetChildren() do
	if child:IsA("GuiObject") or child:IsA("UIListLayout") or child:IsA("UIPadding") then
		child:Destroy()
	end
end
scroller.ScrollingDirection = Enum.ScrollingDirection.Y
scroller.CanvasSize = UDim2.new()
scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroller
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 12)
pad.PaddingBottom = UDim.new(0, 60) -- clear of the toolbar
pad.PaddingLeft = UDim.new(0, 4)
pad.PaddingRight = UDim.new(0, 12)
pad.Parent = scroller

local empty = Instance.new("TextLabel")
empty.Name = "Empty"
empty.BackgroundTransparency = 1
empty.AnchorPoint = Vector2.new(0.5, 0.5)
empty.Position = UDim2.new(0.5, 36, 0.5, -20)
empty.Size = UDim2.new(1, -140, 0, 60)
empty.FontFace = STATUS_FONT
empty.TextSize = 15
empty.TextColor3 = WHITE
empty.TextTransparency = 0.6
empty.TextWrapped = true
empty.Text = EMPTY
empty.Parent = page

local status = Instance.new("TextLabel")
status.Name = "Status"
status.BackgroundTransparency = 1
status.AnchorPoint = Vector2.new(0, 1)
status.Position = UDim2.new(0, 84, 1, 0)
status.Size = UDim2.new(1, -440, 0, 51)
status.FontFace = STATUS_FONT
status.TextSize = 14
status.TextColor3 = WHITE
status.TextTransparency = 0.5
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd
status.Parent = page

local filterIndex = 1
local rows = {} -- [entry] = row
local order = 0

local function matches(entry)
	return FILTERS[filterIndex].match(entry)
end

local function sizeRow(row)
	local size = Settings.get("outputTextSize")
	row.Time.TextSize = size - 1
	row.Message.TextSize = size
end

-- follow the newest line while the view is at the bottom; scrolling up stops that until you're back
local follow, jumping = true, false
local function atBottom()
	return scroller.CanvasPosition.Y >= scroller.AbsoluteCanvasSize.Y - scroller.AbsoluteWindowSize.Y - 24
end
local function jumpToBottom()
	jumping = true
	scroller.CanvasPosition = Vector2.new(0, math.max(0, scroller.AbsoluteCanvasSize.Y - scroller.AbsoluteWindowSize.Y))
	jumping = false
	follow = true
end
track(scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	if not jumping then
		follow = atBottom()
	end
end))
track(scroller:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
	if follow and Settings.get("autoScroll") then
		jumpToBottom()
	end
end))

local function addRow(entry)
	order += 1
	local row = Instance.new("TextButton")
	row.Name = "Line"
	row:SetAttribute("NoFx", true) -- hundreds of lines: a plain hover is enough
	row.AutoButtonColor = false
	row.Text = ""
	row.BackgroundColor3 = WHITE
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.LayoutOrder = order
	row.Visible = matches(entry)
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
	local rowPad = Instance.new("UIPadding", row)
	rowPad.PaddingLeft, rowPad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	rowPad.PaddingTop, rowPad.PaddingBottom = UDim.new(0, 3), UDim.new(0, 3)

	local time = Instance.new("TextLabel")
	time.Name = "Time"
	time.BackgroundTransparency = 1
	time.Size = UDim2.fromOffset(GUTTER - 8, 0)
	time.AutomaticSize = Enum.AutomaticSize.Y
	time.FontFace = TIME_FONT
	time.TextColor3 = WHITE
	time.TextTransparency = 0.75
	time.TextXAlignment = Enum.TextXAlignment.Left
	time.TextYAlignment = Enum.TextYAlignment.Top
	time.Text = os.date("%H:%M:%S", entry.time)
	time.Parent = row

	local style = STYLE[entry.kind] or STYLE.print
	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.BackgroundTransparency = 1
	message.Position = UDim2.fromOffset(GUTTER, 0)
	message.Size = UDim2.new(1, -GUTTER, 0, 0)
	message.AutomaticSize = Enum.AutomaticSize.Y
	message.FontFace = TEXT_FONT
	message.TextColor3 = style[1]
	message.TextTransparency = style[2]
	message.TextWrapped = true
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Top
	message.Text = entry.text
	message.Parent = row
	sizeRow(row)

	row.MouseEnter:Connect(function()
		ButtonFx.tween(row, ButtonFx.FAST, {BackgroundTransparency = 0.975})
	end)
	row.MouseLeave:Connect(function()
		ButtonFx.tween(row, ButtonFx.FAST, {BackgroundTransparency = 1})
	end)
	row.Activated:Connect(function()
		if setClipboard then
			setClipboard(entry.text)
			notify("Copied that line")
		end
	end)
	row.Parent = scroller
	rows[entry] = row
end

local function refreshStatus()
	local total, shown = #OutputLog.entries(), 0
	for _, row in rows do
		if row.Visible then
			shown += 1
		end
	end
	local filter = FILTERS[filterIndex]
	if filter.name == "All" then
		status.Text = total == 1 and "1 line" or total .. " lines"
	else
		status.Text = filter.name .. ": " .. shown .. " of " .. total
	end
	empty.Visible = shown == 0
	empty.Text = total == 0 and EMPTY or "Nothing matches the " .. filter.name:lower() .. " filter."
end

local statusQueued = false
local function queueStatus()
	if not statusQueued then
		statusQueued = true
		task.defer(function()
			statusQueued = false
			refreshStatus()
		end)
	end
end

for _, entry in OutputLog.entries() do
	addRow(entry)
end
refreshStatus()

track(OutputLog.changed:Connect(function(action, entry)
	if action == "add" then
		addRow(entry)
	elseif action == "remove" then
		local row = rows[entry]
		if row then
			row:Destroy()
			rows[entry] = nil
		end
	else
		for _, row in rows do
			row:Destroy()
		end
		table.clear(rows)
	end
	queueStatus()
end))

track(Settings.changed:Connect(function(key)
	if key == nil or key == "outputTextSize" then
		for _, row in rows do
			sizeRow(row)
		end
	end
	if (key == nil or key == "autoScroll") and Settings.get("autoScroll") then
		task.defer(jumpToBottom)
	end
end))

-- opening the page shows the newest lines
track(page:GetPropertyChangedSignal("Visible"):Connect(function()
	if page.Visible and Settings.get("autoScroll") then
		task.defer(jumpToBottom)
	end
end))

local function shownText()
	local filter = FILTERS[filterIndex]
	return OutputLog.text(filter.name ~= "All" and filter or nil)
end

local ACTIONS = {
	Clear = function()
		OutputLog.clear()
		notify("Output cleared")
	end,
	Copy = function()
		if not setClipboard then
			notify("No clipboard here", true)
			return
		end
		local text, count = shownText()
		if count == 0 then
			notify("Nothing to copy", true)
			return
		end
		setClipboard(text)
		notify("Copied " .. count .. (count == 1 and " line" or " lines"))
	end,
	Save = function()
		if type(writefile) ~= "function" then
			notify("Saving needs an executor with file access", true)
			return
		end
		local text, count = shownText()
		if count == 0 then
			notify("Nothing to save", true)
			return
		end
		local path = "output-" .. os.date("%Y%m%d-%H%M%S") .. ".txt"
		local ok, err = pcall(function()
			if type(isfolder) == "function" and type(makefolder) == "function" then
				if not isfolder("logs") then
					makefolder("logs")
				end
				path = "logs/" .. path
			end
			writefile(path, text)
		end)
		notify(ok and "Saved to " .. path or "Couldn't save: " .. tostring(err), not ok)
	end,
}

for _, b in page.Toolbar2:GetChildren() do
	local label = b:IsA("TextButton") and b:FindFirstChild("TextLabel")
	if label and ACTIONS[label.Text] then
		b.Activated:Connect(ACTIONS[label.Text])
	elseif label and label.Text == "Filter" then
		b.Activated:Connect(function()
			filterIndex = filterIndex % #FILTERS + 1
			local filter = FILTERS[filterIndex]
			label.Text = filter.name
			for entry, row in rows do
				row.Visible = matches(entry)
			end
			refreshStatus()
			task.defer(jumpToBottom)
			notify(filter.name == "All" and "Showing everything" or "Showing " .. filter.name:lower() .. " only")
		end)
	end
end

Gui.Destroying:Once(function()
	for _, connection in connections do
		connection:Disconnect()
	end
end)

end

local TREE = {"ScreenGui","ScreenGui",{ZIndexBehavior=E("ZIndexBehavior","Sibling")},{
 {"Frame","Frame",{BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.0744525567,0,0.17715618,0),Size=U2(0,80,0,550),Visible=false,ZIndex=99},{
  {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
  {"UIListLayout","UIListLayout",{HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder")},false},
  {"Frame","IconHolder",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,100,0,100)},{
   {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://106640334752928",Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
  {"Frame","TabButton (Active)",{BackgroundColor3=C(28,28,28),BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=1,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
   {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
   {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
   {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48)},{
    {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
   {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
   {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
   {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
     {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
     {"UICorner","UICorner",false,false}}},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709807111",Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false}}},
  {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,12)},false},
  {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=1,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
   {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
   {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
   {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.349999994},{
    {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
   {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
   {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723407389",Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
   {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
     {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
     {"UICorner","UICorner",false,false}}},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
  {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=1,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
   {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
   {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
   {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.349999994},{
    {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
   {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
   {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709782154",Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
   {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0)},{
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="Library",TextColor3=C(255,255,255),TextSize=18},{
     {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
     {"UICorner","UICorner",false,false}}},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
  {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=1,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
   {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
   {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
   {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.349999994},{
    {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
   {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
   {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734950020",Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
   {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
     {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
     {"UICorner","UICorner",false,false}}},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}}}},
 {"Frame","main",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.476922482,0,0.450082213,0),Size=U2(0,800,0,502),ZIndex=2},{
  {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
  {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,12)},false},
  {"Frame","Topbar",{AnchorPoint=V2(1,0),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,0,0),Size=U2(1,-72,0,36)},{
   {"ScrollingFrame","Tabs",{Active=true,AutomaticCanvasSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,CanvasSize=U2(0,0,0,0),ScrollBarImageColor3=C(0,0,0),ScrollBarThickness=0,Size=U2(1,0,1,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false},
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder")},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Enabled=false,Transparency=0.5},{
     {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}},
   {"Frame","Frame",{AnchorPoint=V2(1,0),BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,0,0),Size=U2(0,100,1,0)},{
    {"UIGradient","UIGradient",{Transparency=NS({0,1,0},{0.5,0,0},{1,0,0})},false}}},
   {"TextButton","AddTabButton",{AnchorPoint=V2(1,0),AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Position=U2(1,0,0,0),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Enabled=false,Transparency=0.5},{
     {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"UIGradient","UIGradient",{Color=CS({0,0.450980395,0.286274523,1},{1,0.521568656,0.666666687,1}),Enabled=false,Rotation=65},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://109566486248794",ImageTransparency=0.5,LayoutOrder=-1,Position=U2(0.5,0,0.5,0),Rotation=45,Size=U2(0,12,0,12)},false},
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
    {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Enabled=false,Transparency=0.949999988},false},
    {"LocalScript","TabManager",false,false,false,false,1}}},
   {"ScrollingFrame","FakeTabs",{AutomaticCanvasSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,CanvasSize=U2(0,0,0,0),ScrollBarImageColor3=C(0,0,0),ScrollBarThickness=0,Size=U2(1,0,1,0),Visible=false},{
    {"TextButton","FakeTab",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),LayoutOrder=3,Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
     {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Enabled=false,Transparency=0.5},{
      {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"Frame","Content",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,0,1,0)},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
      {"ImageButton","ImageButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://109566486248794",ImageTransparency=0.850000024,LayoutOrder=2,Size=U2(0,12,0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734943448",ImageTransparency=0.850000024,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Size=U2(0,0,1,0),Text="a",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
    {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.949999988,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
     {"Frame","Accent",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=-9,Position=U2(0,0,0.5,0),Size=U2(0,4,0.5,0)},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false},
      {"UIShadow","UIShadow",{BlurRadius=U(0,15),Color=C(255,255,255),Transparency=0.949999988},false}}},
     {"Frame","Content",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,0,1,0)},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="@imdooted",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.5},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734943448",ImageTransparency=0.5,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"ImageButton","ImageButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://109566486248794",ImageTransparency=0.5,Size=U2(0,12,0,12)},false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false},
     {"UIGradient","UIGradient",{Color=CS({0,0.450980395,0.286274523,1},{1,0.521568656,0.666666687,1}),Enabled=false,Rotation=65},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.5},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}}}}}},
  {"Frame","SideBar",{BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,64,1,0),ZIndex=99},{
   {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
   {"UIPadding","UIPadding",{PaddingBottom=U(0,6),PaddingLeft=U(0,6),PaddingRight=U(0,6),PaddingTop=U(0,6)},false},
   {"Frame","Content",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,1,0)},{
    {"Frame","IconHolder",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,100,0,100)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://106640334752928",Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=1,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723407389",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709811365",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton (Active)",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.949999988,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=2,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6)},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48)},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Enabled=false,Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709807111",Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Transparency=0.949999988},false}}},
    {"Frame","TabButton (Active)",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.949999988,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=3,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6)},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48)},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Enabled=false,Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709782154",Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Transparency=0.949999988},false}}},
    {"UIListLayout","UIListLayout",{HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder")},false},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709806740",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734950020",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747373176",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}}}},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://127840699991988",Position=U2(1,0,1,0),Size=U2(1,0,1,0),Visible=false},{
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
    {"UIShadow","UIShadow",{BlurRadius=U(0,25),Color=C(255,255,255),Transparency=0.949999988},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
     {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}}}},
  {"Frame","AltToolbar",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,48,0,48),Visible=false},{
   {"UICorner","UICorner",false,false},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734923549",ImageTransparency=0.75,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false}}},
  {"Frame","Toolbar2",{AnchorPoint=V2(1,1),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,0,0,32)},{
   {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false},
   {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Enabled=false,Transparency=0.75},{
    {"UIGradient","UIGradient",{Rotation=-94,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Run",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.5},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734934585",ImageTransparency=0.5,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UIShadow","UIShadow",{BlurRadius=U(0,25),Color=C(255,255,255),Spread=U2(0,25,0,-25),Transparency=0.850000024},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,4),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
   {"UIPadding","UIPadding",{PaddingLeft=U(0,6),PaddingRight=U(0,6)},false},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Clear",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747362241",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Copy",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709799288",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Paste",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709799288",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Save",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723387563",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"UIScale","UIScale",{Scale=1.60000002},false}}},
  {"UIShadow","UIShadow",{BlurRadius=U(0,15),Transparency=0.75},false},
  {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://113988401397964",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(1,24,1,24),Visible=false},false},
  {"ScrollingFrame","ScrollingFrame",{Active=true,AnchorPoint=V2(1,1),AutomaticCanvasSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,CanvasSize=U2(0,0,0,0),HorizontalScrollBarInset=E("ScrollBarInset","ScrollBar"),Position=U2(1,0,0.872384965,0),ScrollBarImageTransparency=0.699999988,ScrollBarThickness=8,Size=U2(1,-72,0.872384965,-48),VerticalScrollBarInset=E("ScrollBarInset","Always"),ZIndex=4},{
   {"TextBox","TextBox",{AnchorPoint=V2(1,0),AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,ClearTextOnFocus=false,ClipsDescendants=true,FontFace=F("rbxasset://fonts/families/Inconsolata.json","Regular","Normal"),MultiLine=true,Position=U2(1,9,2.48110382e-07,0),Size=U2(0.970000029,0,1,0),Text="dsad",TextColor3=C(255,255,255),TextSize=16,TextXAlignment=E("TextXAlignment","Left"),TextYAlignment=E("TextYAlignment","Top")},false},
   {"TextBox","Line",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,ClearTextOnFocus=false,ClipsDescendants=true,FontFace=F("rbxasset://fonts/families/Inconsolata.json","Regular","Normal"),MultiLine=true,Size=U2(0.0299999993,0,1,0),Text="1",TextColor3=C(255,255,255),TextEditable=false,TextSize=16,TextTransparency=0.5,TextXAlignment=E("TextXAlignment","Left"),TextYAlignment=E("TextYAlignment","Top")},false},
   {"LocalScript","LocalScript",false,false,false,false,2},
   {"ModuleScript","LuaHighlighter",false,false,false,false,3}}}}},
 {"UIScale","UIScale",false,false},
 {"Frame","library",{BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.791687846,0,0.205145732,0),Size=U2(0,240,0,502),Visible=false},{
  {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
  {"UIShadow","UIShadow",{BlurRadius=U(0,15),Transparency=0.75},false},
  {"ScrollingFrame","ScrollingFrame",{Active=true,BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,CanvasSize=U2(0,0,0,0),ScrollBarImageColor3=C(0,0,0),ScrollBarThickness=0,Size=U2(1,0,1,0)},{
   {"Frame","Frame",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,0)},{
    {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder")},false},
    {"Frame","Frame",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,0)},{
     {"UIListLayout","UIListLayout",{Padding=U(0,4),SortOrder=E("SortOrder","LayoutOrder")},false},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,0,32),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"Frame","Content",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,1,0)},{
       {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
       {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,-2,1,0),Text="@imdooted",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.5,TextXAlignment=E("TextXAlignment","Left")},false},
       {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734943448",ImageTransparency=0.5,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},{
        {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
       {"ImageButton","ImageButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://109566486248794",ImageTransparency=0.5,Size=U2(0,12,0,12),Visible=false},{
        {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
       {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
       {"UICorner","UICorner",false,false},
       {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.75},{
        {"UIGradient","UIGradient",{Rotation=-98,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}},
      {"Frame","Accent",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=-9,Position=U2(0,0,0.5,0),Size=U2(0,4,0.5,0)},{
       {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false},
       {"UIShadow","UIShadow",{BlurRadius=U(0,15),Color=C(255,255,255),Transparency=0.949999988},false}}}}},
     {"TextButton","TextButton",{AutoButtonColor=false,BackgroundColor3=C(255,107,109),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,0,32),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"Frame","Content",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.150000006,0,0,0),Size=U2(1,0,1,0)},{
       {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
       {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,-2,1,0),Text="doomdtw",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024,TextXAlignment=E("TextXAlignment","Left")},false},
       {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734943448",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},{
        {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
       {"ImageButton","ImageButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://109566486248794",ImageTransparency=0.850000024,Size=U2(0,12,0,12),Visible=false},{
        {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
       {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
       {"UICorner","UICorner",false,false},
       {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Enabled=false,Transparency=0.75},{
        {"UIGradient","UIGradient",{Rotation=-98,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}},
      {"Frame","Accent",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=-9,Position=U2(0,0,0.5,0),Size=U2(0,4,0.5,0),Visible=false},{
       {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false},
       {"UIShadow","UIShadow",{BlurRadius=U(0,15),Color=C(255,255,255),Transparency=0.949999988},false}}},
      {"UICorner","UICorner",false,false},
      {"ImageLabel","ImageLabel",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747362241",ImageColor3=C(13,14,17),Position=U2(0.0526315793,0,0.25,0),Size=U2(0,16,0,16)},{
       {"UIShadow","UIShadow",{BlurRadius=U(0,25),Color=C(255,107,109)},false}}}}},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,0,32),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"Frame","Content",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,1,0)},{
       {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
       {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,-2,1,0),Text="filler.lua",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024,TextXAlignment=E("TextXAlignment","Left")},false},
       {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734943448",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},{
        {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
       {"ImageButton","ImageButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://109566486248794",ImageTransparency=0.850000024,Size=U2(0,12,0,12),Visible=false},{
        {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
       {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
       {"UICorner","UICorner",false,false},
       {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Enabled=false,Transparency=0.75},{
        {"UIGradient","UIGradient",{Rotation=-98,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}},
      {"Frame","Accent",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=-9,Position=U2(0,0,0.5,0),Size=U2(0,4,0.5,0),Visible=false},{
       {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false},
       {"UIShadow","UIShadow",{BlurRadius=U(0,15),Color=C(255,255,255),Transparency=0.949999988},false}}}}},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,0,32),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"Frame","Content",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,1,0)},{
       {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
       {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,-2,1,0),Text="filler.lua",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024,TextXAlignment=E("TextXAlignment","Left")},false},
       {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734943448",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},{
        {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
       {"ImageButton","ImageButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://109566486248794",ImageTransparency=0.850000024,Size=U2(0,12,0,12),Visible=false},{
        {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
       {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
       {"UICorner","UICorner",false,false},
       {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Enabled=false,Transparency=0.75},{
        {"UIGradient","UIGradient",{Rotation=-98,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}},
      {"Frame","Accent",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=-9,Position=U2(0,0,0.5,0),Size=U2(0,4,0.5,0),Visible=false},{
       {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false},
       {"UIShadow","UIShadow",{BlurRadius=U(0,15),Color=C(255,255,255),Transparency=0.949999988},false}}}}}}},
    {"Frame","Topbar",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=-999,Size=U2(1,0,0,24)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"ImageButton","ImageButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709791523",LayoutOrder=1,Size=U2(0,16,0,16)},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Bold","Normal"),LayoutOrder=-1,Size=U2(1,0,1,0),Text="ONLINE",TextColor3=C(255,255,255),TextSize=12,TextXAlignment=E("TextXAlignment","Left")},false}}}}},
   {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder")},false},
   {"TextButton","TextButton",{AnchorPoint=V2(0,1),AutoButtonColor=false,BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),LayoutOrder=-999,Position=U2(0,0,0.995934963,-6),Size=U2(1,0,0.00845510606,32),Text="",TextColor3=C(0,0,0),TextSize=14,ZIndex=3},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734943674",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,-2,1,0),Text="Search...",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024,TextXAlignment=E("TextXAlignment","Left")},false},
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,12)},false}}},
   {"Frame","Frame",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=-999,Size=U2(1,0,0,0)},{
    {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder")},false},
    {"Frame","Frame",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,0)},{
     {"UIListLayout","UIListLayout",{Padding=U(0,4),SortOrder=E("SortOrder","LayoutOrder")},false},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),LayoutOrder=-2,Size=U2(1,0,0,32),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"Frame","Content",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,1,0)},{
       {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
       {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,-2,1,0),Text="filler.lua",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024,TextXAlignment=E("TextXAlignment","Left")},false},
       {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734966248",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},{
        {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
       {"ImageButton","ImageButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://109566486248794",ImageTransparency=0.850000024,Size=U2(0,12,0,12),Visible=false},{
        {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
       {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
       {"UICorner","UICorner",false,false},
       {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Enabled=false,Transparency=0.75},{
        {"UIGradient","UIGradient",{Rotation=-98,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}},
      {"Frame","Accent",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=-9,Position=U2(0,0,0.5,0),Size=U2(0,4,0.5,0),Visible=false},{
       {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false},
       {"UIShadow","UIShadow",{BlurRadius=U(0,15),Color=C(255,255,255),Transparency=0.949999988},false}}}}}}},
    {"Frame","Topbar",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=-999,Size=U2(1,0,0,24)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"ImageButton","ImageButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709791523",LayoutOrder=1,Size=U2(0,16,0,16)},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Bold","Normal"),LayoutOrder=-1,Size=U2(1,0,1,0),Text="FAVORITES",TextColor3=C(255,255,255),TextSize=12,TextXAlignment=E("TextXAlignment","Left")},false}}}}}}},
  {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,12)},false},
  {"TextButton","TextButton",{AnchorPoint=V2(0,1),AutoButtonColor=false,BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Position=U2(0,0,0.995934963,-6),Size=U2(1,0,0.00845510606,32),Text="",TextColor3=C(0,0,0),TextSize=14,ZIndex=3},{
   {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723404337",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},{
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
   {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,-2,1,0),Text="Find More...",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024,TextXAlignment=E("TextXAlignment","Left")},false},
   {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
   {"UIPadding","UIPadding",{PaddingLeft=U(0,12)},false}}},
  {"Frame","Frame",{AnchorPoint=V2(1,1),BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(1,0,0,120)},{
   {"UIGradient","UIGradient",{Rotation=90,Transparency=NS({0,1,0},{0.5,0,0},{1,0,0})},false}}},
  {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://113988401397964",ImageTransparency=0.949999988,Position=U2(-1.01620376,0,1,6),Size=U2(4.03240728,24,1,12),Visible=false},false}}},
 {"Frame","scriptstroe",{BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.13721773,0,0.113053612,0),Size=U2(0,800,0,502),Visible=false},{
  {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
  {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,12)},false},
  {"ScrollingFrame","ScrollingFrame",{Active=true,AnchorPoint=V2(1,1),AutomaticCanvasSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,CanvasSize=U2(0,0,0,0),Position=U2(1,0,1,0),ScrollBarImageColor3=C(0,0,0),ScrollBarThickness=0,Size=U2(1,-72,1,0),ZIndex=2},{
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0.514609873,0,0.420168072,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-120,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(13,14,17),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723415040",ImageTransparency=0.985000014,Position=U2(0.5,0,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(1,-2,1,-2)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(0,14),BottomRightRadius=U(0,14),TopLeftRadius=U(0,14),TopRightRadius=U(0,14)},false}}},
    {"Frame","Frame",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,0.5,0),Size=U2(1,-2,1,-2)},{
     {"UIGradient","UIGradient",{Rotation=90,Transparency=NS({0,1,0},{0.300335586,1,0},{0.399328858,1,0},{0.699664414,0,0},{1,0,0})},false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false}}},
    {"Frame","TextContainer",{AnchorPoint=V2(0,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0,0,1,0),Size=U2(0,100,0,100)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="0 Views",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="Script Name",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.5,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,16)},false}}},
    {"Frame","ButtonContainer",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,100,0,48)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalAlignment=E("HorizontalAlignment","Right"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingRight=U(0,16)},false},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Run",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734934585",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"UICorner","UICorner",false,false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false}}},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Save",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709782154",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
      {"UICorner","UICorner",false,false}}}}}}},
   {"UIGridLayout","UIGridLayout",{CellPadding=U2(0,12,0,12),CellSize=U2(0.5,-6,0,200),SortOrder=E("SortOrder","LayoutOrder")},false},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0.514609873,0,0.420168072,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-120,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(13,14,17),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723415040",ImageTransparency=0.985000014,Position=U2(0.5,0,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(1,-2,1,-2)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(0,14),BottomRightRadius=U(0,14),TopLeftRadius=U(0,14),TopRightRadius=U(0,14)},false}}},
    {"Frame","Frame",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,0.5,0),Size=U2(1,-2,1,-2)},{
     {"UIGradient","UIGradient",{Rotation=90,Transparency=NS({0,1,0},{0.300335586,1,0},{0.399328858,1,0},{0.699664414,0,0},{1,0,0})},false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false}}},
    {"Frame","TextContainer",{AnchorPoint=V2(0,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0,0,1,0),Size=U2(0,100,0,100)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="0 Views",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="Script Name",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.5,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,16)},false}}},
    {"Frame","ButtonContainer",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,100,0,48)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalAlignment=E("HorizontalAlignment","Right"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingRight=U(0,16)},false},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Run",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734934585",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"UICorner","UICorner",false,false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false}}},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Save",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709782154",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
      {"UICorner","UICorner",false,false}}}}}}},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0.514609873,0,0.420168072,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-120,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(13,14,17),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723415040",ImageTransparency=0.985000014,Position=U2(0.5,0,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(1,-2,1,-2)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(0,14),BottomRightRadius=U(0,14),TopLeftRadius=U(0,14),TopRightRadius=U(0,14)},false}}},
    {"Frame","Frame",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,0.5,0),Size=U2(1,-2,1,-2)},{
     {"UIGradient","UIGradient",{Rotation=90,Transparency=NS({0,1,0},{0.300335586,1,0},{0.399328858,1,0},{0.699664414,0,0},{1,0,0})},false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false}}},
    {"Frame","TextContainer",{AnchorPoint=V2(0,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0,0,1,0),Size=U2(0,100,0,100)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="0 Views",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="Script Name",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.5,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,16)},false}}},
    {"Frame","ButtonContainer",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,100,0,48)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalAlignment=E("HorizontalAlignment","Right"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingRight=U(0,16)},false},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Run",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734934585",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"UICorner","UICorner",false,false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false}}},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Save",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709782154",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
      {"UICorner","UICorner",false,false}}}}}}},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0.514609873,0,0.420168072,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-120,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(13,14,17),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723415040",ImageTransparency=0.985000014,Position=U2(0.5,0,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(1,-2,1,-2)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(0,14),BottomRightRadius=U(0,14),TopLeftRadius=U(0,14),TopRightRadius=U(0,14)},false}}},
    {"Frame","Frame",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,0.5,0),Size=U2(1,-2,1,-2)},{
     {"UIGradient","UIGradient",{Rotation=90,Transparency=NS({0,1,0},{0.300335586,1,0},{0.399328858,1,0},{0.699664414,0,0},{1,0,0})},false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false}}},
    {"Frame","TextContainer",{AnchorPoint=V2(0,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0,0,1,0),Size=U2(0,100,0,100)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="0 Views",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="Script Name",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.5,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,16)},false}}},
    {"Frame","ButtonContainer",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,100,0,48)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalAlignment=E("HorizontalAlignment","Right"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingRight=U(0,16)},false},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Run",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734934585",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"UICorner","UICorner",false,false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false}}},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Save",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709782154",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
      {"UICorner","UICorner",false,false}}}}}}},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0.514609873,0,0.420168072,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-120,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(13,14,17),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723415040",ImageTransparency=0.985000014,Position=U2(0.5,0,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(1,-2,1,-2)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(0,14),BottomRightRadius=U(0,14),TopLeftRadius=U(0,14),TopRightRadius=U(0,14)},false}}},
    {"Frame","Frame",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,0.5,0),Size=U2(1,-2,1,-2)},{
     {"UIGradient","UIGradient",{Rotation=90,Transparency=NS({0,1,0},{0.300335586,1,0},{0.399328858,1,0},{0.699664414,0,0},{1,0,0})},false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false}}},
    {"Frame","TextContainer",{AnchorPoint=V2(0,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0,0,1,0),Size=U2(0,100,0,100)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="0 Views",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="Script Name",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.5,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,16)},false}}},
    {"Frame","ButtonContainer",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,100,0,48)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalAlignment=E("HorizontalAlignment","Right"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingRight=U(0,16)},false},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Run",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734934585",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"UICorner","UICorner",false,false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false}}},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Save",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709782154",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
      {"UICorner","UICorner",false,false}}}}}}},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0.514609873,0,0.420168072,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-120,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(13,14,17),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723415040",ImageTransparency=0.985000014,Position=U2(0.5,0,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(1,-2,1,-2)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(0,14),BottomRightRadius=U(0,14),TopLeftRadius=U(0,14),TopRightRadius=U(0,14)},false}}},
    {"Frame","Frame",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,0.5,0),Size=U2(1,-2,1,-2)},{
     {"UIGradient","UIGradient",{Rotation=90,Transparency=NS({0,1,0},{0.300335586,1,0},{0.399328858,1,0},{0.699664414,0,0},{1,0,0})},false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false}}},
    {"Frame","TextContainer",{AnchorPoint=V2(0,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0,0,1,0),Size=U2(0,100,0,100)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="0 Views",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="Script Name",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.5,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,16)},false}}},
    {"Frame","ButtonContainer",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,100,0,48)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalAlignment=E("HorizontalAlignment","Right"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingRight=U(0,16)},false},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Run",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734934585",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"UICorner","UICorner",false,false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false}}},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Save",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709782154",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
      {"UIPadding","UIPadding",{PaddingLeft=U(0,12),PaddingRight=U(0,12)},false},
      {"UICorner","UICorner",false,false}}}}}}}}},
  {"Frame","AltToolbar",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,48,0,48),Visible=false},{
   {"UICorner","UICorner",false,false},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734923549",ImageTransparency=0.75,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false}}},
  {"UIShadow","UIShadow",{BlurRadius=U(0,15),Transparency=0.75},false},
  {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://113988401397964",ImageTransparency=0.75,Position=U2(0.5,0,0.5,0),Size=U2(1,24,1,24),Visible=false},false},
  {"Frame","SideBar",{BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,64,1,0),ZIndex=99},{
   {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
   {"UIPadding","UIPadding",{PaddingBottom=U(0,6),PaddingLeft=U(0,6),PaddingRight=U(0,6),PaddingTop=U(0,6)},false},
   {"Frame","Content",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,1,0)},{
    {"Frame","IconHolder",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,100,0,100)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://106640334752928",Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=1,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723407389",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709811365",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton (Active)",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=2,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Enabled=false,Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709807111",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Enabled=false,Transparency=0.949999988},false}}},
    {"Frame","TabButton (Active)",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=3,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Enabled=false,Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709782154",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Enabled=false,Transparency=0.949999988},false}}},
    {"UIListLayout","UIListLayout",{HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder")},false},
    {"Frame","TabButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.949999988,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Enabled=false,Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709806740",Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Transparency=0.949999988},false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6)},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734950020",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747373176",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}}}},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://127840699991988",Position=U2(1,0,1,0),Size=U2(1,0,1,0),Visible=false},{
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
    {"UIShadow","UIShadow",{BlurRadius=U(0,25),Color=C(255,255,255),Transparency=0.949999988},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
     {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}}}}}},
 {"Frame","output",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,0.5,0),Size=U2(0,800,0,502),Visible=false},{
  {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
  {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,12)},false},
  {"Frame","AltToolbar",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,0.943025231,0),Size=U2(0,48,0,20),Visible=false},{
   {"UICorner","UICorner",false,false},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734923549",ImageTransparency=0.75,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false}}},
  {"UIShadow","UIShadow",{BlurRadius=U(0,15),Transparency=0.75},false},
  {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://113988401397964",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(1,24,1,24),Visible=false},false},
  {"ScrollingFrame","ScrollingFrame",{Active=true,AnchorPoint=V2(1,1),AutomaticCanvasSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,CanvasSize=U2(0,0,0,0),Position=U2(1,0,1,0),ScrollBarImageColor3=C(0,0,0),ScrollBarThickness=0,Size=U2(1,-72,1,0)},{
   {"TextBox","TextBox",{AnchorPoint=V2(1,0),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,ClearTextOnFocus=false,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Medium","Normal"),Position=U2(1,0,0,0),RichText=true,Size=U2(1,-64,1,0),Text="<font color=\"#ffffff\">-- doomdtw</font>\
<font color=\"#ff738d\">-- error</font>\
<font color=\"#e2afff\">-- test service</font>\
<font color=\"#ffb68b\">-- warning</font>",TextColor3=C(255,255,255),TextEditable=false,TextSize=24,TextStrokeColor3=C(255,255,255),TextXAlignment=E("TextXAlignment","Left"),TextYAlignment=E("TextYAlignment","Top")},false},
   {"Frame","Gutter",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,64,1,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,4),BottomRightRadius=U(0,4),TopLeftRadius=U(0,4),TopRightRadius=U(0,4)},false},
    {"TextLabel","TextLabel",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://11702779409","Medium","Normal"),Position=U2(0,0,3.20562812e-08,0),Size=U2(0,15,0.0189999994,15),Text="10:42:10",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
    {"TextLabel","TextLabel",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://11702779409","Medium","Normal"),Position=U2(0,0,0.0554634556,0),Size=U2(0,15,0.0189999994,15),Text="10:42:15",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
    {"TextLabel","TextLabel",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://11702779409","Medium","Normal"),Position=U2(0,0,0.110926911,0),Size=U2(0,15,0.0189999994,15),Text="10:42:18",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},{
     {"Frame","Frame",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,689,0,22)},{
      {"UICorner","UICorner",{BottomLeftRadius=U(0,3),BottomRightRadius=U(0,3),TopLeftRadius=U(0,3),TopRightRadius=U(0,3)},false}}}}},
    {"UIListLayout","UIListLayout",{Padding=U(0,1),SortOrder=E("SortOrder","LayoutOrder")},false},
    {"TextLabel","TextLabel",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://11702779409","Medium","Normal"),Position=U2(0,0,0.1663903,0),Size=U2(0,15,0.0189999994,15),Text="10:42:21",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false}}},
   {"UIScale","UIScale",false,false}}},
  {"Frame","Toolbar2",{AnchorPoint=V2(1,1),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,0,0,32)},{
   {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false},
   {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Enabled=false,Transparency=0.75},{
    {"UIGradient","UIGradient",{Rotation=-94,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
   {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,4),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
   {"UIPadding","UIPadding",{PaddingLeft=U(0,6),PaddingRight=U(0,6)},false},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalAlignment=E("HorizontalAlignment","Center"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Clear",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024,Visible=false},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747362241",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalAlignment=E("HorizontalAlignment","Center"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Copy",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024,Visible=false},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709812159",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalAlignment=E("HorizontalAlignment","Center"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Save",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024,Visible=false},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734941499",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalAlignment=E("HorizontalAlignment","Center"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Filter",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024,Visible=false},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723375128",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"UIScale","UIScale",{Scale=1.60000002},false}}},
  {"Frame","SideBar",{BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,64,1,0),ZIndex=99},{
   {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
   {"UIPadding","UIPadding",{PaddingBottom=U(0,6),PaddingLeft=U(0,6),PaddingRight=U(0,6),PaddingTop=U(0,6)},false},
   {"Frame","Content",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,1,0)},{
    {"Frame","IconHolder",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,100,0,100)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://106640334752928",Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=1,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723407389",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.949999988,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Enabled=false,Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709811365",Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Transparency=0.949999988},false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6)},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}}}},
    {"Frame","TabButton (Active)",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=2,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Enabled=false,Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709807111",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Enabled=false,Transparency=0.949999988},false}}},
    {"Frame","TabButton (Active)",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=3,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709782154",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false}}},
    {"UIListLayout","UIListLayout",{HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder")},false},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709806740",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734950020",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747373176",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}}}},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://127840699991988",Position=U2(1,0,1,0),Size=U2(1,0,1,0),Visible=false},{
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
    {"UIShadow","UIShadow",{BlurRadius=U(0,25),Color=C(255,255,255),Transparency=0.949999988},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
     {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}}}}}},
 {"Frame","settings",{BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.13721773,0,0.113053612,0),Size=U2(0,800,0,502),Visible=false},{
  {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
  {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,12)},false},
  {"Frame","AltToolbar",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,0.943025231,0),Size=U2(0,48,0,20),Visible=false},{
   {"UICorner","UICorner",false,false},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734923549",ImageTransparency=0.75,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false}}},
  {"UIShadow","UIShadow",{BlurRadius=U(0,15),Transparency=0.75},false},
  {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://113988401397964",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(1,24,1,24)},false},
  {"ScrollingFrame","ScrollingFrame",{Active=true,AnchorPoint=V2(1,1),AutomaticCanvasSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,CanvasSize=U2(0,0,0,0),Position=U2(1,0,1,0),ScrollBarImageColor3=C(0,0,0),ScrollBarThickness=0,Size=U2(1,-72,1,-48)},{
   {"UIScale","UIScale",false,false},
   {"UIListLayout","UIListLayout",{Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder")},false},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,64)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-94,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"Frame","TextContainer",{AnchorPoint=V2(0,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0,0,1,0),Size=U2(0,100,1,0)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="this is where a description would go uhhhh yea",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="setting name",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"Frame","ButtonContainer",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,100,1,0)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalAlignment=E("HorizontalAlignment","Right"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,12)},false},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIPadding","UIPadding",{PaddingBottom=U(0,6),PaddingLeft=U(0,6),PaddingRight=U(0,6),PaddingTop=U(0,6)},false},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"Frame","In",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.949999988,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,1,0)},{
       {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
       {"UICorner","UICorner",false,false}}}}}}}}},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,64)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-94,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"Frame","TextContainer",{AnchorPoint=V2(0,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0,0,1,0),Size=U2(0,100,1,0)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="this is where a description would go uhhhh yea",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="setting name",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"Frame","ButtonContainer",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,100,1,0)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalAlignment=E("HorizontalAlignment","Right"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Bottom")},false},
     {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,12)},false},
     {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.100000001,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIPadding","UIPadding",{PaddingBottom=U(0,6),PaddingLeft=U(0,6),PaddingRight=U(0,6),PaddingTop=U(0,6)},false},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"Frame","In",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(1,0,1,0)},{
       {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
       {"UICorner","UICorner",false,false}}},
      {"UIGradient","UIGradient",{Color=CS({0,0.615686297,0.847058892,1},{1,0.68235296,0.419607848,1}),Rotation=65},false}}}}}}},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,82)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-96,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,100,0,64)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="this is where a description would go uhhhh yea",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="setting name",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"Frame","Slider",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,0),Size=U2(1,-32,0,8)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false},
     {"Frame","FillWrap",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,ClipsDescendants=true,Size=U2(0.5,0,1,0)},{
      {"Frame","Frame",{BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,672,0,8)},{
       {"UIGradient","UIGradient",{Color=CS({0,0.615686297,0.847058892,1},{1,0.68235296,0.419607848,1})},false},
       {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}}}},
     {"Frame","Marker",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,0.5,0),Size=U2(1.5,0,1.5,0)},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false},
      {"UIShadow","UIShadow",{BlurRadius=U(0,15),Color=C(16,17,21),Spread=U2(0,25,0,0)},false}}}}},
    {"UIPadding","UIPadding",{PaddingBottom=U(0,16)},false},
    {"Frame","TextContainer",{AnchorPoint=V2(1,0),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,0,0),Size=U2(0,100,0,64)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="this is where a description would go uhhhh yea",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Right"),Visible=false},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="50%",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Right")},false},
     {"UIListLayout","UIListLayout",{HorizontalAlignment=E("HorizontalAlignment","Right"),SortOrder=E("SortOrder","LayoutOrder")},false},
     {"UIPadding","UIPadding",{PaddingRight=U(0,16),PaddingTop=U(0,16)},false}}}}},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,82)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-96,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,100,0,64)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="this is where a description would go uhhhh yea",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="setting name",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"Frame","Slider",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,0),Size=U2(1,-32,0,8)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false},
     {"Frame","FillWrap",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,ClipsDescendants=true,Size=U2(0.670000017,0,1,0)},{
      {"Frame","Frame",{BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,672,0,8)},{
       {"UIGradient","UIGradient",{Color=CS({0,0.615686297,0.847058892,1},{1,0.68235296,0.419607848,1})},false},
       {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}}}},
     {"Frame","Marker",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.670000017,0,0.5,0),Size=U2(1.5,0,1.5,0)},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false},
      {"UIShadow","UIShadow",{BlurRadius=U(0,15),Color=C(16,17,21),Spread=U2(0,25,0,0)},false}}}}},
    {"UIPadding","UIPadding",{PaddingBottom=U(0,16)},false},
    {"Frame","TextContainer",{AnchorPoint=V2(1,0),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,0,0),Size=U2(0,100,0,64)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="this is where a description would go uhhhh yea",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Right"),Visible=false},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="67%",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Right")},false},
     {"UIListLayout","UIListLayout",{HorizontalAlignment=E("HorizontalAlignment","Right"),SortOrder=E("SortOrder","LayoutOrder")},false},
     {"UIPadding","UIPadding",{PaddingRight=U(0,16),PaddingTop=U(0,16)},false}}}}},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,82)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-96,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,100,0,64)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="this is where a description would go uhhhh yea",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="setting name",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"Frame","Slider",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,0),Size=U2(1,-32,0,8)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false},
     {"Frame","FillWrap",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,ClipsDescendants=true,Size=U2(0.5,0,1,0)},{
      {"Frame","Frame",{BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,672,0,8)},{
       {"UIGradient","UIGradient",{Color=CS({0,0.615686297,0.847058892,1},{1,0.68235296,0.419607848,1})},false},
       {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}}}},
     {"Frame","Marker",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,0.5,0),Size=U2(1.5,0,1.5,0)},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false},
      {"UIShadow","UIShadow",{BlurRadius=U(0,15),Color=C(16,17,21),Spread=U2(0,25,0,0)},false}}}}},
    {"UIPadding","UIPadding",{PaddingBottom=U(0,16)},false},
    {"Frame","TextContainer",{AnchorPoint=V2(1,0),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,0,0),Size=U2(0,100,0,64)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Regular","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="this is where a description would go uhhhh yea",TextColor3=C(255,255,255),TextSize=12,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Right"),Visible=false},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="100%",TextColor3=C(255,255,255),TextSize=20,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Right")},false},
     {"UIListLayout","UIListLayout",{HorizontalAlignment=E("HorizontalAlignment","Right"),SortOrder=E("SortOrder","LayoutOrder")},false},
     {"UIPadding","UIPadding",{PaddingRight=U(0,16),PaddingTop=U(0,16)},false}}}}}}},
  {"Frame","Toolbar2",{AnchorPoint=V2(1,1),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,0,0,32),ZIndex=2},{
   {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false},
   {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Enabled=false,Transparency=0.75},{
    {"UIGradient","UIGradient",{Rotation=-94,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
   {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,4),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
   {"UIPadding","UIPadding",{PaddingLeft=U(0,6),PaddingRight=U(0,6)},false},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Reset",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747362241",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Import",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709799288",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"UIScale","UIScale",{Scale=1.60000002},false},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Export",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723387563",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Filter",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723375128",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"UIShadow","UIShadow",{BlurRadius=U(0,15),Transparency=0.5},false}}},
  {"TextButton","TextButton",{AnchorPoint=V2(1,0),AutoButtonColor=false,BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),LayoutOrder=-999,Position=U2(1,0,0,0),Size=U2(1,-72,0,36),Text="",TextColor3=C(0,0,0),TextSize=14,ZIndex=3},{
   {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734943674",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},{
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
   {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,-2,1,0),Text="Search...",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024,TextXAlignment=E("TextXAlignment","Left")},false},
   {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
   {"UIPadding","UIPadding",{PaddingLeft=U(0,12)},false}}},
  {"Frame","Frame",{AnchorPoint=V2(1,1),BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(1,-72,0,100)},{
   {"UIGradient","UIGradient",{Rotation=90,Transparency=NS({0,1,0},{0.503355682,0,0},{1,0,0})},false}}},
  {"Frame","SideBar",{BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,64,1,0),ZIndex=99},{
   {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
   {"UIPadding","UIPadding",{PaddingBottom=U(0,6),PaddingLeft=U(0,6),PaddingRight=U(0,6),PaddingTop=U(0,6)},false},
   {"Frame","Content",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,1,0)},{
    {"Frame","IconHolder",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,100,0,100)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://106640334752928",Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=1,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723407389",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709811365",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton (Active)",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=2,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Enabled=false,Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709807111",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Enabled=false,Transparency=0.949999988},false}}},
    {"Frame","TabButton (Active)",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=3,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.5},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709782154",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Enabled=false,Transparency=0.949999988},false}}},
    {"UIListLayout","UIListLayout",{HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder")},false},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709806740",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.949999988,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48)},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Enabled=false,Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734950020",Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Transparency=0.949999988},false}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747373176",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}}}},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://127840699991988",Position=U2(1,0,1,0),Size=U2(1,0,1,0),Visible=false},{
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
    {"UIShadow","UIShadow",{BlurRadius=U(0,25),Color=C(255,255,255),Transparency=0.949999988},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
     {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}}}}}},
 {"Frame","accountmanager",{BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.13721773,0,0.113053612,0),Size=U2(0,800,0,502),Visible=false},{
  {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
  {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,12)},false},
  {"Frame","AltToolbar",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,0.943025231,0),Size=U2(0,48,0,20),Visible=false},{
   {"UICorner","UICorner",false,false},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734923549",ImageTransparency=0.75,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false}}},
  {"UIShadow","UIShadow",{BlurRadius=U(0,15),Transparency=0.75},false},
  {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://113988401397964",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(1,24,1,24)},false},
  {"ScrollingFrame","ScrollingFrame",{Active=true,AnchorPoint=V2(1,1),AutomaticCanvasSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,CanvasSize=U2(0,0,0,0),Position=U2(1,0,1,0),ScrollBarImageColor3=C(0,0,0),ScrollBarThickness=0,Size=U2(1,-72,1,-48)},{
   {"UIScale","UIScale",false,false},
   {"UIListLayout","UIListLayout",{Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder")},false},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,100)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-94,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.112426035,0,0,0),Size=U2(0.10400892,100,1,0)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Medium","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="@doomdtw",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="doomdtw",TextColor3=C(255,255,255),TextSize=24,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,12),PaddingRight=U(0,16),PaddingTop=U(0,12)},false},
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://127840699991988",LayoutOrder=-1,Position=U2(1,0,1,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"UICorner","UICorner",false,false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,25),Color=C(255,255,255),Transparency=0.949999988},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}},
    {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.368801773,0,0,0),Size=U2(0.123293519,100,1,0)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Medium","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="R$100",TextColor3=C(16,255,136),TextSize=16,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="142376088",TextColor3=C(255,255,255),TextSize=24,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
    {"Frame","buttoncontainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.719901741,0,0,0),Size=U2(0.146962181,100,1,0)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,16),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734934585",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734933222",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747362393",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}}}}}},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,100)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-94,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.112426035,0,0,0),Size=U2(0.10400892,100,1,0)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Medium","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="@doomdtw",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="doomdtw",TextColor3=C(255,255,255),TextSize=24,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,12),PaddingRight=U(0,16),PaddingTop=U(0,12)},false},
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://127840699991988",LayoutOrder=-1,Position=U2(1,0,1,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"UICorner","UICorner",false,false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,25),Color=C(255,255,255),Transparency=0.949999988},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}},
    {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.368801773,0,0,0),Size=U2(0.123293519,100,1,0)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Medium","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="R$100",TextColor3=C(16,255,136),TextSize=16,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="142376088",TextColor3=C(255,255,255),TextSize=24,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
    {"Frame","buttoncontainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.719901741,0,0,0),Size=U2(0.146962181,100,1,0)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,16),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734934585",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734933222",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747362393",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}}}}}},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,100)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-94,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.112426035,0,0,0),Size=U2(0.10400892,100,1,0)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Medium","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="@doomdtw",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="doomdtw",TextColor3=C(255,255,255),TextSize=24,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,12),PaddingRight=U(0,16),PaddingTop=U(0,12)},false},
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://127840699991988",LayoutOrder=-1,Position=U2(1,0,1,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"UICorner","UICorner",false,false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,25),Color=C(255,255,255),Transparency=0.949999988},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}},
    {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.368801773,0,0,0),Size=U2(0.123293519,100,1,0)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Medium","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="R$100",TextColor3=C(16,255,136),TextSize=16,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="142376088",TextColor3=C(255,255,255),TextSize=24,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
    {"Frame","buttoncontainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.719901741,0,0,0),Size=U2(0.146962181,100,1,0)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,16),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734934585",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734933222",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747362393",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}}}}}},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,100)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-94,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.112426035,0,0,0),Size=U2(0.10400892,100,1,0)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Medium","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="@doomdtw",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="doomdtw",TextColor3=C(255,255,255),TextSize=24,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,12),PaddingRight=U(0,16),PaddingTop=U(0,12)},false},
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://127840699991988",LayoutOrder=-1,Position=U2(1,0,1,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"UICorner","UICorner",false,false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,25),Color=C(255,255,255),Transparency=0.949999988},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}},
    {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.368801773,0,0,0),Size=U2(0.123293519,100,1,0)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Medium","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="R$100",TextColor3=C(16,255,136),TextSize=16,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="142376088",TextColor3=C(255,255,255),TextSize=24,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
    {"Frame","buttoncontainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.719901741,0,0,0),Size=U2(0.146962181,100,1,0)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,16),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734934585",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734933222",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747362393",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}}}}}},
   {"Frame","Frame",{BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,0,100)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
     {"UIGradient","UIGradient",{Rotation=-94,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.112426035,0,0,0),Size=U2(0.10400892,100,1,0)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Medium","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="@doomdtw",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.75,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="doomdtw",TextColor3=C(255,255,255),TextSize=24,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"UIPadding","UIPadding",{PaddingBottom=U(0,12),PaddingLeft=U(0,12),PaddingRight=U(0,16),PaddingTop=U(0,12)},false},
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://127840699991988",LayoutOrder=-1,Position=U2(1,0,1,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"UICorner","UICorner",false,false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,25),Color=C(255,255,255),Transparency=0.949999988},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}},
    {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
    {"Frame","TextContainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.368801773,0,0,0),Size=U2(0.123293519,100,1,0)},{
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","Medium","Normal"),LayoutOrder=2,Position=U2(0.0377906971,0,0.863636374,0),Size=U2(0,200,0,0),Text="R$100",TextColor3=C(16,255,136),TextSize=16,TextXAlignment=E("TextXAlignment","Left")},false},
     {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","Y"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),LayoutOrder=1,Position=U2(0.0377906971,0,0.782828271,0),Size=U2(0,200,0,0),Text="142376088",TextColor3=C(255,255,255),TextSize=24,TextTransparency=0.25,TextXAlignment=E("TextXAlignment","Left")},false},
     {"UIListLayout","UIListLayout",{SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false}}},
    {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
     {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
    {"Frame","buttoncontainer",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.719901741,0,0,0),Size=U2(0.146962181,100,1,0)},{
     {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,16),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
     {"UIPadding","UIPadding",{PaddingLeft=U(0,16)},false},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734934585",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734933222",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
     {"TextButton","TextButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,64,0,64),Text="",TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
      {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
      {"UIStroke","UIStroke",{ApplyStrokeMode=E("ApplyStrokeMode","Border"),BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(40,43,53),Transparency=0.5,ZIndex=999},{
       {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
      {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747362393",ImageTransparency=0.850000024,Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}}}}}}}},
  {"Frame","Toolbar2",{AnchorPoint=V2(1,1),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(16,17,21),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(0,0,0,32),ZIndex=2},{
   {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false},
   {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Enabled=false,Transparency=0.75},{
    {"UIGradient","UIGradient",{Rotation=-94,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
   {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,4),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
   {"UIPadding","UIPadding",{PaddingLeft=U(0,6),PaddingRight=U(0,6)},false},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Clear",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747362393",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Import",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709799288",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"UIScale","UIScale",{Scale=1.13},false},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"Frame","Divider",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,3,0.5,0)},{
    {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Filter",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723375128",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}},
   {"UIShadow","UIShadow",{BlurRadius=U(0,15),Transparency=0.5},false},
   {"TextButton","TextButton",{AutoButtonColor=false,AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(0,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},{
    {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
    {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,0,1,0),Text="Export",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024},false},
    {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723387563",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},false},
    {"UIPadding","UIPadding",{PaddingLeft=U(0,8),PaddingRight=U(0,8)},false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false}}}}},
  {"TextButton","TextButton",{AnchorPoint=V2(1,0),AutoButtonColor=false,BackgroundColor3=C(255,255,255),BackgroundTransparency=0.975000024,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),LayoutOrder=-999,Position=U2(1,0,0,0),Size=U2(1,-72,0,36),Text="",TextColor3=C(0,0,0),TextSize=14,ZIndex=3},{
   {"UICorner","UICorner",{BottomLeftRadius=U(0,6),BottomRightRadius=U(0,6),TopLeftRadius=U(0,6),TopRightRadius=U(0,6)},false},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734943674",ImageTransparency=0.850000024,LayoutOrder=-1,Position=U2(0,0,0.5,0),Size=U2(0,16,0,16)},{
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false}}},
   {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/GothamSSm.json","SemiBold","Normal"),Size=U2(0,-2,1,0),Text="Search...",TextColor3=C(255,255,255),TextSize=16,TextTransparency=0.850000024,TextXAlignment=E("TextXAlignment","Left")},false},
   {"UIListLayout","UIListLayout",{FillDirection=E("FillDirection","Horizontal"),HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder"),VerticalAlignment=E("VerticalAlignment","Center")},false},
   {"UIPadding","UIPadding",{PaddingLeft=U(0,12)},false}}},
  {"Frame","Frame",{AnchorPoint=V2(1,1),BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,0,1,0),Size=U2(1,-72,0,100)},{
   {"UIGradient","UIGradient",{Rotation=90,Transparency=NS({0,1,0},{0.503355682,0,0},{1,0,0})},false}}},
  {"Frame","SideBar",{BackgroundColor3=C(13,14,17),BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,64,1,0),ZIndex=99},{
   {"UICorner","UICorner",{BottomLeftRadius=U(0,12),BottomRightRadius=U(0,12),TopLeftRadius=U(0,12),TopRightRadius=U(0,12)},false},
   {"UIPadding","UIPadding",{PaddingBottom=U(0,6),PaddingLeft=U(0,6),PaddingRight=U(0,6),PaddingTop=U(0,6)},false},
   {"Frame","Content",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(1,0,1,0)},{
    {"Frame","IconHolder",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Size=U2(0,100,0,100)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://106640334752928",Position=U2(0.5,0,0.5,0),Size=U2(0,32,0,32)},false}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=1,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10723407389",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709811365",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton (Active)",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=2,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Enabled=false,Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709807111",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Enabled=false,Transparency=0.949999988},false}}},
    {"Frame","TabButton (Active)",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=3,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.5},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709782154",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Enabled=false,Transparency=0.949999988},false}}},
    {"UIListLayout","UIListLayout",{HorizontalFlex=E("UIFlexAlignment","Fill"),Padding=U(0,8),SortOrder=E("SortOrder","LayoutOrder")},false},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10709806740",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}}}},
    {"Frame","TabButton",{BackgroundColor3=C(28,28,28),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(119,207,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6),Visible=false},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10734950020",ImageTransparency=0.949999988,Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Enabled=false,Transparency=0.949999988},false}}},
    {"Frame","TabButton",{BackgroundColor3=C(255,255,255),BackgroundTransparency=0.949999988,BorderColor3=C(0,0,0),BorderSizePixel=0,LayoutOrder=4,Position=U2(-0.635527253,0,0.500438213,0),Size=U2(1,0,1,0)},{
     {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
     {"Frame","Accent",{AnchorPoint=V2(0.5,1),BackgroundColor3=C(255,255,255),BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(0.5,0,1,-6),Size=U2(1,-36,0,6)},{
      {"UICorner","UICorner",{BottomLeftRadius=U(1,0),BottomRightRadius=U(1,0),TopLeftRadius=U(1,0),TopRightRadius=U(1,0)},false}}},
     {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
     {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
      {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}},
     {"TextButton","Hitbox",{BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxasset://fonts/families/SourceSansPro.json","Regular","Normal"),Size=U2(1,0,1,0),TextColor3=C(0,0,0),TextSize=14,TextTransparency=1},false},
     {"UIGradient","UIGradient",{Rotation=74,Transparency=NS({0,0,0},{0.5,0.246000007,0},{1,1,0})},false},
     {"ImageLabel","ImageLabel",{AnchorPoint=V2(0.5,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://10747373176",Position=U2(0.5,0,0.5,0),Size=U2(0,24,0,24)},false},
     {"Frame","Tooltip",{AnchorPoint=V2(0,0.5),AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Position=U2(1,24,0.5,0),Size=U2(1,0,0.5,0),Visible=false},{
      {"TextLabel","TextLabel",{AutomaticSize=E("AutomaticSize","X"),BackgroundColor3=C(0,0,0),BorderColor3=C(0,0,0),BorderSizePixel=0,FontFace=F("rbxassetid://12187365364","Medium","Normal"),Size=U2(0,0,1,0),Text="execution",TextColor3=C(255,255,255),TextSize=18},{
       {"UIPadding","UIPadding",{PaddingBottom=U(0,4),PaddingLeft=U(0,12),PaddingRight=U(0,12),PaddingTop=U(0,4)},false},
       {"UICorner","UICorner",false,false}}},
      {"ImageLabel","ImageLabel",{AnchorPoint=V2(0,0.5),BackgroundColor3=C(255,255,255),BackgroundTransparency=1,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://357733779",ImageColor3=C(0,0,0),Position=U2(0,-8,0.5,0),ScaleType=E("ScaleType","Fit"),Size=U2(0,12,0,12)},false}}},
     {"UIShadow","UIShadow",{BlurRadius=U(0,35),Color=C(255,255,255),Transparency=0.949999988},false}}}}},
   {"ImageLabel","ImageLabel",{AnchorPoint=V2(1,1),BackgroundColor3=C(255,255,255),BackgroundTransparency=0.985000014,BorderColor3=C(0,0,0),BorderSizePixel=0,Image="rbxassetid://127840699991988",Position=U2(1,0,1,0),Size=U2(1,0,1,0),Visible=false},{
    {"UIAspectRatioConstraint","UIAspectRatioConstraint",false,false},
    {"UICorner","UICorner",{BottomLeftRadius=U(0.215000004,0),BottomRightRadius=U(0.215000004,0),TopLeftRadius=U(0.215000004,0),TopRightRadius=U(0.215000004,0)},false},
    {"UIShadow","UIShadow",{BlurRadius=U(0,25),Color=C(255,255,255),Transparency=0.949999988},false},
    {"UIStroke","UIStroke",{BorderStrokePosition=E("BorderStrokePosition","Inner"),Color=C(48,48,48),Transparency=0.649999976},{
     {"UIGradient","UIGradient",{Rotation=45,Transparency=NS({0,0,0},{0.5,1,0},{1,0,0})},false}}}}}}}}},
 {"LocalScript","Navigation",false,false,false,false,4},
 {"LocalScript","ScriptStoreClient",false,false,false,false,5},
 {"LocalScript","ScriptBlox",false,false,false,false,6},
 {"ModuleScript","Storage",false,false,false,false,7},
 {"ModuleScript","ButtonFx",false,false,false,false,8},
 {"ModuleScript","ScriptActions",false,false,false,false,9},
 {"LocalScript","Splash",false,false,false,false,10},
 {"LocalScript","Accounts",false,false,false,false,11},
 {"ModuleScript","Layout",false,false,false,false,12},
 {"LocalScript","Responsive",false,false,false,false,13},
 {"ModuleScript","OutputLog",false,false,false,false,14},
 {"ModuleScript","Settings",false,false,false,false,15},
 {"ModuleScript","Toast",false,false,false,false,16},
 {"LocalScript","SettingsPage",false,false,false,false,17},
 {"LocalScript","Output",false,false,false,false,18}}}

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
