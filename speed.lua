local plr = game.Players.LocalPlayer

local mt = getrawmetatable(game)
setreadonly(mt,false)
local index = mt.__index
local newindex = mt.__newindex

local ws = 80
local spoofTo = plr.Character.Humanoid.WalkSpeed

mt.__index = newcclosure(function(t,i)
    -- index = "WalkSpeed"
    -- table = "Humanoid"
    if tostring(i) == "WalkSpeed" then
        if not checkcaller() then
            return spoofTo
        end
    end
    return index(t,i)
end)

plr.Character.Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
plr.Character.Humanoid.WalkSpeed = ws
end)
plr.Character.Humanoid.WalkSpeed = 0