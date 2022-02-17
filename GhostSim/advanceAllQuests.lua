local uis = game:GetService("UserInputService")
uis.InputBegan:Connect(function(input, gP)
if gP then return end
if input.KeyCode == Enum.KeyCode.N then
    for i=1,150,1 do
        game:GetService("ReplicatedStorage").Network.ToServer.Requests.AdvanceQuest:FireServer(i)
    end
end
end)