local commands = {}
local game_namecall
local loadscript = function(scripturl)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Wha-The/Scripts/main/"..scripturl..".lua"))()
end
commands.r = function(scripturl)
    loadscript(scripturl)
end
commands.spy = function()
    loadscript("simplespyv2")
end

function checkmsg(msg)
    if string.sub(msg, 0, 1) == "!" then
        local args = string.split(string.sub(msg, 2), " ")
        if #args >= 1 then
            local cmd = args[1]
            local fn = commands[cmd]
            local result = "Command not found"
            if fn then
                table.remove(args, 1)
                result = fn(unpack(args))
            end
            if result then
                game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                    Text = result;
                    Font = Enum.Font.ArialBold;
                    Colour = Color3.new(1, 1, 1);
                    FontSize = Enum.FontSize.Size96;
                })
            end
        end
        return true
    end
    return false
end

local newnamecall = newcclosure(function(remote, ...)
    local n_tuple = {...}
	if typeof(remote) == "Instance" and not checkcaller() then
        local methodName = getnamecallmethod()
        local validInstance, remoteName = pcall(function()
			return remote.Name
		end)
		if
			validInstance
			and (methodName == "FireServer" or methodName == "fireServer" or methodName == "InvokeServer" or methodName == "invokeServer")
            and remoteName == "SayMessageRequest"
		then
            local iscmd = checkmsg(n_tuple[1])
            if iscmd then
                n_tuple[1] = "."
                return game_namecall(remote, unpack(n_tuple))
            end
        end
        return game_namecall(remote, ...)
    end
end)
game_namecall = hookmetamethod(game, "__namecall", newnamecall)
