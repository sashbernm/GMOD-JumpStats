JumpStats.HUDController = JumpStats.HUDController or {}

function JumpStats.HUDController.Initialize()
  -- Output router only. Kept for stable init order.
end

function JumpStats.HUDController.OnJumpStats(stats)
  if type(stats) ~= "table" then
    return
  end

  if JumpStats.HUDController.ShouldShowJHUD() and JumpStats.JHUD and JumpStats.JHUD.SetStats then
    JumpStats.JHUD.SetStats(stats)
  end

  if JumpStats.HUDController.ShouldPrintSSJ() and JumpStats.SSJ and JumpStats.SSJ.Print then
    JumpStats.SSJ.Print(stats)
  end

  if JumpStats.HUDController.ShouldSendToSpectators() and JumpStats.Spectators and JumpStats.Spectators.SendClientStats then
    JumpStats.Spectators.SendClientStats(stats)
  end
end

function JumpStats.HUDController.OnReset(reason)
  if JumpStats.JHUD and JumpStats.JHUD.Clear then
    JumpStats.JHUD.Clear()
  end
end

function JumpStats.HUDController.OnSpectatorStats(target, stats)
  if not JumpStats.Settings.Get("HUD.SpectatorHUDEnabled", true) then
    return
  end

  if not JumpStats.Settings.Get("Spectators.ReceiveStats", true) then
    return
  end

  stats = stats or {}
  stats.spectatorTarget = target

  if JumpStats.JHUD and JumpStats.JHUD.SetStats then
    JumpStats.JHUD.SetStats(stats)
  end
end

function JumpStats.HUDController.ShouldSendToSpectators()
  return JumpStats.Settings.Get("Spectators.SendStats", true)
end

function JumpStats.HUDController.ShouldPrintSSJ()
  return JumpStats.Settings.Get("SSJ.Enabled", true)
end

function JumpStats.HUDController.ShouldShowJHUD()
  return JumpStats.Settings.Get("HUD.JHUDEnabled", true)
end
