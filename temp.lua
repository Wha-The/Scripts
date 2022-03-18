local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Assets = ReplicatedStorage.Assets

local BuildController = Knit.CreateController {
    Name = "BuildController"
}

local mainModules = Knit.MainModules
local clientModules = Knit.ClientModules

local guiEffects = clientModules.GuiEffects

local config = Knit.MainModules.Config
local nodePlacement = require(mainModules.NodePlacement)
local itemsConfig = require(config.ItemsConfig)
local Awards = require(config.Awards)

local button = require(clientModules.Button)
local notification = require(Knit.ClientModules.Notification)

local proximityGui = require(clientModules.ProximityGui)

local fadeModule = require(guiEffects.FadeModule)
local ComputerController

local BUILD_MODE, BACKPACK_MODE = "Build", "Backpack"
local CATEGORY_MODE, ITEMS_MODE = "Category", "Items"

local Handler

-- Category Tween Properties
local FADE_TIME, FADE_INCREMENT = 0.05, 280
local TWEEN_TIME = 0.08

local titleTween = nil

-- Tween Category / Item Frame
local function TweenCategory(category, direction)
    local background = category.Background

    local originalSize = background.Size
    local dividedScale = UDim2.new(originalSize.X.Scale / 1.5, 0, originalSize.Y.Scale / 1.5, 0)

    background.Size = (direction == "Out") and dividedScale or originalSize

    local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection[direction], 0, false, 0)
    local tween = TweenService:Create(background, tweenInfo, {Size = (direction == "Out") and originalSize or dividedScale})

    tween:Play()
    tween.Completed:Wait()
end

-- Add / Remove Categories & Items
local function ChangeState(stateType, state, instance, y)
    local self = BuildController

    local itemsFrame = self.BuildGui.Items
    local categoriesFrame = self.BuildGui.Categories

    -- Remove Category / Item
    if (not state) then
        local index = #categoriesFrame:GetChildren()
        -- Loop through existing instances and remove them
        for i = 1, index do
            for _, oldInstance in pairs((stateType == CATEGORY_MODE) and categoriesFrame:GetChildren() or itemsFrame:GetChildren()) do
                if ((not oldInstance:IsA("TextButton") and not oldInstance:IsA("ImageButton")) or oldInstance == instance or oldInstance.ZIndex ~= (index - i)) then
                    continue
                end

                task.spawn(function()
                    TweenCategory(oldInstance, "In")
                end)

                fadeModule:FadeFrame(oldInstance, FADE_TIME, "Out", true, "Tween")
                task.wait(FADE_TIME - (i / FADE_INCREMENT))

                oldInstance:Destroy()
            end
        end

        return
    end

    -- Tween new instance
    task.spawn(function()
        TweenCategory(instance, "Out")
    end)

    fadeModule:FadeFrame(instance, 0, "Out", true, "Direct")
    fadeModule:FadeFrame(instance, FADE_TIME, "In", true, "Tween")

    task.wait(FADE_TIME - (y / FADE_INCREMENT))
end

