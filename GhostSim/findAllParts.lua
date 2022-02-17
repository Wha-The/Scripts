for _, i in pairs(workspace.ScriptParts.FindParts:GetChildren()) do
    if i:IsA("BasePart") then
        coroutine.wrap(function()
            firetouchinterest(game.Players.LocalPlayer.Character.PrimaryPart, i, 0)
            wait(1)
            firetouchinterest(game.Players.LocalPlayer.Character.PrimaryPart, i, 1)
        end)()
        wait()
    end
end