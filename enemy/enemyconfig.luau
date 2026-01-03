local enemyconfig = {}

enemyconfig.Types = {
    Skeleton = {
        Animations = {
            Idle = "rbxassetid://"..83404028575145,
            Walk = "rbxassetid://"..129465674915225,
            Run = "rbxassetid://"..124299496401916,
            Attack = "rbxassetid://"..90647676016211,
        },
        Weapons = {},
        Damage = 20,
        DistanceToFocus = 8,
        AttackCooldown = 1.5,
        DetectionRange = 20,
        PersecutionRange = 35,
        WalkSpeed = {
            Idle = 15,
            Walk = 50,
            Run = 70,
            Focus = 0,
        },
        FSM = { "IDLE", "DETECTION", "PERSECUTION", "FOCUS" }
    }
}

return enemyconfig