local function CopyTable(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = CopyTable(v)
        end
        copy[k] = v
    end
    return copy
end

local setupDesk_offsetForCategory = {
    PCs = {Vector3.new(-4.54265251159668, 1.4124022722244263, -0.0918121337890625), CFrame.Angles(0, math.rad(180), 0)},
    Monitors = {Vector3.new(-1.3406906127929688, 1.3996315002441406, -0.9465484619140625), CFrame.Angles(0, 0, 0)},
    Microphones = {Vector3.new(0.5621910095214844, 1.3628894090652466, 0.7365875244140625), CFrame.Angles(0, 0, 0)},
    Cameras = {Vector3.new(-1.6296024322509766, 1.4052143096923828, -0.5440521240234375), CFrame.Angles(0, math.rad(90), 0)},
    Keyboards = {Vector3.new(-1.5610637664794922, 1.4505314826965332, 0.8126373291015625), CFrame.Angles(0, math.rad(270), 0)},
    Mouses = {Vector3.new(-3.2, 1.3824272155761719, 0.5928955078125), CFrame.Angles(0, math.rad(90), 0)},
}
local oldProximityPrompts = {}
local sitDebounce = false
function BuildController:Unweld(child)
    for _, desc in pairs(child:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.Anchored = true
        end
    end
end


local placedItemIcons = {}
local function ApplyIconToItem(item, icon)
    local c = game.ReplicatedStorage.Assets.Interactive.ItemEffect:Clone()
    c.ImageLabel.Image = icon
    c.Parent = item
    table.insert(placedItemIcons, c)
end

task.spawn(function()
    Knit.OnStart():await()
    local Handler = Knit.GetController("Handler")
    Handler.Handlers.Events:Register("SetPlacedItemIconsVisible", function(enabled)
        for _, i in pairs(placedItemIcons) do
            i.Enabled = enabled
        end
    end)
end)

function BuildController:InitializePlacedModel(model, nodeData)
    local Handler = Knit.GetController("Handler")
    local itemData = itemsConfig:GetItem(model:GetAttribute("Id"))
    local rotation = nodeData.Rotation

    if itemData.SpecialType == 1 then
        local systemData = Handler.Handlers.ClientDataCache:Get().System
        self._setupDesk = model
        self._setupDeskNodeData = nodeData
        
        local setupConfig = require(Knit.MainModules.Config.SetupConfig)
        local oldSetup = model:FindFirstChild("Setup")
        if oldSetup then
            oldSetup:Destroy()
        end
        local old_MonitorScreen = model:FindFirstChild("_MonitorScreen")
        if old_MonitorScreen then
            old_MonitorScreen:Destroy()
        end
        local newSetup = Instance.new("Model")
        newSetup.Name = "Setup"
        newSetup.Parent = model

        local indicator = Instance.new("ObjectValue", newSetup)
        indicator.Name = "_MonitorScreen"
        indicator.Parent = model

        for category, setItem in pairs(systemData.Setup) do
            local offsetData = setupDesk_offsetForCategory[category]
            local offset, offsetRotation = offsetData[1], offsetData[2]
            assert(offset, "No offset set for setup category "..category)
            local itemData = setupConfig:GetItemById(setItem)
            local componentModel = itemData.Model:Clone()
            componentModel.Name = category
            componentModel.Parent = newSetup
            for _, part in pairs(componentModel:GetChildren()) do
                if part:IsA("BasePart") and part ~= componentModel.PrimaryPart then
                    local partOldTransparency = part.Transparency
                    part.Transparency = 1
                    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0)
                    local itemTween = TweenService:Create(part, tweenInfo, {Transparency = partOldTransparency})

                    itemTween:Play()
                end
            end
            local deskCFrame = model:GetPrimaryPartCFrame()
            offset = nodePlacement.AccountRotation(offset, rotation - 90)
            componentModel:SetPrimaryPartCFrame((deskCFrame + offset) * offsetRotation + componentModel.PrimaryPart.Size * Vector3.new(0, 0.5, 0))
            if category == "Monitors" then
                indicator.Value = componentModel.Screen
            end
        end
    end

    --   Placed Item Properties
    local itemColors = {}
    for _, part in pairs(model:GetDescendants()) do
        if (part:IsA("BasePart") and part ~= model.PrimaryPart) then
            local partColor = part.Color
            itemColors[part] = partColor
        end
    end

    model:SetAttribute("IsLoading")

    local newItemColors = CopyTable(itemColors)
    Knit.GetController("HouseController").ClientGrid.itemColors[model] = newItemColors
    for _, child in pairs(model:GetChildren()) do
        if child:IsA("Seat") then
            child.Anchored = true
            if oldProximityPrompts[child] then
                oldProximityPrompts[child]:TweenProximityRemoval()
            end
            local newProximityGui = proximityGui.new({
                object = child,
                buttons = "E",
                maxDistance = 5,
                shouldForceCloseFunction = function()
                    return self.FrameStatus or not game.Players.LocalPlayer.Character or not game.Players.LocalPlayer.Character.Humanoid or game.Players.LocalPlayer.Character.Humanoid.Sit or (child.Parent:FindFirstChild("_MonitorScreen") and ComputerController.State == ComputerController.STATES.UPLOADING) or self.PlayerInteractingWithObject
                end,
                path = "Apartment",
            })
            oldProximityPrompts[child] = newProximityGui
            child.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    oldProximityPrompts[child] = nil
                end
            end)
            newProximityGui:OnClick(function()
                if self.FrameStatus then return end
                if not Knit.GetController("HouseController").PlayerInPlot then return end
                if game.Players.LocalPlayer.Character.Humanoid.Sit or self.PlayerInteractingWithObject then return end

                if child.Parent:FindFirstChild("_MonitorScreen") then
                    if sitDebounce then
                        return
                    end
                end

                self.PlayerInteractingWithObject = true
                local activatedScene = false
                if child.Parent:FindFirstChild("_MonitorScreen") then
                    
                    task.spawn(function() ComputerController:ActivateScene(child.Parent._MonitorScreen.Value) end)
                    activatedScene = true
                end
                local char = game.Players.LocalPlayer.Character

                local originalCFrame = char:GetPrimaryPartCFrame()
                local seatf = child:Clone()
                seatf.Parent = workspace
                seatf.CFrame += Vector3.new(0, 1.5, 0)
                local Weld = Instance.new("Weld")
                Weld.Part0 = seatf
                Weld.Part1 = char.PrimaryPart
                Weld.Parent = seatf
                Weld.Name = "SeatWeld"
                char.Humanoid.Sit = true
                local conn, conn2
                local getOut = function()
                    if sitDebounce then 
                        task.wait()
                        char.Humanoid.Sit = true                  
                    end
                    if activatedScene then
                        task.spawn(function() ComputerController:DeactivateScene() end)
                    end
                    self.PlayerInteractingWithObject = false
                    char.Humanoid.Sit = false
                    conn:Disconnect()
                    if conn2 then
                        conn2:Disconnect()
                    end
                    Weld:Destroy()
                    seatf:Destroy()
                    Handler.Handlers.Events:Deregister("ExitSeat")
                    if (char.PrimaryPart.Position - child.Position).Magnitude < 5 then
                        char:SetPrimaryPartCFrame(originalCFrame)
                        char.PrimaryPart.AssemblyLinearVelocity *= Vector3.new(1, 0, 1)
                    end
                    
                    task.spawn(function()
                        sitDebounce = true
                        task.wait(1)
                        sitDebounce = false
                    end)
                    return true
                end
                conn = Handler:OnTeleport(getOut)
                if not activatedScene then
                    conn2 = Handler:OnJump(getOut, true)
                else
                    conn2 = Handler:OnJump(function()
                        task.wait()
                        char.Humanoid.Sit = true
                    end)
                end

                
                Handler.Handlers.Events:Register("ExitSeat", getOut)

                sitDebounce = true
                task.wait(1)
                sitDebounce = false
            end)
        elseif child:IsA("Model") and child.Name == "FridgeDoor" then
            self:Unweld(child)
            ApplyIconToItem(child.Parent, "rbxassetid://8958282294")
            local newProximityGui = proximityGui.new({
                object = model.PrimaryPart,
                buttons = "E",
                maxDistance = 5,
                shouldForceCloseFunction = function()
                    return self.FrameStatus or self.PlayerInteractingWithObject
                end,
                path = "Apartment",
            })
            local state = false
            local debounce = false
            local originalCFrame = child:GetPrimaryPartCFrame()
            local callback
            callback = function()
                if self.FrameStatus then return end
                if debounce then return end
                debounce = true
                local swungCFrame = not state and originalCFrame * CFrame.Angles(0, math.rad(90 * (child:GetAttribute("SwingDirection") == "Left" and -1 or 1)), 0) or originalCFrame
                task.spawn(function() Handler:TweenPrimaryPart(child, swungCFrame, 0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out) end)
                state = not state
                if state then
                    Handler.Handlers.Events:Register("CloseFridgeDoor", callback)
                    Knit.GetController("FridgeController"):Open()
                else
                    Handler.Handlers.Events:Deregister("CloseFridgeDoor")
                    Knit.GetController("FridgeController"):Close()
                end
                debounce = false
            end

            newProximityGui:OnClick(callback)
        elseif child:IsA("Model") and child.Name == "Pillow" then
            ApplyIconToItem(child.Parent, "rbxassetid://8958284223")
            local newProximityGui = proximityGui.new({
                object = child.PrimaryPart,
                buttons = "E",
                maxDistance = 10,
                shouldForceCloseFunction = function()
                    return self.FrameStatus or self.PlayerInteractingWithObject
                end,
                path = "Apartment",
            })

            newProximityGui:OnClick(function()
                if self.PlayerInteractingWithObject then return end
                self.PlayerInteractingWithObject = true
                Handler.Handlers.Events:AttemptCall("SetPlacedItemIconsVisible", false)
                local sleepPart = child.Parent.SleepPart
                sleepPart.Anchored = true
                local root = game.Players.LocalPlayer.Character.PrimaryPart
                local scf = sleepPart.CFrame * CFrame.Angles(0, math.rad(90), 0)
                local originalCFrame = game.Players.LocalPlayer.Character:GetPrimaryPartCFrame()
                game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(scf)
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = root
                weld.Part1 = sleepPart
                weld.Parent = root
                local track = Handler.Handlers.AnimationHandler:PlayAnimation("Sleeping", nil, {Looped = true, Speed = 2.5})
                Knit.GetService("PlayerService"):Sleep(itemData.Id)
                track:Stop()
                weld:Destroy()
                game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(originalCFrame) 
                self.PlayerInteractingWithObject = false
                Handler.Handlers.Events:AttemptCall("SetPlacedItemIconsVisible", true)
            end)
        elseif child:IsA("BasePart") and child.Name == "ArcadeScreen" then
            ApplyIconToItem(child.Parent, "rbxassetid://8962729017")
            local newProximityGui = proximityGui.new({
                object = child,
                buttons = "E",
                maxDistance = 5,
                shouldForceCloseFunction = function()
                    return self.FrameStatus or self.PlayerInteractingWithObject
                end,
                path = "Apartment",
            })


            newProximityGui:OnClick(function()
                if self.PlayerInteractingWithObject then return end
                Handler.Handlers.Events:AttemptCall("SetPlacedItemIconsVisible", false)
                self.PlayerInteractingWithObject = true
                local stand = child.Parent.Stand
                stand.Anchored = true
                local root = game.Players.LocalPlayer.Character.PrimaryPart
                game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(stand.CFrame)
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = root
                weld.Part1 = stand
                weld.Parent = root
                
                local playing = true
                task.spawn(function()
                    while task.wait() and playing do
                        Handler.SimpleTween(child.Parent.ArcadeScreen, "Color", Color3.fromRGB(141, 162, 166)).Completed:Wait()
                        Handler.SimpleTween(child.Parent.ArcadeScreen, "Color", Color3.fromRGB(174, 199, 203)).Completed:Wait()
                    end
                    Handler.SimpleTween(child.Parent.ArcadeScreen, "Color", Color3.fromRGB(148, 169, 172))
                end)

                local track = Handler.Handlers.AnimationHandler:PlayAnimation("ArcadeMachine", nil, {Looped = true, Speed = 2.5})
                Knit.GetService("PlayerService"):PlayArcadeMachine(itemData.Id)
                playing = false
                track:Stop()
                weld:Destroy()
                self.PlayerInteractingWithObject = false
                Handler.Handlers.Events:AttemptCall("SetPlacedItemIconsVisible", true)
            end)
        elseif child.Name == "Special:DiscoFloor" then
            local Color1 = child.Parent:WaitForChild("Color 1")
            local Color2 = child.Parent:WaitForChild("Color 2")

            local c1, c2 = Color3.fromRGB(255, 0, 191), Color3.fromRGB(4, 175, 236)

            task.spawn(function()
                while task.wait(2) and child.Parent.Parent do
                    for _, child in pairs(Color1:GetChildren()) do
                        if child:IsA("BasePart") then
                            Handler.SimpleTween(child, "Color", c1)
                        end
                    end
                    for _, child in pairs(Color2:GetChildren()) do
                        if child:IsA("BasePart") then
                            Handler.SimpleTween(child, "Color", c2)
                        end
                    end
                    task.wait(2)
                    for _, child in pairs(Color1:GetChildren()) do
                        if child:IsA("BasePart") then
                            Handler.SimpleTween(child, "Color", c2)
                        end
                    end
                    for _, child in pairs(Color2:GetChildren()) do
                        if child:IsA("BasePart") then
                            Handler.SimpleTween(child, "Color", c1)
                        end
                    end
                end
            end)
        elseif child.Name == "Special:Router5" then
            self:Unweld(child.Parent)
            Handler.Handlers.Visuals.Hover(child.Parent.C1, {
                FloatUpBy = 1,
            })
            Handler.Handlers.Visuals.Rotate(child.Parent.C1)
        elseif child.Name == "Special:Router6" then
            self:Unweld(child.Parent)
            Handler.Handlers.Visuals.Hover(child.Parent.C1, {
                FloatUpBy = 1,
            })
            Handler.Handlers.Visuals.Rotate(child.Parent.C1)
            Handler.Handlers.Visuals.Rainbow(child.Parent.C2)
        elseif child.Name == "General:Clutter" then
            local modelsSorted = {}
            for _, model in pairs(child:GetChildren()) do
				if model:IsA("Model") then
					if math.random(1,3) ~= 3 and _ <= (child:GetAttribute("Max") or 10) then
						table.insert(modelsSorted, model)
					else
						_ -= 1
					end
                end
            end
            table.sort(modelsSorted, function(a, b)
                return a:GetModelCFrame().Position.Y > b:GetModelCFrame().Position.Y
            end)
            for _, model in pairs(modelsSorted) do
                local tween
                for _, descendant in pairs(model:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        tween = Handler.SimpleTween(descendant, "Transparency", 0, 0.5 / #modelsSorted)
                    end
                end
                tween.Completed:Wait()
            end
        end
    end
end

local buildFrameTween = nil

-- Tween Main Build Frame (Both in and out supported)
function BuildController:TweenBuildFrame(direction)
    local BUILD_TWEEN_TIME = 0.35
    if (buildFrameTween) then return end

    self.BuildGui.Visible = true

    local tweenInfo = TweenInfo.new(BUILD_TWEEN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection[direction], 0, false, 0)
    buildFrameTween = TweenService:Create(self.BuildGui, tweenInfo, {
        Position = self.BUILD_FRAME_POSITIONS[direction]
    })

    buildFrameTween:Play()
    buildFrameTween.Completed:Wait()

    buildFrameTween = nil

    self.BuildGui.Visible = (direction == "Out")
end

-- Switch state between activating categories / items, Parlement: CATEGORY_MODE, ITEMS_MODE
function BuildController:SwitchChoosing(state)
    local title = self.BuildGui.TitleFrame.Title
    local originalPosition = title.Position

    local TWEEN_TIME, FADE_TIME = 0.18, 0.15
    local TWEEN_OFFSET, TWEEN_DELAY = -0.15, 0.3

    -- Set State
    self.CurrentState = state
    
    if (titleTween) then
        title.Text = (itemsConfig.Display[self.CurrentCategory] or self.CurrentCategory) or state
        return
    end

    -- Tween Category / Item Based on State
    for i = 1, 2 do
        fadeModule:FadeFrame(title, FADE_TIME, (i == 1) and "Out" or "In", false, "Tween")

        local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection[(i == 1) and "In" or "Out"], 0, false, 0)
        titleTween = TweenService:Create(title, tweenInfo, {Position = UDim2.new(originalPosition.X.Scale, 0, (i == 1) and TWEEN_OFFSET or originalPosition.Y.Scale, 0)})

        titleTween:Play()
        titleTween.Completed:Wait()

        title.Text = (itemsConfig.Display[self.CurrentCategory] or self.CurrentCategory) or state

        task.wait(TWEEN_DELAY)
    end

    titleTween = nil
end

-- Tween Return Button
function BuildController:TweenReturnButton(object, direction)
    local TWEEN_POSITION = 1.1
    local BUTTON_TWEEN_TIME = 0.35

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local mainGui = playerGui:WaitForChild("MainGui")
    local originalPosition = mainGui.ReturnButton.Position

    local tweenInfo = TweenInfo.new(BUTTON_TWEEN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
    local buttonTween = TweenService:Create(object, tweenInfo, {
        Position = (direction == "Out") and originalPosition or UDim2.new(originalPosition.X.Scale, 0, TWEEN_POSITION, 0)
    })

    buttonTween:Play()
    buttonTween.Completed:Wait()
end

-- UNFINISHED!
-- Check for eventual inout on placed items (e.g. Delete, Move)
-- Tween color of item based on hovering or click
function BuildController:_ChangeSelectionColor(item, hoverEnter)
    local SELECTION_TWEEN_TIME = 0.35
    local houseController = Knit.GetController("HouseController")
    local currentGrid = houseController.ClientGrid

    if (currentGrid.ChangingItem or (self.ProximityObject and self.ProximityObject.Item ~= item)) then return end

    for _, part in pairs(item:GetDescendants()) do
        if (not part:IsA("BasePart") or part == item.PrimaryPart) then continue end

        local tweenInfo = TweenInfo.new(SELECTION_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0)
        local itemTween = TweenService:Create(part, tweenInfo, {
            Color = hoverEnter and currentGrid.SELECTION_PLACEMENT_COLOR or currentGrid.itemColors[item][part]
        })

        itemTween:Play()
    end
end
function BuildController:_OnSelection(item)
    local houseController = Knit.GetController("HouseController")
    local currentGrid = houseController.ClientGrid
    -- Check for proximity and proximity item
    if (self.ProximityObject) then
        local proximityObject = self.ProximityObject

        if (proximityObject.Item == item) then
            proximityObject.Object:TweenProximityRemoval()
        end
        return
    end

    self:_ChangeSelectionColor(item, true)

    -- Add a new proximity GUI
    local buttons = {
        [1] = {Id = "Move", Image = "rbxassetid://8858219187"},
        [2] = {Id = "Delete", Image = "rbxassetid://8859526921", ImageColor3 = Color3.new(0.9, 0.3, 0.3)},
    }
    if itemsConfig:GetItem(item:GetAttribute("Id")).SpecialType == 1 then
        table.remove(buttons, 2)
        table.insert(buttons, {Id = "MessageUpgrade", Description = "Upgrade"})
    end
    if ComputerController.State == ComputerController.STATES.UPLOADING then
        table.remove(buttons, 1)
    end
    Knit.GetController("SoundController"):PlaySound("Click")
    local newProximityGui = proximityGui.new({
        object = item.PrimaryPart,
        buttons = buttons,
        onRemove = function()
            --self:_ChangeSelectionColor(item, false)
            --self.ProximityObject = nil
        end,
        blankClickDetector = true,
    })
    self.ProximityObject = {
        Item = item,
        Object = newProximityGui,
    }
    

    -- Check for proximity interaction
    newProximityGui:OnClick(function(buttonId)
        if (buttonId == "Delete") then
            newProximityGui:TweenProximityRemoval()
            if self._highlightedItem == item then
                self:_ChangeSelectionColor(self._highlightedItem, false)
                self._highlightedItem = nil
                if (self.ProximityObject) then
                    local proximityObject = self.ProximityObject
                    task.spawn(function() proximityObject.Object:TweenProximityRemoval() end)
                    self.ProximityObject = nil
                end
            end
            currentGrid:AttemptRemoveItem(item)
        elseif (buttonId == "Move") then
            newProximityGui:TweenProximityRemoval()
            self._moving_Temporary_Item = item
            self:Selectitem(itemsConfig:GetItem(item:GetAttribute("Id")), 3)
        elseif (buttonId == "MessageUpgrade") then
            local setupConfig = require(Knit.MainModules.Config.SetupConfig)
            local setupLevels = 0
            for _, id in pairs(Handler.Handlers.ClientDataCache:Get().System.Setup) do
                setupLevels += setupConfig:GetItemById(id).StarScore
            end

            local statusNotification = notification.new({
                NotificationType = "Informational",
                Title = "Upgrade",
                Description = "To upgrade your desk, visit the Setup Shop in the city! (orange building)",
                SetupScore = setupLevels,
                clickEffect = "Bounce"
            })
            statusNotification:Open()
        end
    end)

end

function BuildController:InputDetection()
    local houseController = Knit.GetController("HouseController")

    -- Placement, and Rotation Detection

    local function setHighlightedItem(isClick)
        local mouse = game.Players.LocalPlayer:GetMouse()
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
        raycastParams.FilterDescendantsInstances = {houseController:GetPlayerHouse().PlacedItems}--{game.Players.LocalPlayer.Character}

        local mouseRay = mouse.UnitRay
        local raycast = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)

        local function doCheck()
            if self._highlightedItem then
                if isClick or not self.ProximityObject then
                    self:_ChangeSelectionColor(self._highlightedItem, false)
                    self._highlightedItem = nil
                    if (self.ProximityObject) then
                        local proximityObject = self.ProximityObject
                        task.spawn(function() proximityObject.Object:TweenProximityRemoval() end)
                        self.ProximityObject = nil
                    end
                end
            end
        end
        local failed = false
        if raycast then
            local PlacedItems = houseController:GetPlayerHouse().PlacedItems
            if raycast.Instance:IsDescendantOf(PlacedItems) then
                local model = raycast.Instance
                while not model:IsA("Model") or model.Parent ~= PlacedItems do
                    model = model:FindFirstAncestorWhichIsA("Model")
                end
                if not model:GetAttribute("IsLoading") then
                    doCheck()
                    if not self.ProximityObject then
                        self._highlightedItem = model
                        self:_ChangeSelectionColor(self._highlightedItem, true)
                    end
                end
            else
                failed = true
            end
        else
            failed = true
        end
        if failed then
            doCheck()
        end
    end
    
    UserInputService.TouchTapInWorld:Connect(function(position, gameProcessed)
        local currentGrid = houseController.ClientGrid
        if (not currentGrid or gameProcessed or not self.FrameStatus) then return end
        if not currentGrid.SelectedItem then
            setHighlightedItem(true)
            if self._highlightedItem then
                self:_OnSelection(self._highlightedItem)
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local currentGrid = houseController.ClientGrid
        if (not currentGrid or gameProcessed or not self.FrameStatus) then return end
        if (input.UserInputType == Enum.UserInputType.MouseButton1) then
            if currentGrid.SelectedItem then return currentGrid:AttemptPlaceItem() end
            setHighlightedItem(true)
            if self._highlightedItem then
                self:_OnSelection(self._highlightedItem)
            end
        elseif (input.UserInputType == Enum.UserInputType.MouseButton3) then
            local mouse = game.Players.LocalPlayer:GetMouse()
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
            raycastParams.FilterDescendantsInstances = {currentGrid._grid}

            local mouseRay = mouse.UnitRay
            local raycast = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
            if (not raycast) then return end
            local node = currentGrid._node:GetNode(raycast.Position.X, raycast.Position.Z)
            if not node then return print("Can't determine node on mouse") end
            print("Node on mouse: ", string.format("Vector3.new(%s, %s, %s)", tostring(node.X), tostring(node.Y), tostring(node.Z)))
        elseif (input.KeyCode == Enum.KeyCode.R) then
            if currentGrid.SelectedItem then currentGrid:RotateItem() end
        end
    end)
    local counter = 0
    local interval = 1/10
    RunService.RenderStepped:Connect(function(step)
        counter += step
        if counter > interval then
            counter -= interval
            if (not houseController.ClientGrid or not self.FrameStatus or not self.PlacementEnabled) then return end
            setHighlightedItem(false)
        end
    end)
end

function BuildController:UpdateBuildGuide(enabled)
    Handler.Handlers.Events:AttemptCall(enabled and "BuildMode:MobileRegister" or "BuildMode:MobileDeregister")
    self.BuildGuide.Visible = enabled
    local isMobile = not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled and UserInputService.TouchEnabled
    self.BuildGuide.Desktop.Visible = not isMobile
    self.BuildGuide.Mobile.Visible = isMobile

    local houseController = Knit.GetController("HouseController")

    if not self._BuildGuideMobile_RotateButtonConnected then
        self._BuildGuideMobile_RotateButtonConnected = true
        local b = button.new(self.BuildGuide.Mobile.Rotate, {clickEffect = "Bounce", Async = true})
        b:OnClick(function()
            local currentGrid = houseController.ClientGrid
            if not currentGrid then return end
            if currentGrid.SelectedItem then currentGrid:RotateItem() end
        end)
    end
end

function BuildController:Selectitem(item, mode)
    if self._highlightedItem then
        self:_ChangeSelectionColor(self._highlightedItem, false)
        self._highlightedItem = nil
        if (self.ProximityObject) then
            local proximityObject = self.ProximityObject
            task.spawn(function() proximityObject.Object:TweenProximityRemoval() end)
            self.ProximityObject = nil
        end
    end

    
    self:UpdateBuildGuide(true)

    local TWEEN_POSITION = 1.1
    local houseController = Knit.GetController("HouseController")
    local currentGrid = houseController.ClientGrid
    if mode == 3 then
        self._moving_Temporary_Item.Parent = nil
        self._cleanUpPastMoveObject = function(success)
            if not self._moving_Temporary_Item then return end
            if success then
                self._moving_Temporary_Item:Destroy()
            else
                self._moving_Temporary_Item.Parent = Knit.GetController("HouseController"):GetPlayerHouse().PlacedItems
            end
            self._moving_Temporary_Item = nil
        end
        currentGrid._cleanUpPastMoveObject = self._cleanUpPastMoveObject
        local _getMoveObjectOriginalPosition = function()
            return self._moving_Temporary_Item and self._moving_Temporary_Item:GetPrimaryPartCFrame().Position
        end
        currentGrid._getMoveObjectOriginalPosition = _getMoveObjectOriginalPosition 
        
        local pos = _getMoveObjectOriginalPosition()
        local node = currentGrid._node:GetNode(pos.X, pos.Z)
        --task.spawn(function() nodePlacement.TemporarilyRemoveObject(node) end)
        
       
    end
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local mainGui = playerGui:WaitForChild("MainGui")
    
    local originalPosition = mainGui.ReturnButton.Position


    self.PlacementEnabled = false

    -- Call and Setup Return Button
    self.ReturnButton = button.new(mainGui.ReturnButton, {clickEffect = "Bounce", buttonType = "ReturnButton"})
    local returnObject = self.ReturnButton._object

    returnObject.Position = UDim2.new(originalPosition.X.Scale, 0, TWEEN_POSITION, 0)

    returnObject.Visible = true
    returnObject.ButtonText.Text = mode == 3 and "Cancel" or "Return"

    self.ReturnButton:OnClick(function()
        self:DeselectItem()
        if mode == 3 then
            self._cleanUpPastMoveObject()
        end
    end)

    task.spawn(function() self:TweenBuildFrame("In") end)

    -- Deactivate previous return buttons
    local otherButtons = button:GetButtonFromType("ReturnButton")
    if (otherButtons) then
        for _, button in pairs(otherButtons) do
            task.spawn(function() self:TweenReturnButton(button, "In") end)
        end
    end

    task.spawn(function() self:TweenReturnButton(returnObject, "Out") end)
    -- Select Item ClientGrid (Activate Placement)
    currentGrid:SelectItem(item.Id, mode)
end

function BuildController:DeselectItem(skipTween, deleteSelectedItem)
    local houseController = Knit.GetController("HouseController")
    if houseController.ClientGrid and houseController.ClientGrid.CurrentItem then
        houseController.ClientGrid:DeselectItem(deleteSelectedItem == nil and true or deleteSelectedItem)
    end
    self:UpdateBuildGuide(false)
    self.PlacementEnabled = true
    -- Tween Required GUI Elements
    if not skipTween then
        task.spawn(function() self:TweenBuildFrame("Out") end)
    end
    
    if self.ReturnButton then
        self:TweenReturnButton(self.ReturnButton._object, "In")

        self.ReturnButton:Remove()
    end

    -- Activate previous return buttons
    local otherButtons = button:GetButtonFromType("ReturnButton")
    if (otherButtons) then
        for _, button in pairs(otherButtons) do
            task.spawn(function() self:TweenReturnButton(button, "Out") end)
        end
    end
end

function BuildController:UpdateBuildStatus()
    self:ChangeGridStatus(self.FrameStatus)
    task.spawn(function()
        if self.ProximityObject then
            self.ProximityObject.Object:TweenProximityRemoval()
        end
    end)
    task.spawn(function()
        self:TweenBuildFrame(self.FrameStatus and "Out" or "In")
    end)
    Handler.Handlers.Events:AttemptCall("SetHUDEnabled", not self.FrameStatus)
    if not self.FrameStatus then
        self:DeselectItem(true)
    end
end

-- Enables / Disables the grid
function BuildController:ChangeGridStatus(status)
    local houseController = Knit.GetController("HouseController")

    if (not houseController.ClientGrid) then return end

    -- Init / Remove Grid
    if (status) then
        houseController.ClientGrid:InitGrid()
    else
        houseController.ClientGrid:RemoveGrid()
    end
end

function BuildController:UpdateItems()
    local dataService = Knit.GetService("DataService")

    local buildFrame = self.BuildGui

    local itemsFrame = buildFrame.Items
    local categoryFrame = buildFrame.Categories

    local instance = itemsFrame.Instance
    instance.Visible = false

    -- Switch from choosing a category to choosing an item
    task.spawn(function()
        self:SwitchChoosing(ITEMS_MODE)
    end)

    -- Disable items and categories
    ChangeState(ITEMS_MODE, false, itemsFrame.Instance)
    ChangeState(CATEGORY_MODE, false, categoryFrame.Instance)

    task.wait(FADE_TIME * 2)

    itemsFrame.Visible = true
    categoryFrame.Visible = false

    local currentMode = self.CurrentMode
    self._inMode = currentMode
    self.CurrentMode = nil

    local items = itemsConfig:GetCategory(self.CurrentCategory)
    table.sort(items, function(a, b)
        a, b = require(a), require(b)
        if a.ReduceUploadTimePercent and b.ReduceUploadTimePercent then
            return a.ReduceUploadTimePercent < b.ReduceUploadTimePercent
        end
        if a.MoodDecreaseReduction and b.MoodDecreaseReduction then
            return a.MoodDecreaseReduction < b.MoodDecreaseReduction
        end
        if a.EnergyDecreaseReduction and b.EnergyDecreaseReduction then
            return a.EnergyDecreaseReduction < b.EnergyDecreaseReduction
        end
        if a.CashIncreasePercent and b.CashIncreasePercent then
            return a.CashIncreasePercent < b.CashIncreasePercent
        end
        if a.CashIncreasePercent and b.CashIncreasePercent then
            return a.CashIncreasePercent < b.CashIncreasePercent
        end
        if Awards:GetAward(a.Id) and Awards:GetAward(b.Id) then
            local aa, ab = Awards:GetAward(a.Id), Awards:GetAward(b.Id)
            if self.CurrentCategory == "Play Buttons" then
                return aa.RequiredSubscribers < ab.RequiredSubscribers
            end
        end
        return a.Price < b.Price
    end)

    -- Loop through items player maintains in ownership
    local playerData = Handler.Handlers.ClientDataCache:Get()
    for i, item in pairs(items) do
        local requiredItem = require(item)
        if currentMode == BACKPACK_MODE and playerData.System.Items[requiredItem.Id] <= 0 then continue end

        local itemPath = Assets.Interior[requiredItem.Category][requiredItem.Id]
        assert(itemPath, "[BuildController]: The path for the " .. requiredItem.Id .. " item could not be found")

        local newItem = instance:Clone()
        local background = newItem.Background

        -- Display item infomation
        background.Price.Visible = requiredItem.Price
        background.Price.Text = "$" .. tostring(requiredItem.Price)

        background.Amount.Visible = (currentMode == BACKPACK_MODE)
        background.Amount.Text = playerData.System.Items[requiredItem.Id]

        -- Add item to viewport frame
        
        newItem.Background.ItemImage.Image = "rbxthumb://type=Asset&id="..requiredItem.Image.."&w=420&h=420"

        local itemButton = button.new(newItem, {clickEffect = "Bounce", scaleByConstraint = newItem.Background})

        -- TODO: Add inventory support
        -- Check for item activation
        itemButton:OnClick(function()
            if (not self.PlacementEnabled) then return end
            if not requiredItem.Price or Handler.Handlers.ClientDataCache:Get().Default.Money >= requiredItem.Price then
                self:Selectitem(requiredItem, currentMode == BACKPACK_MODE and 2 or 1)
            end
        end)

        newItem.Visible = true
        newItem.Parent = itemsFrame

        newItem.LayoutOrder = requiredItem.Price

        -- Enable Items
        ChangeState(ITEMS_MODE, true, newItem, i)
    end
end

function BuildController:GetCategoriesFromInventoryDepth(categories)
    local layers = 3
    if self.Depth == 0 then
        categories = {"Furniture", "Upgrades", "Awards"}
    else 
        if self.Depth == "Furniture" then
            local _modifiedcategories = {}
            for _, category in pairs(categories) do
                if not itemsConfig.UpgradeCategories[category] then
                    table.insert(_modifiedcategories, category)
                end
            end
            categories = _modifiedcategories
        elseif self.Depth == "Awards" then
            categories = {"Play Buttons"}
        else
            local _modifiedcategories = {}
            for _, category in pairs(categories) do
                if itemsConfig.UpgradeCategories[category] then
                    table.insert(_modifiedcategories, category)
                end
            end
            categories = _modifiedcategories
        end
    end
    return categories, layers
end
local _CategoryButtonsCooldown
-- Init and switch to a new set of categories
function BuildController:UpdateCategories(categories)
    local _originalCategories = categories
    local categoriesFrame = self.BuildGui.Categories

    categoriesFrame.Visible = true
    self.BuildGui.Items.Visible = false

    local instance = categoriesFrame.Instance
    instance.Visible = false

    -- Switch to category mode
    task.spawn(function()
        if (self.CurrentState == CATEGORY_MODE) then return end
        self:SwitchChoosing(CATEGORY_MODE)
    end)

    -- Disable Categories
    ChangeState(CATEGORY_MODE, false, instance)

    task.wait(FADE_TIME * 2)
    local layers
    if self.CurrentMode == BACKPACK_MODE then
        categories, layers = self:GetCategoriesFromInventoryDepth(categories)
    end

    local emptyMessage = self.BuildGui.EmptyMessage
    emptyMessage.Visible = categories and (#categories <= 0)

    fadeModule:FadeFrame(emptyMessage, 0, "Out", false, "Direct")
    fadeModule:FadeFrame(emptyMessage, FADE_TIME * 2, "In", false, "Tween")
    
    -- Set Categories Up
    for i, category in pairs(categories) do
        local newCategory = instance:Clone()
        newCategory.Background.Text.Text = itemsConfig.Display[category] or category
        local categoryButton = button.new(newCategory, {clickEffect = "Bounce", scaleByConstraint = newCategory.Background})

        categoryButton:OnClick(function()
            if _CategoryButtonsCooldown then return end
            _CategoryButtonsCooldown = true
            task.spawn(function()task.wait(1) _CategoryButtonsCooldown = false end)
            if self.Depth == 0 and self.CurrentMode == BACKPACK_MODE and layers > 2 then
                self.Depth = category
                return self:UpdateCategories(_originalCategories)
            end
            self.CurrentCategory = category

            local categoryEvent = self:UpdateItems()
            table.insert(self.CategoryEvents, categoryEvent)
        end)

        newCategory.ZIndex = i
        self.CategoryButtons[i] = newCategory

        newCategory.Visible = true
        newCategory.Parent = categoriesFrame

        ChangeState(CATEGORY_MODE, true, newCategory, i)
    end
end

local changeFrameStatusCooldown = false

function BuildController:ChangeFrameStatus(notImportant)
    if notImportant then
        if self.PlayerInteractingWithObject then return end
        if changeFrameStatusCooldown then return end
    end
    changeFrameStatusCooldown = true
    if self._highlightedItem then
        self:_ChangeSelectionColor(self._highlightedItem, false)
        self._highlightedItem = nil
        if (self.ProximityObject) then
            local proximityObject = self.ProximityObject
            task.spawn(function() proximityObject.Object:TweenProximityRemoval() end)
            self.ProximityObject = nil
        end
    end
    if self._cleanUpPastMoveObject then
        self._cleanUpPastMoveObject()
    end
    task.spawn(function()
        self:DeselectItem(true, true)
    end)

    local houseController = Knit.GetController("HouseController")
    -- Check if the player is in their plot or the build menu is already open
    if (self.FrameStatus or houseController.PlayerInPlot) then
        self.FrameStatus = not self.FrameStatus
        self:UpdateBuildStatus()
        task.spawn(function()
            task.wait(.5)
            changeFrameStatusCooldown = false
        end)
        if self.FrameStatus then 
            self._Inventory_UpdateMode()
        end
        return
    end

    -- Player is not in their plot yet, add a confirmation if they want to teleport to their plot
    local plotNotification = notification.new({
        NotificationType = "Confirmation",
        Title = "Teleport",
        Description = "Would you like to teleport to your house in order to decorate your apartment?",
        clickEffect = "Bounce",
        NonRefundable = false
    })

    plotNotification:Open()
    plotNotification:OnResponse(function(responseType)
        local character = game.Players.LocalPlayer.Character

        plotNotification:Close()
        if (not responseType or not character) then return end

        -- Teleport to plot
        houseController:TeleportToPlot(game.Players.LocalPlayer, character)
        self:ChangeFrameStatus(notImportant)

        return
    end)
    task.spawn(function()
        task.wait(.5)
        changeFrameStatusCooldown = false
    end)
end

function BuildController:KnitStart()
    Handler = Knit.GetController("Handler")

    local dataService = Knit.GetService("DataService")
    ComputerController = Knit.GetController("ComputerController")

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local mainGui = playerGui:WaitForChild("MainGui")

    -- Tweening Info
    self.BuildGui = mainGui:WaitForChild("Build")
    self.BuildGuide = mainGui:WaitForChild("BuildGuide")

    self.BUILD_FRAME_POSITIONS = {
        Out = self.BuildGui.Position,
        In = UDim2.new(0.5, 0, 1.5, 0)
    }

    local cooldown = false

    -- Function Init
    self.Depth = 0
    self.FrameStatus = true
    self:ChangeFrameStatus()

    self:InputDetection()
    self:SwitchChoosing(CATEGORY_MODE)

    -- Switch beteween Purchaseable and Purchased items
    local function UpdateMode()
        self._inMode = nil
        local categories = nil

        if (cooldown) then return end
        cooldown = true
        self.CurrentCategory = nil

        -- Check for mode
        if (self.CurrentMode == BUILD_MODE) then
            categories = itemsConfig:GetAllCategories()
        elseif (self.CurrentMode == BACKPACK_MODE) then
            categories = {}

            local playerData = Handler.Handlers.ClientDataCache:Get()

            -- Loop through items to search for owned items
            for itemId, itemIndex in pairs(playerData.System.Items) do
                if (itemIndex <= 0) then continue end
                local requiredItem = itemsConfig:GetItem(itemId)
                if not table.find(categories, requiredItem.Category) then
                    table.insert(categories, requiredItem.Category)
                end
            end
        end

        -- Init and switch to the categories
        self:UpdateCategories(categories)
        self.PlacementEnabled = true

        cooldown = false
    end

    local purchase = button.new(self.BuildGui.Purchase, {clickEffect = "Bounce", hoverEffect = "Rotate"})
    local backpack = button.new(self.BuildGui.Backpack, {clickEffect = "Bounce", hoverEffect = "Rotate"})
    local CloseButton = button.new(self.BuildGui.ExitButton, {clickEffect = "Bounce"})

    UpdateMode()

    -- Check for purchase or backpack switch interaction
    purchase:OnClick(function()
        if (self.CurrentMode == BUILD_MODE) then return end

        self.CurrentMode = BUILD_MODE
        UpdateMode()
    end)

    backpack:OnClick(function()
        if (self.CurrentMode == BACKPACK_MODE and self.Depth == 0) then return end

        self.CurrentMode = BACKPACK_MODE
        self.Depth = 0
        UpdateMode()
    end)
    CloseButton:OnClick(function()
        if (self._inMode == BACKPACK_MODE) then 
            self.CurrentMode = BACKPACK_MODE
            UpdateMode()
        elseif (self._inMode == BUILD_MODE) then
            self.CurrentMode = BUILD_MODE
            UpdateMode()
        elseif (self.Depth ~= 0) then
            self.Depth = 0
            self.CurrentMode = BACKPACK_MODE
            UpdateMode()
        else
            self:ChangeFrameStatus(true)
        end
    end)
    self._Inventory_Mode_Backpack = BACKPACK_MODE
    self._Inventory_Mode_Build = BUILD_MODE
    self._Inventory_UpdateMode = UpdateMode

    Knit.GetService("SetupService").ReloadDesk:Connect(function()
        Handler.Handlers.ClientDataCache:Reset()
        self:InitializePlacedModel(self._setupDesk, self._setupDeskNodeData)
    end)
end

function BuildController:KnitInit()
    -- Specify Modes, States, and Events
    self.CurrentMode = BUILD_MODE
    self.CurrentState = CATEGORY_MODE

    self.ItemButtons = {}
    self.CategoryButtons = {}

    self.CategoryEvents = {}
end

return BuildController
