local a = Instance.new("Part")
a.Transparency = 0.5
a.Anchored = true
a.Color = Color3.new(1, 0, 0)

a.CanCollide = false
a.CanTouch = false
a.CanQuery = false
a.Size = Vector3.new(3, 6, 2)

a.Parent = workspace

game:GetService("RunService").RenderStepped:Connect(function(step)
	if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character.PrimaryPart then
		a.CFrame = game.Players.LocalPlayer.Character:GetPrimaryPartCFrame()
		for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
			if not v.Parent:IsA("Tool") and v:IsA("BasePart") then
				sethiddenproperty(v, "Transparency", 1)
			end
		end
		game.Players.LocalPlayer.Character.Humanoid.AutoRotate = false
		game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(game.Players.LocalPlayer.Character:GetPrimaryPartCFrame() * CFrame.Angles(0, math.rad(step * 1000), 0))
	end
end)