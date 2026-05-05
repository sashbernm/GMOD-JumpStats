JumpStats.Config.kCurrentSettingsVersion = 1
JumpStats.Config.CurrentSettingsVersion = JumpStats.Config.kCurrentSettingsVersion

JumpStats.Config.kNet = {
  ClientStatsRate = 0.1,
}
JumpStats.Config.Net = JumpStats.Config.kNet

JumpStats.Config.kDefaultSettings = {
  Version = JumpStats.Config.kCurrentSettingsVersion,
  HUD = {
    JHUDEnabled = true,
    VelocityHUDEnabled = true,
    SpectatorHUDEnabled = true,
  },
  JHUD = {
    X = 0.5,
    Y = 0.35,
    Align = "center",
    Background = true,
    ShowJump = true,
    ShowVelocity = true,
    ShowGain = true,
    ShowSync = true,
    ShowJSS = true,
    ShowEfficiency = true,
    ShowSPJ = true,
  },
  VelocityHUD = {
    X = 0.5,
    Y = 0.55,
    ShowUnits = false,
  },
  SSJ = {
    Enabled = true,
    ShowJump = true,
    ShowVelocity = true,
    ShowGain = true,
    ShowSync = true,
    ShowJSS = true,
    ShowEfficiency = true,
    ShowSPJ = true,
  },
  Spectators = {
    SendStats = true,
    ReceiveStats = true,
  },
  Fonts = {
    JHUDSize = 28,
    VelocitySize = 32,
    MenuSize = 16,
  },
  Colors = {
    Text = {r = 255, g = 255, b = 255, a = 255},
    Background = {r = 0, g = 0, b = 0, a = 140},
    Good = {r = 90, g = 220, b = 90, a = 255},
    Warning = {r = 255, g = 210, b = 90, a = 255},
    Bad = {r = 255, g = 90, b = 90, a = 255},
  },
}
JumpStats.Config.DefaultSettings = JumpStats.Config.kDefaultSettings

JumpStats.Config.kThresholds = {
  Gain = {
    Good = 70,
    Warning = 30,
  },
  Sync = {
    Good = 90,
    Warning = 70,
  },
  Efficiency = {
    Good = 80,
    Warning = 50,
  },
  Velocity = {
    Good = 300,
    Warning = 250,
  },
  JSS = {
    Good = 90,
    Warning = 70,
  },
}
JumpStats.Config.Thresholds = JumpStats.Config.kThresholds

function JumpStats.Config.GetDefaults()
  return JumpStats.Util.DeepCopy(JumpStats.Config.kDefaultSettings)
end

function JumpStats.Config.GetDefault(path)
  local defaults = JumpStats.Config.GetDefaults()
  return JumpStats.Util.GetPath(defaults, path)
end

function JumpStats.Config.GetStatThresholds(stat_name)
  return JumpStats.Config.kThresholds[stat_name]
end

function JumpStats.Config.GetNetRateLimit()
  return JumpStats.Config.kNet.ClientStatsRate
end
