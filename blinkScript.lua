local oldChar

local function on()
	oldChar = game.Players.LocalPlayer.Character
	local c = game.Players.LocalPlayer.Character
	c.Archivable = true
	c = c:Clone()
	c.Parent = workspace
	game.Players.LocalPlayer.Character = c
	oldChar.PrimaryPart.Anchored = true
    require(game:GetService("StarterPlayer").StarterPlayerScripts.PlayerModule.ControlModule):Enable()
	c.Humanoid.WalkSpeed *= 3
    c.Humanoid.JumpPower *= 3
    workspace.CurrentCamera.CameraSubject = c
end
local function off()
	oldChar:SetPrimaryPartCFrame(game.Players.LocalPlayer.Character:GetPrimaryPartCFrame())
	game.Players.LocalPlayer.Character:Destroy()
	oldChar.PrimaryPart.Anchored = false
	game.Players.LocalPlayer.Character = oldChar
    workspace.CurrentCamera.CameraSubject = oldChar
end

local enabled = false

game:GetService("UserInputService").JumpRequest:Connect(function()
	if enabled then
		game.Players.LocalPlayer.Character.Humanoid:ChangeState("Jumping")
	end
end)

game:GetService("UserInputService").InputBegan:Connect(function(input, gP)
	if gP then return end
	if input.KeyCode == Enum.KeyCode.B then
		enabled = not enabled
		local f = enabled and on or off
		f()
	end
end)

for i, connection in pairs(getconnections(game.Players.LocalPlayer.CharacterAdded)) do
    connection:Disable()
end
game.StarterGui:ClearAllChildren()
game.StarterPlayer.StarterCharacterScripts:ClearAllChildren()