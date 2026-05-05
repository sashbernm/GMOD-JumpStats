JumpStats.Fonts = JumpStats.Fonts or {}

JumpStats.Fonts.kNames = {
  JHUD = "JumpStats.JHUD",
  Velocity = "JumpStats.Velocity",
  Menu = "JumpStats.Menu",
}
JumpStats.Fonts.Names = JumpStats.Fonts.kNames

local function GetSetting(path, fallback)
  if JumpStats.Settings and JumpStats.Settings.Get then
    return JumpStats.Settings.Get(path, fallback)
  end

  return fallback
end

function JumpStats.Fonts.Initialize()
  JumpStats.Fonts.Create()
end

function JumpStats.Fonts.Create()
  surface.CreateFont(JumpStats.Fonts.kNames.JHUD, {
    font = "Roboto",
    size = GetSetting("Fonts.JHUDSize", 28),
    weight = 1100,
    antialias = true,
    shadow = true,
  })

  surface.CreateFont(JumpStats.Fonts.kNames.Velocity, {
    font = "Tahoma",
    size = GetSetting("Fonts.VelocitySize", 32),
    weight = 700,
    antialias = true,
  })

  surface.CreateFont(JumpStats.Fonts.kNames.Menu, {
    font = "Tahoma",
    size = GetSetting("Fonts.MenuSize", 16),
    weight = 500,
    antialias = true,
  })
end

function JumpStats.Fonts.Refresh()
  JumpStats.Fonts.Create()
end

function JumpStats.Fonts.GetJHUDFont()
  return JumpStats.Fonts.kNames.JHUD
end

function JumpStats.Fonts.GetVelocityFont()
  return JumpStats.Fonts.kNames.Velocity
end

function JumpStats.Fonts.GetMenuFont()
  return JumpStats.Fonts.kNames.Menu
end
