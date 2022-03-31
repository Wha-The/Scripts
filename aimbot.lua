local plrs = game:GetService("Players")
local TeamBased = true
local teambasedswitch = "o"
local presskeytoaim = true
local aimkey = "e"
local raycast = false

local espupdatetime = 5
autoesp = false

local lockaim = true
local lockangle = 5


local plrsforaim = {}

local lplr = game:GetService("Players").LocalPlayer

local f = {}
local espforlder



local RadarGUI = Instance.new("ScreenGui")
RadarGUI.Parent = game.CoreGui
RadarGUI.ResetOnSpawn = false

local FrameBG = Instance.new("Frame")
FrameBG.Parent = RadarGUI

FrameBG.AnchorPoint = Vector2.new(0.5,0.5)
FrameBG.Position = UDim2.new(0.7,0,0.5,0)
FrameBG.Size = UDim2.new(0.35,0,0.35,0)
FrameBG.Active = true

Instance.new("UIAspectRatioConstraint").Parent = FrameBG

FrameBG.BackgroundColor3 = Color3.new(0,0,0)
FrameBG.BackgroundTransparency = 0.6
local ZoomText = Instance.new("TextLabel")
ZoomText.BackgroundTransparency = 1
ZoomText.Font = Enum.Font.FredokaOne
ZoomText.Position = UDim2.new(0.5,0,1,0)
ZoomText.Size = UDim2.new(0.4,0,0.1,0)
ZoomText.AnchorPoint = Vector2.new(0.5,1)
ZoomText.TextScaled = true
ZoomText.TextColor3 = Color3.new(1,1,1)
ZoomText.TextStrokeTransparency = 0
ZoomText.Text = "Zoom: ?"
ZoomText.Parent = FrameBG
ZoomText.ZIndex = 2

local Frame = Instance.new("Frame")
Frame.BackgroundTransparency = 1
Frame.Parent = FrameBG
Frame.Size = UDim2.fromScale(1,1)
local scale = 1
local radius = 175 -- studs
local mapFPS = 15

FrameBG.MouseWheelBackward:Connect(function()
	radius += 5
	if radius > 500 then
		radius = 500
	end
end)
FrameBG.MouseWheelForward:Connect(function()
	radius -= 5
	if radius <= 100 then
		radius = 100
	end
end)

local function addTarget(part, color, indicator)
	local Dot = Instance.new("Frame")
	Dot.Name = indicator
	Dot.BackgroundColor3 = color
	local circle = Instance.new("UICorner")
	circle.Parent = Dot
	circle.CornerRadius = UDim.new(1,0)
	Dot.Size = UDim2.new(0.05 * scale,0,0.05 * scale,0)
	Dot.AnchorPoint = Vector2.new(0.5,0.5)
	
	local Object = Instance.new("ObjectValue")
	Object.Parent = Dot
	Object.Name = "Object"	
	Object.Value = part
	
	Dot.Parent = Frame
end

local function addWall(part)
	local Line = Instance.new("Frame")
	Line.Name = "__WALL"
	Line.BackgroundColor3 = Color3.new(1,1,1)
	Line.BorderSizePixel = 0
	
	Line.AnchorPoint = Vector2.new(0.5,0.5)
	
	local LookAngle = part.CFrame - part.CFrame.Position
	
	local y, z, x = LookAngle:ToOrientation()
	local rot = math.deg(-z)
	Line.Rotation = rot

	local Object = Instance.new("ObjectValue")
	Object.Parent = Line
	Object.Name = "Object"	
	Object.Value = part

	Line.Parent = Frame
	
end

local function removeTarget(indicator)
	if Frame:FindFirstChild(indicator) then
		Frame:FindFirstChild(indicator):Destroy()
	end
end

local Dot = Instance.new("Frame")
Dot.Name = "LOCALPLAYER"
Dot.BackgroundColor3 = Color3.new(0,1,1)
local circle = Instance.new("UICorner")
circle.Parent = Dot
circle.CornerRadius = UDim.new(1,0)
Dot.Size = UDim2.new(0.05 * scale,0,0.05 * scale,0)
Dot.AnchorPoint = Vector2.new(0.5,0.5)
Dot.Position = UDim2.new(0.5,0,0.5,0)
Dot.Parent = Frame

