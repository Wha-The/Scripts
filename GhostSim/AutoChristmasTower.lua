setfpscap(15)
local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:connect(function()
   vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
   wait(1)
   vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

local is = Instance.new("BodyVelocity")
is.MaxForce = Vector3.one * math.huge
is.Velocity = Vector3.zero
is.Parent = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")

_G.AUTOTOWER = not _G.AUTOTOWER
local player = game.Players.LocalPlayer
local charger = game.Workspace.ScriptParts:FindFirstChild("PackChargers") and
    game.Workspace.ScriptParts:FindFirstChild("PackChargers").LabCharger or
    game.Workspace.ScriptParts.EctoplasmConverters:FindFirstChild("Converter") or
    game.Workspace.ScriptParts.EctoplasmConverters:FindFirstChild("EpilogueConverter") or
    game.Workspace.ScriptParts.EctoplasmConverters:FindFirstChild("GhostWorldConverter")
if not _G.dropcollecton then
 
_G.dropcollecton = true
game:GetService("Players").LocalPlayer:WaitForChild("AvailableDrops").ChildAdded:Connect(function(a)
wait()
game:GetService("ReplicatedStorage").Network.ToServer.Requests.CollectDrop:FireServer(a)
end)
 
end
local function allGhostsVaporized(list)
    local yes = true
    for i,v in pairs(list) do
        if _G.AUTOTOWER and v.Parent and v.Parent ~= game.Lighting then
            yes = false
            break
        end
    end
    return yes
end

local rng = Random.new(os.time())

local function shuffle(array)
    local item
    for i = #array, 1, -1 do
        item = table.remove(array, rng:NextInteger(1, i))
        table.insert(array, item)
    end
end

local range = (game:GetService("Players").LocalPlayer.Stats.AppliedPasses.DoubleRange.Value and 50 or 25)

local scan = function()
    local s = workspace.Ghosts:GetChildren()
    shuffle(s)
    for u,z in pairs(s) do
        if z.Parent and z:FindFirstChild("Tower") then
            task.wait(.1)
            local body = z:FindFirstChild("HumanoidRootPart") and z.HumanoidRootPart
            body = body and body.CFrame or z:GetModelCFrame()
            player.Character.HumanoidRootPart.CFrame = body + Vector3.new(0,.1,5)
            local vaccume = {}
            local vs = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
            for i,v in pairs(game.Workspace.Ghosts:GetChildren()) do
                local bodyv = v:FindFirstChild("HumanoidRootPart") and v.HumanoidRootPart
                bodyv = bodyv and bodyv.CFrame or v:GetModelCFrame()
                local mag = (bodyv.Position-game.Players.LocalPlayer.Character.HumanoidRootPart.Position).magnitude
                if mag < range then
                    table.insert(vaccume,v)
                end
            end
            print("Attempting to vaccum "..#vaccume)
            if #vaccume >= 1 then
                local timeoutReached = false
                spawn(function()
                    wait(8)
                    timeoutReached = true
                end)
                repeat 
                    wait()
                    for i,v in pairs(vaccume) do
                        game:GetService("ReplicatedStorage").Network.ToServer.Requests.StartUseVacuum:FireServer()
                        game:GetService("ReplicatedStorage").Network.ToServer.Requests.VacuumEnemy:FireServer(v)
                    end
                until allGhostsVaporized(vaccume) or timeoutReached-- or (vs - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 30
                print("All Ghosts vaporized! Moving on...")
                if typeof(charger) == "Instance" then
                    spawn(function()
                        firetouchinterest(game.Players.LocalPlayer.Character.Head,charger,0)
                        wait()
                        firetouchinterest(game.Players.LocalPlayer.Character.Head,charger,1)
                    end)
                end
            end
        end
    end
end

repeat 
task.wait();
if game:GetService("Workspace").ScriptParts.MegaBossArenas["1"].InfoDisplay.SurfaceGui.Frame.Label.Text == "TOWER READY" then
    if not game.Players.LocalPlayer.Character then
        game.Players.LocalPlayer.CharacterAdded:Wait()
    end
    game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(Vector3.new(354, 334, -156)))
    task.wait(2)
else
    game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(workspace.ScriptParts.MegaBossArenas["1"].FloorTeleport.CFrame)
    print(workspace.ScriptParts.MegaBossArenas[1].TowerStatus.UI.Desc.Text)
    if workspace.ScriptParts.MegaBossArenas[1].TowerStatus.UI.Desc.Text ~= 'FLOOR <font color="#ff0000">8</font> IN PROGRESS...' then
        local cor = game.Players.LocalPlayer.Character:FindFirstChild("Corruption")
        if cor then
            cor.Value = 100
        end
        game:GetService("ReplicatedStorage").Network.ToServer.Requests.UseItem:FireServer(110)
        repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.UI.MainGui.DungeonDisplay.RoomFrame.Label.Text ~= ". . ." or not _G.AUTOTOWER
        local origin = game:GetService("Workspace").ScriptParts.MegaBossArenas["1"].Data.GhostsRemaining.Value
        repeat scan(); task.wait() until game:GetService("Workspace").ScriptParts.MegaBossArenas["1"].Data.GhostsRemaining.Value <= 0 or not _G.AUTOTOWER
        if origin > 0 then
            game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(workspace.Map.Tower:WaitForChild("EndRoom").BasicConstruction.Door.CFrame)
            task.wait(3)
        end
        local boss = game:GetService("Workspace").ScriptParts.MegaBossArenas["1"].Data.Boss
        if boss.Value then
            print("Boss: ", boss.Value.Name)
            repeat wait();
                if boss.Value and boss.Value:FindFirstChild("HumanoidRootPart") then
                    local args = {
                        [1] = boss.Value
                    }
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = boss.Value.HumanoidRootPart.CFrame + Vector3.new(0,30,0)
                    game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                    game:GetService("ReplicatedStorage").Network.ToServer.Requests.StartUseVacuum:FireServer()
                    game:GetService("ReplicatedStorage").Network.ToServer.Requests.VacuumEnemy:FireServer(boss.Value)
                    game:GetService("ReplicatedStorage").Network.ToServer.Requests.VacuumFireHit:FireServer(boss.Value)
                end
            until not boss.Value or not _G.AUTOTOWER
            if not game.Players.LocalPlayer.Character then
                game.Players.LocalPlayer.CharacterAdded:Wait()
            end
            game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(game:GetService("Workspace").ScriptParts.MegaBossArenas["1"].LeavePortal.CFrame)
        end
    end
end
until not _G.AUTOTOWER