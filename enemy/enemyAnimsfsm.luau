local enemyAnimsfsm = {}

local function getAnimator(enemy)
    local animator = enemy.Humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = enemy.Humanoid
    end
    return animator
end

local function loadTrack(enemy, animId)
    enemy._animCache = enemy._animCache or {}

    if not enemy._animCache[animId] then
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        enemy._animCache[animId] = anim
    end

    return getAnimator(enemy):LoadAnimation(enemy._animCache[animId])
end

local function stopAllTracks(enemy)
    if not enemy.Tracks then return end
    for i = #enemy.Tracks, 1, -1 do
        local t = enemy.Tracks[i]
        if t then
            t:Stop(0.1)
            t:Destroy()
        end
        table.remove(enemy.Tracks, i)
    end
end

function enemyAnimsfsm:GetDesired(enemy)
    if enemy._dead then return "Death" end

    local state = enemy.State
    if state == "IDLE" then
        if (enemy.HRP.Position - (enemy.LastPosition or enemy.HRP.Position)).Magnitude > 0.1 then
            return "Walk"
        end
        return "Idle"
    elseif state == "DETECTION" then
        return "Walk"
    elseif state == "PERSECUTION" then
        return "Run"
    elseif state == "FOCUS" then
        return "Idle"
    end

    return "Idle"
end

function enemyAnimsfsm:Update(enemy)
    if enemy._dead then return end
    if enemy._instantAnimPlaying then return end

    enemy.Tracks = enemy.Tracks or {}

    local desired = self:GetDesired(enemy)
    if desired ~= enemy.LastAnim then
        local animId = enemy.Config.Animations[desired]
        if animId then
            stopAllTracks(enemy)
            local track = loadTrack(enemy, animId)
            track.Priority = Enum.AnimationPriority.Movement
            track:Play(0.15)
            table.insert(enemy.Tracks, track)
        end
        enemy.LastAnim = desired
    end

    enemy.LastPosition = enemy.HRP.Position
end

local function playInstant(enemy, key)
    if enemy._instantAnimPlaying then return end

    local animId = enemy.Config.Animations[key]
    if not animId then return end

    stopAllTracks(enemy)

    enemy._instantAnimPlaying = true
    enemy.LastAnim = nil

    local track = loadTrack(enemy, animId)
    track.Priority = Enum.AnimationPriority.Action
    track.Looped = false
    track:Play(0.05)

    enemy.Tracks = enemy.Tracks or {}
    table.insert(enemy.Tracks, track)

    track.Stopped:Once(function()
        enemy._instantAnimPlaying = false
        enemy.LastAnim = nil
    end)
end

function enemyAnimsfsm:PlayAttack(enemy)
    if enemy._dead then return end
    playInstant(enemy, "Attack")
end

function enemyAnimsfsm:PlayHit(enemy)
    if enemy._dead then return end
    playInstant(enemy, "Hit")
end

function enemyAnimsfsm:PlayDeath(enemy)
    playInstant(enemy, "Death")
end

return enemyAnimsfsm
