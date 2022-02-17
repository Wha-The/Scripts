local UserInputService = game:GetService("UserInputService")

local originalView
local deb = false
local originalSensetivity = UserInputService.MouseDeltaSensitivity
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not deb and not gameProcessed and input.KeyCode == Enum.KeyCode.X then
		originalView = workspace.CurrentCamera.FieldOfView
		game:GetService("TweenService"):Create(workspace.CurrentCamera, TweenInfo.new(0.2), {FieldOfView = workspace.CurrentCamera.FieldOfView + 30}):Play()
	end
	if not deb and not gameProcessed and input.KeyCode == Enum.KeyCode.C then
		originalView = workspace.CurrentCamera.FieldOfView
		game:GetService("TweenService"):Create(workspace.CurrentCamera, TweenInfo.new(0.2), {FieldOfView = workspace.CurrentCamera.FieldOfView - 50}):Play()
		UserInputService.MouseDeltaSensitivity = originalSensetivity * 0.5
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.X then
		deb = true
		game:GetService("TweenService"):Create(workspace.CurrentCamera, TweenInfo.new(0.2), {FieldOfView = originalView}):Play()
		wait(.5)
		deb = false
	end
	if not gameProcessed and input.KeyCode == Enum.KeyCode.C then
		deb = true
		game:GetService("TweenService"):Create(workspace.CurrentCamera, TweenInfo.new(0.2), {FieldOfView = originalView}):Play()
		wait(.5)
		deb = false
		UserInputService.MouseDeltaSensitivity = originalSensetivity
	end
end)