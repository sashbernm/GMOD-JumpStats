JumpStats.VelocityHUD = JumpStats.VelocityHUD or {}

JumpStats.VelocityHUD.current_velocity = JumpStats.VelocityHUD.current_velocity or 0
JumpStats.VelocityHUD.previous_velocity = JumpStats.VelocityHUD.previous_velocity or 0
JumpStats.VelocityHUD.last_change_time = JumpStats.VelocityHUD.last_change_time or 0
JumpStats.VelocityHUD.initialized = JumpStats.VelocityHUD.initialized or false

local kNeutralAfterSeconds = 0.05

local function GetSetting(path, fallback)
  if JumpStats.Settings and JumpStats.Settings.Get then
    return JumpStats.Settings.Get(path, fallback)
  end

  return fallback
end

function JumpStats.VelocityHUD.Initialize()
  if JumpStats.VelocityHUD.initialized then
    return
  end

  hook.Add("HUDPaint", "JumpStats.VelocityHUD.Paint", function()
    JumpStats.VelocityHUD.Paint()
  end)

  JumpStats.VelocityHUD.initialized = true
end

function JumpStats.VelocityHUD.Shutdown()
  hook.Remove("HUDPaint", "JumpStats.VelocityHUD.Paint")
  JumpStats.VelocityHUD.initialized = false
end

function JumpStats.VelocityHUD.Update(sample)
  if not sample then
    return
  end

  local velocity = math.floor(sample.speed2D or 0)

  if velocity ~= JumpStats.VelocityHUD.current_velocity then
    JumpStats.VelocityHUD.previous_velocity = JumpStats.VelocityHUD.current_velocity or 0
    JumpStats.VelocityHUD.current_velocity = velocity
    JumpStats.VelocityHUD.last_change_time = CurTime()
  end
end

function JumpStats.VelocityHUD.Clear()
  JumpStats.VelocityHUD.current_velocity = 0
  JumpStats.VelocityHUD.previous_velocity = 0
end

function JumpStats.VelocityHUD.ShouldDraw()
  if not GetSetting("HUD.VelocityHUDEnabled", true) then
    return false
  end

  local ply = LocalPlayer()
  if not JumpStats.Util.IsValidPlayer(ply) then
    return false
  end

  return (JumpStats.VelocityHUD.current_velocity or 0) > 0
end

function JumpStats.VelocityHUD.Paint()
  if not JumpStats.VelocityHUD.ShouldDraw() then
    return
  end

  local x, y = JumpStats.VelocityHUD.GetPosition()
  local text = JumpStats.VelocityHUD.GetVelocityText()
  local color = JumpStats.VelocityHUD.GetVelocityColor()
  local font = JumpStats.Fonts.GetVelocityFont()

  draw.SimpleText(text, font, x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function JumpStats.VelocityHUD.GetPosition()
  return ScrW() * GetSetting("VelocityHUD.X", 0.5), ScrH() * GetSetting("VelocityHUD.Y", 0.55)
end

function JumpStats.VelocityHUD.GetVelocityText()
  return JumpStats.Format.Velocity(JumpStats.VelocityHUD.current_velocity)
end

function JumpStats.VelocityHUD.GetVelocityColor()
  local current_velocity = JumpStats.VelocityHUD.current_velocity or 0
  local previous_velocity = JumpStats.VelocityHUD.previous_velocity or current_velocity

  if CurTime() - (JumpStats.VelocityHUD.last_change_time or 0) > kNeutralAfterSeconds then
    return JumpStats.Format.GetTextColor()
  end

  if current_velocity > previous_velocity then
    return Color(100, 190, 255)
  end

  if current_velocity < previous_velocity then
    return JumpStats.Format.GetBadColor()
  end

  return JumpStats.Format.GetTextColor()
end
