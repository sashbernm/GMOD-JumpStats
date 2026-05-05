JumpStats.Net.kMessages = {
  ClientStats = "JumpStats.ClientStats",
  SpectatorStats = "JumpStats.SpectatorStats",
}

JumpStats.Net.kBits = {
  Jumps = 16,
  Velocity = 16,
  Strafes = 8,
}

function JumpStats.Net.Register()
  if not SERVER then
    JumpStats.logger:Warn("Attempted to call JS.Net.Register in CLIENT")
    return
  end

  for _, message_name in pairs(JumpStats.Net.kMessages) do
    util.AddNetworkString(message_name)
  end
end

function JumpStats.Net.WriteStats(stats)
  stats = stats or {}

  net.WriteUInt(JumpStats.Net.ClampUInt(stats.jumps, 0, 255), JumpStats.Net.kBits.Jumps)

  net.WriteUInt(
      JumpStats.Net.ClampUInt(math.floor(stats.velocity or 0), 0, 65535),
      JumpStats.Net.kBits.Velocity)

  net.WriteFloat(tonumber(stats.gain) or 0)
  net.WriteFloat(tonumber(stats.sync) or 0)
  net.WriteFloat(tonumber(stats.jss) or 0)
  net.WriteFloat(tonumber(stats.efficiency) or 0)

  net.WriteUInt(JumpStats.Net.ClampUInt(stats.strafes, 0, 255), JumpStats.Net.kBits.Strafes)

  net.WriteFloat(tonumber(stats.strafesPerJump) or 0)
end

function JumpStats.Net.ReadStats()
  local stats = {}

  stats.jumps = net.ReadUInt(JumpStats.Net.kBits.Jumps)
  stats.velocity = net.ReadUInt(JumpStats.Net.kBits.Velocity)

  stats.gain = net.ReadFloat()
  stats.sync = net.ReadFloat()
  stats.jss = net.ReadFloat()
  stats.efficiency = net.ReadFloat()

  stats.strafes = net.ReadUInt(JumpStats.Net.kBits.Strafes)
  stats.strafesPerJump = net.ReadFloat()

  return stats
end

function JumpStats.Net.ClampUInt(value, min_value, max_value)
  value = tonumber(value) or 0
  value = math.floor(value)

  if JumpStats.Util and JumpStats.Util.Clamp then
    return JumpStats.Util.Clamp(value, min_value, max_value)
  end

  return math.max(min_value, math.min(max_value, value))
end
