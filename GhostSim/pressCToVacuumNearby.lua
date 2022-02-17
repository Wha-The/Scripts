local UserInputService = game:GetService("UserInputService")
local scan = function()
        local vaccume = {
        }
        for i,v in pairs(game.Workspace.Ghosts:GetChildren()) do

                local mag = ((v:FindFirstChild("Body") and v.Body or v:GetModelCFrame()).Position-game.Players.LocalPlayer.Character.HumanoidRootPart.Position).magnitude
                if mag < 65 then
                        table.insert(vaccume,v)
                end
        end
        print(#vaccume.." Ghosts Found")
        game:GetService("ReplicatedStorage").Network.ToServer.Requests.StartUseVacuum:FireServer()
        for i,v in pairs(vaccume) do
                
                game:GetService("ReplicatedStorage").Network.ToServer.Requests.VacuumEnemy:FireServer(v)
        end
end
_G.ON = true
while wait(.3) and _G.ON do
        scan()
end