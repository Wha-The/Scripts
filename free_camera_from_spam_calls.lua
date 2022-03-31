local LocalPlayer = game:GetService("Players").LocalPlayer
local OldIndex = nil

OldIndex = hookmetamethod(game, "__index", function(Self, Key)
    if not checkcaller() and Self == LocalPlayer and Key == "Character" then
        return nil
    end

    return OldIndex(...)
end)