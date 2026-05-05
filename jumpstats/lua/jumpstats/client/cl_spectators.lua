JumpStats.Spectators = JumpStats.Spectators or {}

JumpStats.Spectators.last_client_send = JumpStats.Spectators.last_client_send or 0
JumpStats.Spectators.client_initialized = JumpStats.Spectators.client_initialized or false

function JumpStats.Spectators.InitializeClient()
  if JumpStats.Spectators.client_initialized then
    return
  end

  net.Receive(JumpStats.Net.kMessages.SpectatorStats, function()
    JumpStats.Spectators.ReceiveStats()
  end)

  JumpStats.Spectators.client_initialized = true
end

function JumpStats.Spectators.SendClientStats(stats)
  if not JumpStats.Spectators.ShouldSend() then
    return
  end

  if not JumpStats.Spectators.CanSend() then
    return
  end

  if type(stats) ~= "table" then
    return
  end

  net.Start(JumpStats.Net.kMessages.ClientStats)
  JumpStats.Net.WriteStats(stats)
  net.SendToServer()
end

function JumpStats.Spectators.ShouldSend()
  if not JumpStats.Settings.Get("Spectators.SendStats", true) then
    return false
  end

  local ply = LocalPlayer()
  if not JumpStats.Util.IsValidPlayer(ply) then
    return false
  end

  return true
end

function JumpStats.Spectators.CanSend()
  local now = CurTime()
  local min_interval = JumpStats.Config.GetNetRateLimit()

  if now - (JumpStats.Spectators.last_client_send or 0) < min_interval then
    return false
  end

  JumpStats.Spectators.last_client_send = now
  return true
end

function JumpStats.Spectators.ReceiveStats()
  if not JumpStats.Settings.Get("Spectators.ReceiveStats", true) then
    return
  end

  local target = net.ReadEntity()
  local stats = JumpStats.Net.ReadStats()

  if not JumpStats.Util.IsValidPlayer(target) then
    return
  end

  JumpStats.HUDController.OnSpectatorStats(target, stats)
end

function JumpStats.Spectators.GetCurrentTarget()
  local ply = LocalPlayer()

  if not JumpStats.Util.IsValidPlayer(ply) then
    return nil
  end

  return ply:GetObserverTarget()
end
