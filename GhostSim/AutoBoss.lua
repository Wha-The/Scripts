

_G.AUTOBOSS = true
local Boss = workspace.Ghosts["King Krab"]
repeat 
wait();
-- Script generated by SimpleSpy - credits to exx#9394

local args = {
    [1] = Boss
}
game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = Boss:GetModelCFrame()+Vector3.new(0,10,0)
game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
game:GetService("ReplicatedStorage").Network.ToServer.Requests.StartUseVacuum:FireServer()
game:GetService("ReplicatedStorage").Network.ToServer.Requests.VacuumEnemy:FireServer(Boss)

until not _G.AUTOBOSS or not Boss.Parent