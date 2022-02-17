for i=0, -50, -1 do
game:GetService("ReplicatedStorage").Network.ToServer.Requests.AdvanceQuest:FireServer(i)
end