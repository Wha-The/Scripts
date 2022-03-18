local Namespace = {
    Eating1 = 8917831429,
    Eating2 = 8917833149,
    Emote1 = 8917838112,
    Emote2 = 8917839266,
    Emote3 = 8917841077,
    Emote4 = 8929856213,
    Emote5 = 8929857221,
    Emote6 = 8929857982,
    Sleeping = 8917843108,
    ArcadeMachine = 8917829232,

    RobotBoss_Idle = 9097415227,
    RobotBoss_ManiacalLaugh = 9097416382,
	RobotBoss_PointGun = 9098509179,
	RobotBoss_ShootGun = 9098551816,
    RobotBoss_Walk = 9097419547,
    RobotBoss_CannonOpenClose = 9097410505,
}

local AnimationHandler = {}
AnimationHandler.Namespace = Namespace

function AnimationHandler:PlayAnimation(anim, character, properties)
    character = character or (game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait())
    properties = properties or {}
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    assert(humanoid, "[AnimationHandler] Can't find humanoid within character!")
    local id = Namespace[anim]
    assert(id, "Can't find animation "..anim)
    local a = Instance.new("Animation")
    a.AnimationId = "rbxassetid://"..id
    
    local Animator = humanoid:FindFirstChildWhichIsA("Animator")
    if not Animator then
        Animator = Instance.new("Animator")
        Animator.Parent = humanoid
    end
    local track = Animator:LoadAnimation(a)
    if properties.Looped then
        track.Looped = true
    end
    track:Play()
    if properties.Speed then
        track:AdjustSpeed(properties.Speed)
    end
    return track
end

return AnimationHandler