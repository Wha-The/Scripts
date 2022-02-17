local commands = {}
local loadscript = function(scripturl)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Wha-The/Scripts/main/"..scripturl..".lua"))()
end
commands.r = function(scripturl)
    loadscript(scripturl)
end
commands.spy = function()
    loadscript("simplespyv2")
end


local bindable = Instance.new("BindableFunction")
bindable.Name = "__rx56"
bindable.Parent = game:GetService("Chat")
bindable.OnInvoke = function(msg, ChatWindow, ChatSettings)
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

local catchChat = Instance.new("ModuleScript")
catchChat.Parent = game:GetService("Chat"):WaitForChild("ClientChatModules"):WaitForChild("CommandModules")
catchChat.Name = "Process"
catchChat.Source = [[
    local StarterGui = game:GetService("StarterGui")
    local util = require(script.Parent:WaitForChild("Util"))
    
    local b = game:GetService("Chat"):WaitForChild("__rx56")
    function ProcessMessage(message, ChatWindow, ChatSettings)
        print(message)
        return b:Invoke(message, ChatWindow, ChatSettings)
    end
    
    return {
        [util.KEY_COMMAND_PROCESSOR_TYPE] = util.COMPLETED_MESSAGE_PROCESSOR,
        [util.KEY_PROCESSOR_FUNCTION] = ProcessMessage
    }
]]