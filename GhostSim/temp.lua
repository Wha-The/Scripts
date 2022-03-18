queue_on_teleport('loadstring(game:HttpGet("https://pastebin.com/raw/11S1e2GR", true))()')
if game.PlaceId ~= 4383092793 then
	task.wait(5)
	return game:GetService("ReplicatedStorage").Network.ToServer.Requests.TransportToPlace:FireServer("Backdoor")
end
repeat wait() until game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character.PrimaryPart and workspace:FindFirstChild("Ghosts")
local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:connect(function()
   vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
   wait(1)
   vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)
local GhostDetectionIgnore = {
   "Ghastly Tree",
   "George the Gorilla",
   "Sludge",
   "Subject One",
   "King Krab",
   "Magmoraug",
   "Grim",
    "Anomaly",
    "Dino King",
    "Jolly Roger",
    "Anonymous",
}
local range = (game:GetService("Players").LocalPlayer.Stats.AppliedPasses.DoubleRange.Value and 50 or 25)
_G.AF = not _G.AF
local player = game.Players.LocalPlayer
local charger = game.Workspace.ScriptParts:FindFirstChild("PackChargers") and
    game.Workspace.ScriptParts:FindFirstChild("PackChargers").LabCharger or
    game.Workspace.ScriptParts.EctoplasmConverters:FindFirstChild("Converter") or
    game.Workspace.ScriptParts.EctoplasmConverters:FindFirstChild("EpilogueConverter")
NPCS = {"Programmer","RAM","Honeydrop","Bee", "Error 404", "Rock Crystal", "Web Surfer", "Binary", "Byte", "Digi Cat", "Lucky Cat"}
print("Farm: ",table.concat(NPCS))
local function getTargetList() 
    targets = {}
    for u,z in pairs(game.Workspace.Ghosts:GetChildren()) do 
        if table.find(NPCS,z.Name) or not next(NPCS) then 
            table.insert(targets,z)
        end
    end
    return targets
end
local function allGhostsVaporized(list)
    local yes = true
    for i,v in pairs(list) do
        if _G.AF and v.Parent and v.Parent ~= game.Lighting then
            yes = false
        end
    end
    return yes
end

spawn(function()
    while wait(10) and _G.AF do
        game:GetService("ReplicatedStorage").Network.ToServer.Requests.UseItem:FireServer(111)
    end
end)


spawn(function()
    while wait() and _G.AF do
        local currentTargetList = getTargetList()
        print("TargetList: ",#currentTargetList)
        
        for u,z in pairs(currentTargetList) do
            if z.Parent and z:FindFirstChild("Body") then
                wait()
                if z:FindFirstChild("Body") then
                    player.Character.HumanoidRootPart.CFrame = z.HumanoidRootPart.CFrame+Vector3.new(0,.1,5)
                end
                local vaccume = {}

                for i,v in pairs(game.Workspace.Ghosts:GetChildren()) do
                    local mag = (v:GetModelCFrame().Position-game.Players.LocalPlayer.Character.HumanoidRootPart.Position).magnitude
                    if mag < range and not table.find(GhostDetectionIgnore,v.Name) then
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
                    wait(.25)
                    repeat 
                        wait()
                            for i,v in pairs(vaccume) do
                                game:GetService("ReplicatedStorage").Network.ToServer.Requests.StartUseVacuum:FireServer()
                                game:GetService("ReplicatedStorage").Network.ToServer.Requests.VacuumEnemy:FireServer(v)
                            end
                    until allGhostsVaporized(vaccume) or timeoutReached
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
        done = true
    end
end)
if not _G.dropcollecton then

_G.dropcollecton = true
game:GetService("Players").LocalPlayer:WaitForChild("AvailableDrops").ChildAdded:Connect(function(a)
wait()
game:GetService("ReplicatedStorage").Network.ToServer.Requests.CollectDrop:FireServer(a)
end)

end


print("started")