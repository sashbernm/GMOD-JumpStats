JumpStats.Calculator = JumpStats.Calculator or {}

local kMaxAccelerateSpeed = 32.8
local kDefaultTickInterval = 0.015

local function NewState()
  return {
    active = false,
    jump_start_speed = 0,
    current_speed = 0,
    max_speed = 0,
    jumps = 0,
    strafes = 0,
    gain_samples = {},
    sync_good_ticks = 0,
    sync_total_ticks = 0,
    distance = Vector(0, 0, 0),
    trajectory = 0,
    jss_pct_total = 0,
    jss_abs_total = 0,
    jss_total = 0,
    previous_sample = nil,
    latest_sample = nil,
  }
end

local function GetTickInterval()
  if engine and engine.TickInterval then
    return engine.TickInterval()
  end

  return kDefaultTickInterval
end

local function HasButton(sample, key)
  if not sample or not key then
    return false
  end

  return bit.band(tonumber(sample.buttons) or 0, key) ~= 0
end

local function Round(value, decimals)
  if JumpStats.Util and JumpStats.Util.Round then
    return JumpStats.Util.Round(value, decimals)
  end

  return math.Round(value, decimals or 0)
end

JumpStats.Calculator.state = JumpStats.Calculator.state or NewState()

function JumpStats.Calculator.Initialize()
  JumpStats.Calculator.Reset()
end

function JumpStats.Calculator.Reset()
  JumpStats.Calculator.state = NewState()
end

function JumpStats.Calculator.ResetJumpSpecificStats()
  local jumps = JumpStats.RunState and JumpStats.RunState.GetJumpCount and JumpStats.RunState.GetJumpCount() or 0
  JumpStats.Calculator.state = NewState()
  JumpStats.Calculator.state.jumps = jumps
end

function JumpStats.Calculator.StartJump(sample)
  local state = NewState()

  state.active = true
  state.jumps = JumpStats.RunState.GetJumpCount()

  if sample then
    state.jump_start_speed = sample.speed2D or 0
    state.current_speed = sample.speed2D or 0
    state.max_speed = sample.speed2D or 0
    state.previous_sample = sample
    state.latest_sample = sample
  end

  JumpStats.Calculator.state = state
end

function JumpStats.Calculator.Update(sample)
  local state = JumpStats.Calculator.state

  if not state or not state.active or not sample then
    return
  end

  local previous_sample = state.latest_sample or state.previous_sample or sample

  state.previous_sample = previous_sample
  state.latest_sample = sample
  state.current_speed = sample.speed2D or 0
  state.max_speed = math.max(state.max_speed or 0, sample.speed2D or 0)
  state.jumps = JumpStats.RunState.GetJumpCount()

  table.insert(state.gain_samples, JumpStats.Calculator.CalculateGain(sample))
  JumpStats.Calculator.AccumulateSync(sample)
  JumpStats.Calculator.AccumulateEfficiency(sample)
  JumpStats.Calculator.AccumulateJSS(sample)
end

function JumpStats.Calculator.FinishJump(sample)
  if sample then
    JumpStats.Calculator.Update(sample)
  end

  return JumpStats.Calculator.GetFinalStats()
end

function JumpStats.Calculator.AddStrafe()
  local state = JumpStats.Calculator.state

  if not state then
    return 0
  end

  state.strafes = (state.strafes or 0) + 1
  return state.strafes
end

function JumpStats.Calculator.CalculateGain(sample)
  if not sample or not sample.wishDirection then
    return 0
  end

  local wish_speed = tonumber(sample.wishSpeed) or 0
  local max_speed = tonumber(sample.maxSpeed) or 0

  if max_speed ~= 0 and wish_speed > max_speed then
    wish_speed = max_speed
  end

  if wish_speed == 0 then
    return 0
  end

  local wishspd = math.min(wish_speed, kMaxAccelerateSpeed)
  local velocity = sample.velocity2D or sample.absoluteVelocity or Vector(0, 0, 0)
  local current_gain = velocity:Dot(sample.wishDirection)

  if current_gain == 0 or current_gain >= kMaxAccelerateSpeed then
    return 0
  end

  return ((wishspd - math.abs(current_gain)) / wishspd) * 100
end

function JumpStats.Calculator.AccumulateSync(sample)
  local state = JumpStats.Calculator.state
  local angle_diff = tonumber(sample.angleDiff or sample.yawDiff) or 0

  if angle_diff == 0 then
    return
  end

  local left = HasButton(sample, IN_MOVELEFT)
  local right = HasButton(sample, IN_MOVERIGHT)

  state.sync_total_ticks = state.sync_total_ticks + 1

  if angle_diff < 0 and left and not right then
    state.sync_good_ticks = state.sync_good_ticks + 1
    return
  end

  if angle_diff > 0 and not left and right then
    state.sync_good_ticks = state.sync_good_ticks + 1
  end
end

