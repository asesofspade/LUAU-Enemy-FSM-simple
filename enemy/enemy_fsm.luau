local enemyfsm = {}
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local comms = game.ReplicatedStorage.Remotes.Comms

local FSMFuncs = {}
local ObjectOrientedRef

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
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude == 0 then return end

    local targetCF = CFrame.new(hrp.Position, hrp.Position + dir)
    hrp.CFrame = hrp.CFrame:Lerp(targetCF, math.clamp(dt * 8, 0, 1))
end

local function DoAttack(enemy, config)
    local hrp = enemy.HRP

    local attackPart = Instance.new("Part")
    attackPart.Size = Vector3.new(5,5,9)
    attackPart.Transparency = 0.5
    attackPart.Anchored = true
    attackPart.CanCollide = false
    attackPart.CFrame = hrp.CFrame * CFrame.new(0,0,-4)
    attackPart.Parent = workspace

    local hitboxParts = {}
    for _, plr in pairs(Players:GetPlayers()) do
        local char = plr.Character
        if char and char ~= enemy.Model then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") and string.match(part.Name, "Hitbox") then
                    table.insert(hitboxParts, part)
                end
            end
        end
    end

    if #hitboxParts == 0 then
        Debris:AddItem(attackPart, 0.15)
        return
    end

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = hitboxParts

    local overlaps = workspace:GetPartBoundsInBox(attackPart.CFrame, attackPart.Size, params)

    local hitCharacters = {}
    for _, part in pairs(overlaps) do
        local character = part:FindFirstAncestorOfClass("Model")
        if character and character:FindFirstChildOfClass("Humanoid") and not hitCharacters[character] then
            hitCharacters[character] = true
            comms:Fire("ApplyDamage", config.Damage, character, enemy.Model)
        end
    end

    Debris:AddItem(attackPart, 0.15)
end

local function MoveToTarget(enemy, targetPos)
    if ObjectOrientedRef and enemy.Model then
        ObjectOrientedRef:Fire(enemy.Model, {
            MoveTo = {
                target = targetPos,
                alignGround = true
            }
        })
    end
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
        enemy.State = "IDLE"
        return
    end
    local dir, dist = XZDir(hrp.Position, target.Character.HumanoidRootPart.Position)
    if dist > config.DetectionRange then
        enemy.State = (dist <= config.PersecutionRange) and "PERSECUTION" or "IDLE"
        return
    end
    MoveToTarget(enemy, target.Character.HumanoidRootPart.Position)
    if dist <= config.DistanceToFocus then enemy.State = "FOCUS" end
end

FSMFuncs.PERSECUTION = function(enemy, config, dt)
    local target = enemy.TargetPlayer
    local hrp = enemy.HRP
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        enemy.State = "IDLE"
        return
    end
    local dir, dist = XZDir(hrp.Position, target.Character.HumanoidRootPart.Position)
    if dist <= config.DetectionRange then
        enemy.State = "DETECTION"
        return
    elseif dist <= config.DistanceToFocus then
        enemy.State = "FOCUS"
        return
    elseif dist > config.PersecutionRange then
        enemy.State = "IDLE"
        return
    end
    MoveToTarget(enemy, target.Character.HumanoidRootPart.Position)
end

FSMFuncs.FOCUS = function(enemy, config, dt)
    local target = enemy.TargetPlayer
    local hrp = enemy.HRP
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        enemy.State = "IDLE"
        return
    end

    local targetHRP = target.Character.HumanoidRootPart
    local dir, dist = XZDir(hrp.Position, targetHRP.Position)

    if dist > config.PersecutionRange then
        enemy.State = "IDLE"
        return
    elseif dist > config.DistanceToFocus then
        enemy.State = "PERSECUTION"
        return
    end

    if ObjectOrientedRef and enemy.Model then
        ObjectOrientedRef:Fire(enemy.Model, { MoveStop = true })
    end

    RotateTowards(enemy, targetHRP.Position, dt)

    enemy.AttackTimer = math.max(0, enemy.AttackTimer - dt)
    if enemy.AttackTimer <= 0 then
        if enemy.AnimsFSM then
            enemy.AnimsFSM:PlayAttack(enemy) 
        end
        
        task.delay(0.5, function()
            DoAttack(enemy, config)
        end)
        
        enemy.AttackTimer = config.AttackCooldown
    end

end


function enemyfsm:Setup(enemy, config, objectOriented, animsFSM)
    ObjectOrientedRef = objectOriented
    enemy.InitialPosition = enemy.HRP.Position
    enemy.State = "IDLE"
    enemy.TargetPlayer = nil
    enemy.AttackTimer = 0
    enemy.FSM = {}
    enemy.AnimsFSM = animsFSM
    for _, stateName in ipairs(config.FSM) do
        if FSMFuncs[stateName] then
            enemy.FSM[stateName] = function(dt)
                FSMFuncs[stateName](enemy, config, dt)
                if enemy.AnimsFSM then
                    enemy.AnimsFSM:Update(enemy)
                end
            end
        end
    end
end

return enemyfsm
