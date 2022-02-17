local lastY = 0
local float = false
local b = game:GetService("UserInputService")
b.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.M then
		float = not float
		if not float then
			print(lastY)
			
			local a = game.Players.LocalPlayer.Character.PrimaryPart:FindFirstChildWhichIsA("BodyVelocity")
			if a then a:Destroy() end
			local set = game.Players.LocalPlayer.Character.PrimaryPart.CFrame - game.Players.LocalPlayer.Character.PrimaryPart.Position * Vector3.new(0, 1, 0) + Vector3.new(0, lastY, 0)
			print(set)
			game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(set)
		else
			lastY = game.Players.LocalPlayer.Character.PrimaryPart.Position.Y
			local bf = Instance.new("BodyVelocity")
            bf.MaxVelocity = math.huge * Vector3.one
			bf.Velocity = Vector3.new(0, 0, 0)
			bf.Parent = game.Players.LocalPlayer.Character.PrimaryPart
			game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(game.Players.LocalPlayer.Character.PrimaryPart.CFrame + Vector3.new(0, 25, 0))
		end
	end

end)