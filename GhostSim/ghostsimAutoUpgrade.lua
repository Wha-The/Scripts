_G.AutoUpgrader = not _G.AutoUpgrader
_G.AF = false
local player = game.Players.LocalPlayer
local charger = game.Workspace.ScriptParts:FindFirstChild("PackChargers") and
    game.Workspace.ScriptParts:FindFirstChild("PackChargers").LabCharger or
    game.Workspace.ScriptParts.EctoplasmConverters.Converter

GhostAntennaLevels = setmetatable({},{
    __index=function(self,v)
        for _,entry in pairs(game:GetService("ReplicatedStorage").GhostEntries:GetDescendants()) do 
            if entry.Name == 'GhostName' then 
                if entry.Value == v then 
                    local lvl = entry.Parent.Parent.Stats.AntennaLevel.Value
                    self[v] = lvl
                    return lvl
                end
            end
        end
        return 0
    end,
})



local function farm(NPCS)
    NPCS = NPCS or {}
    if #NPCS <= 0 then
        print("Farm List: None")
        _G.AF = nil
        wait(2)
        return
    else
        _G.AF = true
    end
    print("Farm: ",table.concat(NPCS))
    local function getTargetList() 
        targets = {}
        for u,z in pairs(game.Workspace.Ghosts:GetChildren()) do 
            if table.find(NPCS,z.Name) then 
                table.insert(targets,z)
            end
        end
        return targets
    end
    local function allGhostsVaporized(list)
        local yes = true
        for i,v in pairs(list) do
            if _G.AF and (v:FindFirstChild("Body")) and v.Parent ~= game.Lighting then
                yes = false
            end
        end
        return yes
    end
    spawn(function()
        while wait() and _G.AF do
            local currentTargetList = getTargetList()
            print("TargetList: ",#currentTargetList)
            for u,z in pairs(currentTargetList) do 
                if GhostAntennaLevels[z.Name]>game.Players.LocalPlayer.Stats.AntennaLevel.Value then
                    continue
                end
                if z.Parent and z:FindFirstChild("Body") then
                    wait(.1)
                    if z:FindFirstChild("Body") then
                           
                        player.Character.HumanoidRootPart.CFrame = z.HumanoidRootPart.CFrame+Vector3.new(0,.1,5)
                    end
                    local vaccume = {}

                    for i,v in pairs(game.Workspace.Ghosts:GetChildren()) do
                        local mag = (v.Body.Position-game.Players.LocalPlayer.Character.HumanoidRootPart.Position).magnitude
                        if mag < 25 then
                            if GhostAntennaLevels[v.Name]<=game.Players.LocalPlayer.Stats.AntennaLevel.Value then
                                table.insert(vaccume,v)
                            end
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
                        until allGhostsVaporized(vaccume) or timeoutReached
                        print("All Ghosts vaporized! Moving on...")
                        spawn(function()
                            firetouchinterest(game.Players.LocalPlayer.Character.Head,charger,0)
                            wait()
                            firetouchinterest(game.Players.LocalPlayer.Character.Head,charger,1)
                        end)
                    end
                end
            end
        end
    end)
end
farm() -- Kill past instances
spawn(function()
    while wait(10) and _G.AutoUpgrader do
        game:GetService("ReplicatedStorage").Network.ToServer.Requests.UseItem:FireServer(111)
    end
end)
local RequirementsToGhostLookup = {
    ["Advanced Parts"]={
        "Firefly",
        "Swamp Dweller",
        "Frost Spirit",
        "Snowstorm",
        "Mushroom",
        "Flutter Spirit",
    },
    ["Datachip"]={"Firefly","Swamp Dweller"},
    ["Ice Cube"]={"Frost Spirit","Snowstorm"},
    ["Mushroom"]={"Mushroom","Flutter Spirit"},
    ["Bobber"]={"Water Spirit","Glitcher"},
    ["Apple"]={"Farmer","Crazy Cow"},
    ["Satellite"]={"Parasite","Super Computer"},
    ["Hay Bale"]={"Digital Bandit","Trojan Horse"},
    ["USB"]={"Web Surfer","Binary"},
    ["Ecto-Coffee"]={"Byte","Digi Cat"},
}

print("RUN",_G.AutoUpgrader)

local counter = 0
local autoUpgradeTools = game:GetService("RunService").Heartbeat:Connect(function(step)
    counter += step
    if counter > 30 then
        counter -= 30
        for i=1, 37 do
            game:GetService("ReplicatedStorage").Network.ToServer.Requests.PurchaseVacuum:FireServer(i)
        end
        for i=1, 33 do
            game:GetService("ReplicatedStorage").Network.ToServer.Requests.PurchasePack:FireServer(i)
        end
    end
end)

while _G.AutoUpgrader and wait() do
    local requirements = {}
    for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.UI.MainGui.CharacterMenu.MainFrame.Pages.Character.AntennaInfo.ItemLine.Container:GetChildren()) do
        if v:IsA("Frame") then
            local literal = v.Amount.Text:gsub("x","")
            requirements[v.Title.Text] = {
                amount=tonumber(literal),
                id=v.Name,
            }
        end
    end
    for material,conf in pairs(requirements) do
        if not _G.AutoUpgrader then return end
        local amount = conf.amount
        local id = conf.id
        local ghostsToFarm = RequirementsToGhostLookup[material]
        if not ghostsToFarm then warn(material,"Not Found!");return end
        farm(ghostsToFarm)
        print("Farming: ",material)
        print("Material ID:", id)
        local getCurrentlyHas = function()
            local currentlyhas = game.Players.LocalPlayer.Inventory.Items:FindFirstChild(id)
            if currentlyhas then 
                currentlyhas = currentlyhas.Value
            else
                print("Can't find value, assuming 0")
                currentlyhas = 0
            end
            return currentlyhas
        end
        repeat wait() until getCurrentlyHas() >= amount or not _G.AutoUpgrader
        print("Enough: ",material)
        farm()
    end
    game:GetService("ReplicatedStorage").Network.ToServer.Requests.UpgradeAntenna:FireServer()
    wait(3)
end
autoUpgradeTools:Disconnect()