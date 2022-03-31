local added = {}
local a = ""
for _, g in pairs(game:GetDescendants()) do
	if g:IsA("Sound") and not table.find(added, g.SoundId) and not string.find(g.SoundId, "rbxasset://") then
		table.insert(added, g.SoundId)
		a ..= "\n"..g.Name..": https://www.roblox.com/library/"..string.gsub(g.SoundId, "rbxassetid://", "").."/"
	end
end
setclipboard(a)
print(#added)