game:GetService("ProximityPromptService").PromptShown:Connect(function(prompt)
	prompt.HoldDuration = 0
end)