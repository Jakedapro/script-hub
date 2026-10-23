-- Paste into execute_luau (Client) during a playtest: per-page hash of what's on screen, for comparing
-- the place's own GUI against gui.lua. `detail` lists the lines of one page instead.
local detail = nil -- e.g. "main.SideBar"
local gui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("ScreenGui")
local function line(d)
	local p, s = d.AbsolutePosition, d.AbsoluteSize
	local text = (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and d.Text or ""
	local image = (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Image or ""
	return string.format("%s %d,%d %dx%d v%s t%.2f %s %s", d:GetFullName():gsub("^.-ScreenGui%.", ""), p.X, p.Y, s.X, s.Y,
		tostring(d.Visible), d.BackgroundTransparency, text, image)
end
local function hash(str)
	local h = 5381
	for i = 1, #str do
		h = (h * 33 + string.byte(str, i)) % 4294967296
	end
	return string.format("%08x", h)
end
local out = {}
for _, page in gui:GetChildren() do
	if page:IsA("GuiObject") then
		local lines = {line(page)}
		for _, d in page:GetDescendants() do
			if d:IsA("GuiObject") and not d.Name:match("^Card%d+$") and not d:FindFirstAncestorWhichIsA("ScrollingFrame") then
				table.insert(lines, line(d))
			end
		end
		table.sort(lines)
		local key = page.Name
		if detail and detail:sub(1, #key) == key then
			local picked = {}
			for _, l in lines do
				if l:sub(1, #detail) == detail then
					table.insert(picked, l)
				end
			end
			return table.concat(picked, "\n")
		end
		table.insert(out, string.format("%s %s (%d)", key, hash(table.concat(lines, "\n")), #lines))
	end
end
table.sort(out)
return table.concat(out, "\n")