local counter = 0
game:GetService("RunService").Heartbeat:Connect(function(step)
	counter += step
	if mapFPS == 0 or counter > 1/mapFPS then
		-- update radar
		counter = 0
		local char = game.Players.LocalPlayer.Character
		if not char then return end
		local hrp = char:WaitForChild("HumanoidRootPart")
		local LookAngle = workspace.CurrentCamera.CFrame
		for _, child in pairs(Frame:GetChildren()) do
			if child:IsA("Frame") and child:FindFirstChild("Object") then
				local part = child.Object.Value
				if not part or not part.Parent then
					child:Destroy()
					return
				end
				local relative = CFrame.new(part.Position):ToObjectSpace(CFrame.new(hrp.Position))
				local onmap = UDim2.fromScale(0.5 + relative.Position.X / radius, 0.5 + relative.Position.Z / radius)
				child.Position = onmap
				if onmap.X.Scale <0 or onmap.X.Scale > 1 or onmap.Y.Scale < 0 or onmap.Y.Scale > 1 then
					child.Visible = false
				else
					child.Visible = true
				end
	 		end
		end
		-- update Invisible Frame to respect camera look direction
		
		local y, z, x = LookAngle:ToOrientation()
		local rot = 180 + math.deg(z)
		Frame.Rotation = rot
		
		-- Update Wall Sizes, make walls under player not visible
		for _, child in pairs(Frame:GetChildren()) do
			if child.Name == "__WALL" then
				local part = child.Object.Value
				if not part or not part.Parent then
					child:Destroy()
					return
				end
				local Z = part.Size.Z / radius
				local X = part.Size.X / radius

				X = X < 1 and X or 1
				Z = Z < 1 and Z or 1
				child.Size = UDim2.fromScale(X,Z)
				if child.Visible then
					child.Visible = LookAngle.Position.Y < (part.Position.Y + part.Size.Y)
				end
			end
		end
	end
	ZoomText.Text = "Zoom: "..radius
end)

local checkTarget = function(child)
	if not child:IsA("BasePart") or child:IsA("Terrain") then
		return
	end
	
	if child.Size.Y > 10 and child.Transparency ~= 1 then
		addWall(child)
	end
	
end
for _, child in pairs(workspace:GetDescendants()) do checkTarget(child) end
workspace.DescendantAdded:Connect(checkTarget)















function getfovxyz(p0, p1, deg)
	local x1, y1, z1 = p0:ToOrientation()
	local cf = CFrame.new(p0.p, p1.p)
	local x2, y2, z2 = cf:ToOrientation()
	--local d = math.deg
	if deg then
		--return Vector3.new(d(x1-x2), d(y1-y2), d(z1-z2))
	else
		return Vector3.new((x1 - x2), (y1 - y2), (z1 - z2))
	end
end


function checkfov(part)
	local fov = getfovxyz(game.Workspace.CurrentCamera.CFrame, part.CFrame)
	local angle = math.abs(fov.X) + math.abs(fov.Y)
	return angle
end


f.addesp = function()
	--print("ESP ran")
	if espforlder then
	else
		espforlder = Instance.new("Folder")
		espforlder.Parent = game.Workspace.CurrentCamera
	end
	for i, v in pairs(espforlder:GetChildren()) do
		v:Destroy()
	end
	for _, plr in pairs(plrs:GetChildren()) do
		if plr.Character and plr.Character.Humanoid.Health > 0 and plr.Name ~= lplr.Name then
			if TeamBased == true then
				if plr.Team.Name ~= plrs.LocalPlayer.Team.Name then
					local e = espforlder:FindFirstChild(plr.Name)
					if not e then
						--print("Added esp for team based")
						local bill = Instance.new("BillboardGui", espforlder)
						bill.Name = plr.Name
						bill.AlwaysOnTop = true
						bill.Size = UDim2.new(2.5, 0, 2.5, 0)
						bill.Adornee = plr.Character.Head
						local Frame = Instance.new("Frame", bill)
						Frame.Active = true
						Frame.BackgroundColor3 = Color3.new(0.541176, 0.168627, 0.886275)
						Frame.BackgroundTransparency = 0
						Frame.BorderSizePixel = 0
						Frame.AnchorPoint = Vector2.new(.5, .5)
						Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
						Frame.Size = UDim2.new(1, 0, 1, 0)
						Frame.Rotation = 0
						addTarget(plr.Character.Head, Color3.new(0.541176, 0.168627, 0.886275), plr.Name)
						plr.Character.Humanoid.Died:Connect(function()
							bill:Destroy()
							removeTarget(plr.Name)
						end)
					end
				end
			else
				local e = espforlder:FindFirstChild(plr.Name)
				if not e then
					--print("Added esp")
					local bill = Instance.new("BillboardGui", espforlder)
					bill.Name = plr.Name
					bill.AlwaysOnTop = true
					bill.Size = UDim2.new(1, 0, 1, 0)
					bill.Adornee = plr.Character.Head
					local Frame = Instance.new("Frame", bill)
					Frame.Active = true
					Frame.BackgroundColor3 = Color3.new(0.541176, 0.168627, 0.886275)
					Frame.BackgroundTransparency = 0
					Frame.BorderSizePixel = 0
					Frame.AnchorPoint = Vector2.new(.5, .5)
					Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
					Frame.Size = UDim2.new(1, 0, 1, 0)
					Frame.Rotation = 0
					addTarget(plr.Character.Head, Color3.new(0.541176, 0.168627, 0.886275), plr.Name)
					plr.Character.Humanoid.Died:Connect(
						function()
							bill:Destroy()
							removeTarget(plr.Name)
						end
					)
				end
			end
		end
	end
