JumpStats.Spectators = JumpStats.Spectators or {}

JumpStats.Spectators.initialized = JumpStats.Spectators.initialized or false
JumpStats.Spectators.last_send_times = JumpStats.Spectators.last_send_times or {}

function JumpStats.Spectators.Initialize()
  if JumpStats.Spectators.initialized then
    return
  end

  net.Receive(JumpStats.Net.kMessages.ClientStats, function(length, ply)
    JumpStats.Spectators.ReceiveClientStats(ply)
  end)

  hook.Add("PlayerDisconnected", "JumpStats.Spectators.Cleanup", function(ply)
    JumpStats.Spectators.CleanupPlayer(ply)
  end)

  JumpStats.Spectators.initialized = true

  if JumpStats.logger then
    JumpStats.logger:Info("Initialized spectators")
  end
end

function JumpStats.Spectators.Shutdown()
  hook.Remove("PlayerDisconnected", "JumpStats.Spectators.Cleanup")

  JumpStats.Spectators.initialized = false
end

function JumpStats.Spectators.ReceiveClientStats(ply)
  if not JumpStats.Util.IsValidPlayer(ply) then
    return
  end

  if not JumpStats.Spectators.CanSend(ply) then
    return
  end

  local stats = JumpStats.Net.ReadStats()

  if not JumpStats.Spectators.ValidateStats(stats) then
    return
  end

  JumpStats.Spectators.BroadcastStats(ply, stats)
end

function JumpStats.Spectators.CanSend(ply)
  local now = CurTime()
  local last_send = JumpStats.Spectators.last_send_times[ply] or 0
  local min_interval = JumpStats.Config.GetNetRateLimit()

  if now - last_send < min_interval then
    return false
  end

  JumpStats.Spectators.last_send_times[ply] = now
  return true
end

function JumpStats.Spectators.ValidateStats(stats)
  if type(stats) ~= "table" then
    return false
  end

  local jumps = tonumber(stats.jumps)
  local velocity = tonumber(stats.velocity)
  local gain = tonumber(stats.gain)
  local sync = tonumber(stats.sync)
  local jss = tonumber(stats.jss)
  local efficiency = tonumber(stats.efficiency)
  local strafes = tonumber(stats.strafes)
  local strafes_per_jump = tonumber(stats.strafesPerJump)

  if not jumps or jumps < 0 or jumps > 255 then
    return false
  end

  if not velocity or velocity < 0 or velocity > 10000 then
    return false
  end

  if not gain or gain < -10000 or gain > 10000 then
    return false
  end

  if not sync or sync < 0 or sync > 100 then
    return false
  end

  if not jss or jss < -10000 or jss > 10000 then
    return false
  end

  if not efficiency or efficiency < 0 or efficiency > 1000 then
    return false
  end

  if not strafes or strafes < 0 or strafes > 255 then
    return false
  end

  if not strafes_per_jump or strafes_per_jump < 0 or strafes_per_jump > 255 then
    return false
  end

  return true
end

function JumpStats.Spectators.GetSpectators(target)
  local spectators = {}

  if not JumpStats.Util.IsValidPlayer(target) then
    return spectators
  end

  for _, ply in ipairs(player.GetHumans()) do
    if JumpStats.Spectators.IsSpectating(ply, target) then
      table.insert(spectators, ply)
    end
  end

  return spectators
end

function JumpStats.Spectators.IsSpectating(spectator, target)
  if not JumpStats.Util.IsValidPlayer(spectator) then
    return false
  end

  if not JumpStats.Util.IsValidPlayer(target) then
    return false
  end

  if spectator == target then
    return false
  end

  return spectator:GetObserverTarget() == target
end

function JumpStats.Spectators.BroadcastStats(target, stats)
  local spectators = JumpStats.Spectators.GetSpectators(target)

  for _, spectator in ipairs(spectators) do
    JumpStats.Spectators.SendStats(spectator, target, stats)
  end
end

function JumpStats.Spectators.SendStats(spectator, target, stats)
  if not JumpStats.Util.IsValidPlayer(spectator) then
    return
  end

  if not JumpStats.Util.IsValidPlayer(target) then
    return
  end

  if not JumpStats.Spectators.ValidateStats(stats) then
    return
  end

  net.Start(JumpStats.Net.kMessages.SpectatorStats)
  net.WriteEntity(target)
  JumpStats.Net.WriteStats(stats)
  net.Send(spectator)
end

function JumpStats.Spectators.CleanupPlayer(ply)
  JumpStats.Spectators.last_send_times[ply] = nil
end