function JumpStats.Calculator.AccumulateEfficiency(sample)
  local state = JumpStats.Calculator.state
  local velocity = sample.absoluteVelocity or sample.velocity or Vector(0, 0, 0)
  local lagged_movement = tonumber(sample.laggedMovement) or 1
  local dist = velocity * GetTickInterval() * lagged_movement

  state.trajectory = (state.trajectory or 0) + dist:Length2D()
  state.distance:Add(dist)
end

function JumpStats.Calculator.GetOptimalYaw(speed, max_velocity, angle_diff)
  speed = tonumber(speed) or 0
  max_velocity = tonumber(max_velocity) or kMaxAccelerateSpeed
  angle_diff = tonumber(angle_diff) or 0

  local yaw = math.abs(angle_diff)
  local perfect_yaw = 0

  if speed ~= 0 then
    perfect_yaw = math.deg(math.atan(max_velocity / speed))
  end

  if perfect_yaw == 0 then
    return 0, yaw, perfect_yaw
  end

  return yaw / perfect_yaw, yaw, perfect_yaw
end

function JumpStats.Calculator.JSSToPercent(optimal_ratio)
  return 1 - math.abs((tonumber(optimal_ratio) or 0) - 1)
end

function JumpStats.Calculator.AccumulateJSS(sample)
  local state = JumpStats.Calculator.state
  local optimal_ratio = JumpStats.Calculator.GetOptimalYaw(
      sample.speed2D or 0,
      kMaxAccelerateSpeed,
      sample.angleDiff or 0)

  state.jss_pct_total = state.jss_pct_total + JumpStats.Calculator.JSSToPercent(optimal_ratio)
  state.jss_abs_total = state.jss_abs_total + optimal_ratio
  state.jss_total = state.jss_total + 1
end

function JumpStats.Calculator.CalculateSync()
  local state = JumpStats.Calculator.state

  if not state or (state.sync_total_ticks or 0) <= 0 then
    return 0
  end

  return Round((state.sync_good_ticks / state.sync_total_ticks) * 100, 2)
end

function JumpStats.Calculator.CalculateGainAverage()
  local state = JumpStats.Calculator.state
  local average = JumpStats.Util.TableAverage(state.gain_samples)

  return Round(JumpStats.Util.Clamp(average, 0, 100), 2)
end

function JumpStats.Calculator.CalculateJSS()
  local state = JumpStats.Calculator.state

  if not state or (state.jss_total or 0) <= 0 then
    return 0, "0"
  end

  local jss_pct = state.jss_pct_total / state.jss_total
  local jss_abs = state.jss_abs_total / state.jss_total
  local percent = jss_pct * 100
  local absolute_percent = jss_abs * 100

  return Round(percent, 2), JumpStats.Calculator.FormatJSS(percent, absolute_percent)
end

function JumpStats.Calculator.FormatJSS(percent, absolute_percent)
  local display_percent = math.Round(math.abs(percent or 0))
  local display_abs = math.Round(math.abs(absolute_percent or 0))

  if display_percent > 97 then
    return "✓" .. tostring(display_percent)
  end

  if display_abs >= 100 then
    return "+" .. tostring(display_percent)
  end

  return "-" .. tostring(math.floor(display_percent))
end

function JumpStats.Calculator.CalculateEfficiency(gain_average)
  local state = JumpStats.Calculator.state

  if not state or (state.trajectory or 0) <= 0 then
    return 0
  end

  local distance_2d = state.distance:Length2D()
  local efficiency = (distance_2d / state.trajectory) * (tonumber(gain_average) or 0)

  return math.max(Round(efficiency, 2), 0)
end

function JumpStats.Calculator.CalculateSPJ()
  local state = JumpStats.Calculator.state

  if not state then
    return 0
  end

  return state.strafes or 0
end

function JumpStats.Calculator.GetCurrentStats()
  local state = JumpStats.Calculator.state or NewState()
  local gain_average = JumpStats.Calculator.CalculateGainAverage()
  local jss, jss_text = JumpStats.Calculator.CalculateJSS()

  return {
    jumps = JumpStats.RunState.GetJumpCount(),
    velocity = math.floor(state.current_speed or 0),
    maxVelocity = math.floor(state.max_speed or 0),
    gain = gain_average,
    sync = JumpStats.Calculator.CalculateSync(),
    jss = jss,
    jssText = jss_text,
    efficiency = JumpStats.Calculator.CalculateEfficiency(gain_average),
    strafes = state.strafes or 0,
    strafesPerJump = JumpStats.Calculator.CalculateSPJ(),
    prestrafe = false,
  }
end

function JumpStats.Calculator.GetFinalStats()
  return JumpStats.Util.DeepCopy(JumpStats.Calculator.GetCurrentStats())
end

function JumpStats.Calculator.BuildPrestrafeStats(sample)
  local speed = 0

  if sample then
    speed = sample.speed2D or 0
  end

  return {
    jumps = JumpStats.RunState.GetJumpCount(),
    velocity = math.floor(speed),
    maxVelocity = math.floor(speed),
    gain = 0,
    sync = 0,
    jss = 0,
    jssText = "0",
    efficiency = 0,
    strafes = 0,
    strafesPerJump = 0,
    prestrafe = true,
  }
end
