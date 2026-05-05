JumpStats.RunState = JumpStats.RunState or {}

JumpStats.RunState.kStateIdle = "Idle"
JumpStats.RunState.kStatePrestrafe = "Prestrafe"
JumpStats.RunState.kStateInAir = "InAir"
JumpStats.RunState.kStateLanded = "Landed"

JumpStats.RunState.state = JumpStats.RunState.state or JumpStats.RunState.kStateIdle
JumpStats.RunState.jump_count = JumpStats.RunState.jump_count or 0
JumpStats.RunState.last_reset_reason = JumpStats.RunState.last_reset_reason or nil
JumpStats.RunState.last_state_change_time = JumpStats.RunState.last_state_change_time or 0

local kStopSpeed = 5
local kTeleportDistance = 512
local kValidStates = {
  [JumpStats.RunState.kStateIdle] = true,
  [JumpStats.RunState.kStatePrestrafe] = true,
  [JumpStats.RunState.kStateInAir] = true,
  [JumpStats.RunState.kStateLanded] = true,
}

local function GetTime()
  if CurTime then
    return CurTime()
  end

  return 0
end

local function HasButton(sample, button)
  if not sample or not button then
    return false
  end

  return bit.band(tonumber(sample.buttons) or 0, button) ~= 0
end

local function SetState(state)
  if not kValidStates[state] then
    state = JumpStats.RunState.kStateIdle
  end

  if JumpStats.RunState.state == state then
    return
  end

  JumpStats.RunState.state = state
  JumpStats.RunState.last_state_change_time = GetTime()
end

function JumpStats.RunState.Initialize()
  JumpStats.RunState.Reset("initialize")
end

function JumpStats.RunState.Reset(reason)
  JumpStats.RunState.state = JumpStats.RunState.kStateIdle
  JumpStats.RunState.jump_count = 0
  JumpStats.RunState.last_reset_reason = reason or nil
  JumpStats.RunState.last_state_change_time = GetTime()
end

function JumpStats.RunState.StartPrestrafe()
  if JumpStats.RunState.IsIdle() then
    SetState(JumpStats.RunState.kStatePrestrafe)
  end
end

function JumpStats.RunState.StartJump()
  SetState(JumpStats.RunState.kStateInAir)
end

function JumpStats.RunState.Land()
  if JumpStats.RunState.IsInAir() then
    SetState(JumpStats.RunState.kStateLanded)
  end
end

function JumpStats.RunState.IsIdle()
  return JumpStats.RunState.state == JumpStats.RunState.kStateIdle
end

function JumpStats.RunState.IsPrestrafe()
  return JumpStats.RunState.state == JumpStats.RunState.kStatePrestrafe
end

function JumpStats.RunState.IsInAir()
  return JumpStats.RunState.state == JumpStats.RunState.kStateInAir
end

function JumpStats.RunState.IsLanded()
  return JumpStats.RunState.state == JumpStats.RunState.kStateLanded
end

function JumpStats.RunState.IsRunning()
  return not JumpStats.RunState.IsIdle()
end

function JumpStats.RunState.GetState()
  return JumpStats.RunState.state
end

function JumpStats.RunState.GetJumpCount()
  return JumpStats.RunState.jump_count
end

function JumpStats.RunState.GetLastResetReason()
  return JumpStats.RunState.last_reset_reason
end

function JumpStats.RunState.GetLastStateChangeTime()
  return JumpStats.RunState.last_state_change_time
end

function JumpStats.RunState.SetJumpCount(jump_count)
  JumpStats.RunState.jump_count = math.max(math.floor(tonumber(jump_count) or 0), 0)
end

function JumpStats.RunState.IncrementJumpCount()
  JumpStats.RunState.jump_count = JumpStats.RunState.jump_count + 1
  return JumpStats.RunState.jump_count
end

function JumpStats.RunState.MarkLandedIfNeeded(sample)
  if sample and sample.onGround then
    JumpStats.RunState.Land()
  end
end

function JumpStats.RunState.ShouldReset(sample)
  if type(sample) ~= "table" then
    return true, "missing sample"
  end

  if sample.moveType == MOVETYPE_NOCLIP then
    return true, "noclip"
  end

  if sample.moveType == MOVETYPE_LADDER then
    return true, "ladder"
  end

  if sample.waterLevel and sample.waterLevel >= 2 then
    return true, "water"
  end

  if sample.teleported then
    return true, "teleport"
  end

  if sample.previousPosition and sample.position then
    local distance = sample.position:Distance(sample.previousPosition)
    if distance > kTeleportDistance then
      return true, "teleport"
    end
  end

  if JumpStats.RunState.IsIdle() then
    return false, nil
  end

  local is_holding_jump = HasButton(sample, IN_JUMP)

  if sample.onGround and not is_holding_jump and JumpStats.RunState.GetJumpCount() > 0 then
    return true, "grounded"
  end

  if sample.onGround and (sample.speed2D or 0) < kStopSpeed and not is_holding_jump then
    return true, "stopped"
  end

  return false, nil
end

function JumpStats.RunState.UpdateFromSample(sample)
  local should_reset, reason = JumpStats.RunState.ShouldReset(sample)

  if should_reset then
    JumpStats.RunState.Reset(reason)
    return false, reason
  end

  if JumpStats.RunState.IsInAir() and sample and sample.onGround then
    JumpStats.RunState.Land()
  end

  if JumpStats.RunState.IsIdle() and sample and sample.onGround and (sample.speed2D or 0) >= kStopSpeed then
    JumpStats.RunState.StartPrestrafe()
  end

  return true, nil
end
