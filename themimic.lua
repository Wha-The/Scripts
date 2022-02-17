loadstring(game:HttpGet(('https://pastebin.com/raw/WxmvCLLH'),true))()
game.Lighting:FindFirstChildWhichIsA("DepthOfFieldEffect"):Destroy()
loadstring(game:HttpGet("https://pastebin.com/raw/06iG6YkU", true))()

noclip = false
game:GetService('RunService').Stepped:connect(function()
if noclip then
game.Players.LocalPlayer.Character.Humanoid:ChangeState(11)
end
end)
plr = game.Players.LocalPlayer
mouse = plr:GetMouse()
mouse.KeyDown:connect(function(key)
 
if key == "v" then
noclip = not noclip
game.Players.LocalPlayer.Character.Humanoid:ChangeState(11)
end
end)
print('Loaded')
print('Press "E" to noclip')