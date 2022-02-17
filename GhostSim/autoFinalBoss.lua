_G.AUTOBOSS = not _G.AUTOBOSS
spawn(function()
    while wait(5) and _G.AUTOBOSS do
          pcall(function()
            local rm = workspace.Ghosts:FindFirstChild("Final Boss"):FindFirstChild("RemoteEvent")
            if rm then
                rm:FireServer()
            end
        end)
    end
end)
repeat 
game:GetService("RunService").Heartbeat:Wait()
local ghost
if workspace.Ghosts:FindFirstChild("Final Boss") and workspace.Ghosts["Final Boss"].PrimaryPart.Position.Y < 80 then
    ghost = workspace.Ghosts:FindFirstChild("Final Boss")
end
if game.Workspace.Ghosts:FindFirstChild("Void Eye") then
    ghost = game.Workspace.Ghosts:FindFirstChild("Void Eye")
end
if game.Workspace.Ghosts:FindFirstChild("Pillar") then
    ghost = game.Workspace.Ghosts:FindFirstChild("Pillar")
end


if ghost then
    if ghost:FindFirstChild("HumanoidRootPart") then
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame((ghost:FindFirstChild("HEAD") and ghost.HEAD.CFrame or ghost.HumanoidRootPart.CFrame) + Vector3.new(20, 0, 20))
    end
    game:GetService("ReplicatedStorage").Network.ToServer.Requests.VacuumFireHit:FireServer(ghost)
elseif not workspace.Ghosts:FindFirstChild("Final Boss") then
    spawned = false
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(-282,239,2487))
    wait(5)
end

until not _G.AUTOBOSS