_G.AUTOBOSS = not _G.AUTOBOSS

local g = game:GetService("Workspace").ScriptParts.EctoplasmConverters.GhostWorldConverter
repeat
local b = workspace.Ghosts:FindFirstChild("The Great Guardian")
firetouchinterest(game.Players.LocalPlayer.Character.Head, g, 0)
task.wait();
firetouchinterest(game.Players.LocalPlayer.Character.Head, g, 1)

local cor = game.Players.LocalPlayer.Character:FindFirstChild("Corruption")
if cor then
    cor.Value = 100
end
if b and b.Parent then
    local args = {
        [1] = b
    }
    if b:FindFirstChild("Health") and b.Health.Value <= 500 then
        game:GetService("ReplicatedStorage").Network.ToServer.Requests.UseItem:FireServer(117)
    end

    game:GetService("ReplicatedStorage").Network.ToServer.Requests.VacuumFireHit:FireServer(unpack(args))
    game:GetService("ReplicatedStorage").Network.ToServer.Requests.StartUseVacuum:FireServer()
    game:GetService("ReplicatedStorage").Network.ToServer.Requests.VacuumEnemy:FireServer(b)
    game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
    game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(b:GetPrimaryPartCFrame() + Vector3.new(1, 20, 0))
else
    game.Players.LocalPlayer.Character.PrimaryPart.CFrame = CFrame.new(Vector3.new(788, -814, 5163))
end
until not _G.AUTOBOSS