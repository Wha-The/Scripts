

_G.AUTOBOSS = not _G.AUTOBOSS
local Boss
local b = game:GetService("Workspace").ScriptParts.EctoplasmConverters.GhostWorldConverter
repeat
firetouchinterest(game.Players.LocalPlayer.Character.Head, b, 0)
Boss = workspace.Ghosts:FindFirstChild("Grim") or workspace.Ghosts:FindFirstChild("Jolly Roger")
wait();
firetouchinterest(game.Players.LocalPlayer.Character.Head, b, 1)
if Boss then
-- Script generated by SimpleSpy - credits to exx#9394

local args = {
    [1] = Boss
}
game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = Boss:GetModelCFrame()+Vector3.new(0,10,0)
game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
game:GetService("ReplicatedStorage").Network.ToServer.Requests.StartUseVacuum:FireServer()
game:GetService("ReplicatedStorage").Network.ToServer.Requests.VacuumEnemy:FireServer(Boss)
end
until not _G.AUTOBOSS