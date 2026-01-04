local enemyfsm = {}
local Players = game:GetService("Players")
local ObjectOrientedRef
local gameconfig
local comms = game.ReplicatedStorage.Remotes.Comms
local FSMFuncs = {}

function enemyfsm:Setup(enemy, cfg, objectOriented, animsFSM, gConfig)
    ObjectOrientedRef = objectOriented
    gameconfig = gConfig
    enemy.ObjectOriented = objectOriented
    enemy.InitialPosition = enemy.HRP.Position
    enemy.State = "IDLE"
    enemy.TargetPlayer = nil
    enemy.AttackTimer = 0
    enemy.FSM = {}
    enemy.AnimsFSM = animsFSM
    local fsmList = { "IDLE" }
    if cfg.Type and cfg.Type.Name and cfg.Type.Variants then
        local typeData = gConfig.EnemiesTypes[cfg.Type.Name]
        if typeData and typeData.Variants then
            local variantData = typeData.Variants[cfg.Type.Variants]
            if variantData and variantData.FSM then
                fsmList = variantData.FSM
            end
        end
    end
    cfg.FSM = fsmList
    for _, stateName in ipairs(cfg.FSM) do
        if FSMFuncs[stateName] then
            enemy.FSM[stateName] = function(dt)
                if not enemy.Locked then
                    FSMFuncs[stateName](enemy, cfg, dt)
                    if enemy.AnimsFSM then
                        enemy.AnimsFSM:Update(enemy)
                    end
                end
            end
        end
    end
end

local function XZDir(from, to)
    local dir = to - from
    dir = Vector3.new(dir.X,0,dir.Z)
    local dist = dir.Magnitude
    if dist > 0 then return dir.Unit, dist end
    return Vector3.new(0,0,0), 0
end

local function RotateTowards(enemy, targetPos, dt)
    local hrp = enemy.HRP
    local dir = targetPos - hrp.Position
    dir = Vector3.new(dir.X,0,dir.Z)
    if dir.Magnitude == 0 then return end
    hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, hrp.Position + dir), math.clamp(dt*8,0,1))
end

local function MoveToTarget(enemy, targetPos)
    if ObjectOrientedRef and enemy.Model then
        ObjectOrientedRef:Fire(enemy.Model, { MoveTo = { target = targetPos, alignGround = true } })
    end
end

local function DoAttack(enemy)
    local target = enemy.TargetPlayer
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = enemy.HRP
    local targetHRP = target.Character.HumanoidRootPart
    if (targetHRP.Position - hrp.Position).Magnitude > enemy.Config.DistanceToFocus then return end
    comms:Fire({ Action="TryAttack", Enemy=enemy, Character=target.Character })
end

FSMFuncs.IDLE = function(enemy, config, dt)
    enemy.IdleTimer = (enemy.IdleTimer or 0) - dt
    local hrp = enemy.HRP
    if enemy.IdleTimer <= 0 or not enemy.IdleTarget or (hrp.Position - enemy.IdleTarget).Magnitude < 0.5 then
        local r = 4
        enemy.IdleTarget = enemy.InitialPosition + Vector3.new(math.random()*r*2-r,0,math.random()*r*2-r)
        enemy.IdleTimer = math.random(2,5)
    end
    MoveToTarget(enemy, enemy.IdleTarget)
    local closest, minDist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local d = (plr.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
            if d < config.PersecutionRange and d < minDist then
                closest, minDist = plr, d
            end
        end
    end
    enemy.TargetPlayer = closest
    if closest then
        if minDist <= config.DetectionRange then
            enemy.State = "DETECTION"
        else
            enemy.State = "PERSECUTION"
        end
    end
end

FSMFuncs.DETECTION = function(enemy, config, dt)
    local target = enemy.TargetPlayer
    local hrp = enemy.HRP
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        enemy.State="IDLE"
        return
    end
    local _, dist = XZDir(hrp.Position, target.Character.HumanoidRootPart.Position)
    if dist > config.DetectionRange then
        enemy.State = (dist <= config.PersecutionRange) and "PERSECUTION" or "IDLE"
        return
    end
    MoveToTarget(enemy, target.Character.HumanoidRootPart.Position)
    if dist <= config.DistanceToFocus then
        enemy.State="FOCUS"
    end
end

FSMFuncs.PERSECUTION = function(enemy, config, dt)
    local target = enemy.TargetPlayer
    local hrp = enemy.HRP
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        enemy.State="IDLE"
        return
    end
    local _, dist = XZDir(hrp.Position, target.Character.HumanoidRootPart.Position)
    if dist <= config.DetectionRange then
        enemy.State="DETECTION"
    elseif dist <= config.DistanceToFocus then
        enemy.State="FOCUS"
    elseif dist > config.PersecutionRange then
        enemy.State="IDLE"
    end
    MoveToTarget(enemy, target.Character.HumanoidRootPart.Position)
end

FSMFuncs.FOCUS = function(enemy, config, dt)
    local target = enemy.TargetPlayer
    local hrp = enemy.HRP
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        enemy.State="IDLE"
        return
    end
    local targetHRP = target.Character.HumanoidRootPart
    local _, dist = XZDir(hrp.Position, targetHRP.Position)
    if dist > config.PersecutionRange then
        enemy.State="IDLE"
        return
    elseif dist > config.DistanceToFocus then
        enemy.State="PERSECUTION"
        return
    end
    if ObjectOrientedRef and enemy.Model then
        ObjectOrientedRef:Fire(enemy.Model, { MoveStop=true })
    end
    RotateTowards(enemy, targetHRP.Position, dt)
    enemy.AttackTimer = math.max(0, enemy.AttackTimer - dt)
    if enemy.AttackTimer <= 0 then
        DoAttack(enemy)
        enemy.AttackTimer = config.AttackCooldown
    end
end

return enemyfsm
