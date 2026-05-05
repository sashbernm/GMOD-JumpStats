JumpStats.SSJ = JumpStats.SSJ or {}

function JumpStats.SSJ.Initialize()
  -- This module prints on demand; it does not need hooks.
end

function JumpStats.SSJ.Print(stats)
  if not JumpStats.SSJ.ShouldPrint(stats) then
    return
  end

  local parts = JumpStats.SSJ.BuildParts(stats)
  if not parts or #parts == 0 then
    return
  end

  chat.AddText(unpack(parts))
end

function JumpStats.SSJ.ShouldPrint(stats)
  if not JumpStats.Settings.Get("SSJ.Enabled", true) then
    return false
  end

  return type(stats) == "table"
end

function JumpStats.SSJ.BuildParts(stats)
  return JumpStats.Format.SSJ(stats)
end

function JumpStats.SSJ.GetEnabledStats()
  return {
    Jump = JumpStats.Settings.Get("SSJ.ShowJump", true),
    Velocity = JumpStats.Settings.Get("SSJ.ShowVelocity", true),
    Gain = JumpStats.Settings.Get("SSJ.ShowGain", true),
    Sync = JumpStats.Settings.Get("SSJ.ShowSync", true),
    JSS = JumpStats.Settings.Get("SSJ.ShowJSS", true),
    Efficiency = JumpStats.Settings.Get("SSJ.ShowEfficiency", true),
    SPJ = JumpStats.Settings.Get("SSJ.ShowSPJ", true),
  }
end