end
local cam = game.Workspace.CurrentCamera

local mouse = lplr:GetMouse()
local switch = false
local key = "k"
local aimatpart = nil
mouse.KeyDown:Connect(function(a)
		if a == "t" then
			f.addesp()
		elseif a == "u" then
			if raycast == true then
				raycast = false
			else
				raycast = true
			end
		elseif a == "l" then
			if autoesp == false then
				autoesp = true
			else
				autoesp = false
			end
		end
		if a == "j" then
			if mouse.Target then
				mouse.Target:Destroy()
			end
		end
		if a == key then
			if switch == false then
				switch = true
			else
				switch = false
				if aimatpart ~= nil then
					aimatpart = nil
				end
			end
		elseif a == teambasedswitch then
			if TeamBased == true then
				TeamBased = false
			else
				TeamBased = true
			end
		elseif a == aimkey then
			if not aimatpart then
				local maxangle = math.rad(20)
				for i, plr in pairs(plrs:GetChildren()) do
					if
						plr.Name ~= lplr.Name and plr.Character and plr.Character.Head and plr.Character.Humanoid and
						plr.Character.Humanoid.Health > 1
					then
						if TeamBased == true then
							if plr.Team.Name ~= lplr.Team.Name then
								local an = checkfov(plr.Character.Head)
								if an < maxangle then
									maxangle = an
									aimatpart = math.random(1,3) == 1 and plr.Character.Head or plr.Character.PrimaryPart
								end
							end
						else
							local an = checkfov(plr.Character.Head)
							if an < maxangle then
								maxangle = an
								aimatpart = plr.Character.Head
							end
						end
						plr.Character.Humanoid.Died:Connect(
							function()
								if aimatpart.Parent == plr.Character or aimatpart == nil then
									aimatpart = nil
								end
							end
						)
					end
				end
			else
				aimatpart = nil
			end
		end
	end
)


function getaimbotplrs()
	plrsforaim = {}
	for i, plr in pairs(plrs:GetChildren()) do
		if
			plr.Character and plr.Character.Humanoid and plr.Character.Humanoid.Health > 0 and plr.Name ~= lplr.Name and
			plr.Character.Head
		then
			if TeamBased == true then
				if plr.Team.Name ~= lplr.Team.Name then
					local cf = CFrame.new(game.Workspace.CurrentCamera.CFrame.p, plr.Character.Head.CFrame.p)
					local r = Ray.new(cf, cf.LookVector * 10000)
					local ign = {}
					for i, v in pairs(plrs.LocalPlayer.Character:GetChildren()) do
						if v:IsA("BasePart") then
							table.insert(ign, v)
						end
					end
					local obj = game.Workspace:FindPartOnRayWithIgnoreList(r, ign)
					if obj.Parent == plr.Character and obj.Parent ~= lplr.Character then
						table.insert(plrsforaim, obj)
					end
				end
			else
				local cf = CFrame.new(game.Workspace.CurrentCamera.CFrame.p, plr.Character.Head.CFrame.p)
				local r = Ray.new(cf, cf.LookVector * 10000)
				local ign = {}
				for i, v in pairs(plrs.LocalPlayer.Character:GetChildren()) do
					if v:IsA("BasePart") then
						table.insert(ign, v)
					end
				end
				local obj = game.Workspace:FindPartOnRayWithIgnoreList(r, ign)
				if obj.Parent == plr.Character and obj.Parent ~= lplr.Character then
					table.insert(plrsforaim, obj)
				end
			end
		end
	end
