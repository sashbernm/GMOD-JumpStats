JumpStats.Tracker = JumpStats.Tracker or {}

JumpStats.Tracker.initialized = JumpStats.Tracker.initialized or false
JumpStats.Tracker.last_sample = JumpStats.Tracker.last_sample or nil

local kMinimumPrestrafeSpeed = 5

local function HasButton(sample, key)
  if not sample or not key then
    return false
  end

  return bit.band(tonumber(sample.buttons) or 0, key) ~= 0
end

local function IsFirstPrediction()
  if JumpStats.Util and JumpStats.Util.IsFirstPrediction then
    return JumpStats.Util.IsFirstPrediction()
  end

  if IsFirstTimePredicted then
    return IsFirstTimePredicted()
  end

  return true
end

function JumpStats.Tracker.Initialize()
  if JumpStats.Tracker.initialized then
    return
  end

  hook.Add("SetupMove", "JumpStats.Tracker.SetupMove", function(ply, move_data, command)
    JumpStats.Tracker.OnSetupMove(ply, move_data, command)
  end)

  hook.Add("OnPlayerJump", "JumpStats.Tracker.OnPlayerJump", function(ply, velocity)
    JumpStats.Tracker.OnPlayerJump(ply, velocity)
  end)

  hook.Add("KeyPress", "JumpStats.Tracker.KeyPress", function(ply, key)
    JumpStats.Tracker.OnKeyPress(ply, key)
  end)

  JumpStats.Tracker.initialized = true
end

function JumpStats.Tracker.Shutdown()
  hook.Remove("SetupMove", "JumpStats.Tracker.SetupMove")
  hook.Remove("OnPlayerJump", "JumpStats.Tracker.OnPlayerJump")
  hook.Remove("KeyPress", "JumpStats.Tracker.KeyPress")

  JumpStats.Tracker.initialized = false
end

function JumpStats.Tracker.OnSetupMove(ply, move_data, command)
  if not JumpStats.Tracker.ShouldTrack(ply) then
    return
  end

  if not IsFirstPrediction() then
    return
  end

  local sample = JumpStats.Sampler.Sample(ply, move_data, command)
  if not sample then
    return
  end

  JumpStats.Tracker.last_sample = sample

  local should_reset, reason = JumpStats.RunState.ShouldReset(sample)
  if should_reset then
    JumpStats.Tracker.Reset(reason)
    return
  end

  JumpStats.VelocityHUD.Update(sample)

  if JumpStats.RunState.GetJumpCount() <= 0 and not sample.onGround and HasButton(sample, IN_JUMP) then
    JumpStats.RunState.IncrementJumpCount()
    JumpStats.RunState.StartJump()
    JumpStats.Calculator.StartJump(sample)
    JumpStats.Tracker.DispatchStats(JumpStats.Calculator.BuildPrestrafeStats(sample))
    return
  end

  if JumpStats.RunState.IsIdle() and sample.onGround and (sample.speed2D or 0) > kMinimumPrestrafeSpeed then
    JumpStats.RunState.StartPrestrafe()
  end

  if JumpStats.RunState.IsInAir() then
    JumpStats.Calculator.Update(sample)
  end

  if JumpStats.RunState.IsInAir() and sample.onGround then
    JumpStats.RunState.Land()
  end
end

function JumpStats.Tracker.OnPlayerJump(ply, velocity)
  if not JumpStats.Tracker.ShouldTrack(ply) then
    return
  end

  if not IsFirstPrediction() then
    return
  end

  local sample = JumpStats.Tracker.last_sample
  if not sample then
    return
  end

  local previous_jump_count = JumpStats.RunState.GetJumpCount()
  JumpStats.RunState.IncrementJumpCount()

  if previous_jump_count <= 0 then
    JumpStats.RunState.StartJump()
    JumpStats.Calculator.StartJump(sample)
    JumpStats.Tracker.DispatchStats(JumpStats.Calculator.BuildPrestrafeStats(sample))
    return
  end

  local stats = JumpStats.Tracker.FinalizeJump(sample)
  JumpStats.Tracker.DispatchStats(stats)

  JumpStats.RunState.StartJump()
  JumpStats.Calculator.StartJump(sample)
end

function JumpStats.Tracker.OnKeyPress(ply, key)
  if not JumpStats.Tracker.ShouldTrack(ply) then
    return
  end

  if not IsFirstPrediction() then
    return
  end

  if not JumpStats.RunState.IsInAir() then
    return
  end

  if key == IN_MOVELEFT or key == IN_MOVERIGHT then
    JumpStats.Calculator.AddStrafe()
  end
end

function JumpStats.Tracker.ShouldTrack(ply)
  if not JumpStats.Util.IsValidPlayer(ply) then
    return false
  end

  if ply ~= LocalPlayer() then
    return false
  end

  if not ply:Alive() then
    return false
  end

  return true
end

function JumpStats.Tracker.Reset(reason)
  if JumpStats.Calculator and JumpStats.Calculator.Reset then
    JumpStats.Calculator.Reset()
  end

  if JumpStats.RunState and JumpStats.RunState.Reset then
    JumpStats.RunState.Reset(reason)
  end

  if JumpStats.HUDController and JumpStats.HUDController.OnReset then
    JumpStats.HUDController.OnReset(reason)
  end

  if JumpStats.VelocityHUD and JumpStats.VelocityHUD.Clear then
    JumpStats.VelocityHUD.Clear()
  end
end

function JumpStats.Tracker.FinalizeJump(sample)
  return JumpStats.Calculator.FinishJump(sample or JumpStats.Tracker.last_sample)
end

function JumpStats.Tracker.DispatchStats(stats)
  if not stats then
    return
  end

  JumpStats.HUDController.OnJumpStats(stats)
end
