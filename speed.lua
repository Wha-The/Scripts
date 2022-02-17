local h = game.Players.LocalPlayer.Character.Humanoid
h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
h.WalkSpeed = 80
end)
h.WalkSpeed = 0