end

function aimat(part)
	cam.CFrame = CFrame.new(cam.CFrame.p, part.CFrame.p)
end


game:GetService("RunService").RenderStepped:Connect(function()
	if aimatpart then
		local lowestY = (plrs.LocalPlayer.Character and plrs.LocalPlayer.Character.PrimaryPart and plrs.LocalPlayer.Character.PrimaryPart.Position.Y - 40)
		if lowestY and aimatpart.Position.Y < lowestY then
			aimatpart = nil
		else
			aimat(aimatpart)
			if aimatpart.Parent == plrs.LocalPlayer.Character then
				aimatpart = nil
			end
		end
	end
	if raycast == true and switch == false and not aimatpart then
		getaimbotplrs()
		aimatpart = nil
		local maxangle = 999
		for i, v in ipairs(plrsforaim) do
			if v.Parent ~= lplr.Character then
				local an = checkfov(v)
				if an < maxangle and v ~= lplr.Character.Head then
					maxangle = an
					aimatpart = v
					v.Parent.Humanoid.Died:Connect(function() aimatpart = nil end)
				end
			end
		end
	end
end
)
coroutine.wrap(function()
	while wait(5) do
		if autoesp == true then
			pcall(f.addesp)
		end
	end
end)
warn("loaded")

local AutoShoot = false
local HighlightShots = true
UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gP)
	if not gP and input.KeyCode == Enum.KeyCode.Z then
		AutoShoot = not AutoShoot
		print("AutoShoot: ",AutoShoot)
	end
	if not gP and input.KeyCode == Enum.KeyCode.L then
		HighlightShots = not HighlightShots
	end
end)
local mouse1down = mouse1down or function()end
local mouse1up = mouse1up or function()end
coroutine.wrap(function()
    local isClicking = false
	while task.wait(.1) do
		if AutoShoot and aimatpart then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Whitelist
			params.FilterDescendantsInstances = {aimatpart.Parent}
			local ray = workspace:Raycast(workspace.CurrentCamera.CFrame.Position, CFrame.new(workspace.CurrentCamera.CFrame.Position, aimatpart.Position).LookVector * 200, params)
			if ray and ray.Instance then
                
                if isClicking then return end
                isClicking = true
                mouse1down()
                print("HOLD MOUSE")
            else
                if isClicking then
                    isClicking = false
                    mouse1up()
                    print("RELEASE MOUSE")
                end
			end
        else
            if isClicking then
                isClicking = false
                mouse1up()
                print("RELEASE MOUSE")
            end
		end
	end
end)()

local mouseDown = false

UIS.InputBegan:Connect(function(input, gp)
	if not gp and input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = true
		if HighlightShots then
			while mouseDown do
				coroutine.wrap(function()
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Blacklist
					params.FilterDescendantsInstances = {
						game:GetService("Players").LocalPlayer.Character,
					}
					local ray = workspace:Raycast(workspace.CurrentCamera.CFrame.Position, workspace.CurrentCamera.CFrame.LookVector * 200, params)
				
					local att0 = Instance.new("Attachment")
					local att1 = Instance.new("Attachment")
					att0.Parent = workspace.Terrain
					att1.Parent = workspace.Terrain
					att0.Position = workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.lookVector * 1
					att1.Position = ray and ray.Position or workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.lookVector * 200
					local beam = Instance.new("Beam")
					beam.Attachment0 = att0
					beam.Attachment1 = att1
					beam.Color = ColorSequence.new(Color3.new(128, 0, 128))
					beam.LightEmission = 0
					beam.LightInfluence = 1
					beam.CurveSize0 = 0
					beam.CurveSize1 = 0
					beam.FaceCamera = true
					beam.Enabled = true
					beam.Transparency = NumberSequence.new(0.5)
					beam.Width0 = .2
					beam.Width1 = .2
					beam.Parent = att0
					task.wait(1.5)
					beam:Destroy()
					att0:Destroy()
					att1:Destroy()
				end)()
				task.wait(task.wait())
				
			end
		end
	end
end)
UIS.InputEnded:Connect(function(input, gP)
	if not gP and input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = false
	end
end)