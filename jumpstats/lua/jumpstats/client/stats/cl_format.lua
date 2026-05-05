JumpStats.Format = JumpStats.Format or {}

local function GetSetting(path, fallback)
  if JumpStats.Settings and JumpStats.Settings.Get then
    return JumpStats.Settings.Get(path, fallback)
  end

  return fallback
end

local kColorRed = Color(255, 46, 46, 255)
local kColorOrange = Color(255, 175, 28, 255)
local kColorLightGreen = Color(104, 247, 47, 255)
local kColorGreen = Color(0, 255, 0, 255)
local kColorDarkGreen = Color(6, 210, 0, 255)
local kColorAqua = Color(0, 255, 255, 255)
local kColorPink = Color(243, 68, 252, 255)
local kColorPurple = Color(255, 0, 255, 255)
local kColorSSJHeader = Color(51, 245, 61, 255)
local kColorSSJNumber = Color(253, 249, 11, 255)

local function WithAlpha(color, alpha)
  return Color(color.r, color.g, color.b, alpha or color.a or 255)
end

function JumpStats.Format.Number(value, decimals)
  value = tonumber(value) or 0
  decimals = decimals or 0

  if JumpStats.Util and JumpStats.Util.Round then
    return tostring(JumpStats.Util.Round(value, decimals))
  end

  return tostring(math.Round(value, decimals))
end

function JumpStats.Format.Percent(value, decimals)
  return JumpStats.Format.Number(value, decimals or 1) .. "%"
end

function JumpStats.Format.SignedNumber(value, decimals)
  value = tonumber(value) or 0

  local prefix = ""
  if value > 0 then
    prefix = "+"
  end

  return prefix .. JumpStats.Format.Number(value, decimals or 1)
end

function JumpStats.Format.Velocity(value)
  value = tonumber(value) or 0

  local text = tostring(math.floor(value))
  if GetSetting("VelocityHUD.ShowUnits", false) then
    text = text .. " u/s"
  end

  return text
end

function JumpStats.Format.JHUD(stats)
  local rows = {}

  if not stats then
    return rows
  end

  if stats.spectatorTarget and IsValid(stats.spectatorTarget) then
    table.insert(rows, {
      label = "Player",
      value = stats.spectatorTarget:Nick(),
      color = JumpStats.Format.GetTextColor(),
    })
  end

  if stats.prestrafe then
    table.insert(rows, {
      label = "Prestrafe",
      value = JumpStats.Format.Velocity(stats.velocity),
      color = JumpStats.Format.GetVelocityColor(stats.velocity),
    })
    return rows
  end

  if GetSetting("JHUD.ShowJump", true) then
    table.insert(rows, {
      label = "Jump",
      value = tostring(stats.jumps or 0),
      color = JumpStats.Format.GetTextColor(),
    })
  end

  if GetSetting("JHUD.ShowVelocity", true) then
    table.insert(rows, {
      label = "Velocity",
      value = JumpStats.Format.Velocity(stats.velocity),
      color = JumpStats.Format.GetVelocityColor(stats.velocity),
    })
  end

  if GetSetting("JHUD.ShowGain", true) then
    table.insert(rows, {
      label = "Gain",
      value = JumpStats.Format.Percent(stats.gain, 1),
      color = JumpStats.Format.GetGainColor(stats.gain),
    })
  end

  if GetSetting("JHUD.ShowSync", true) then
    table.insert(rows, {
      label = "Sync",
      value = JumpStats.Format.Percent(stats.sync, 1),
      color = JumpStats.Format.GetSyncColor(stats.sync),
    })
  end

  if GetSetting("JHUD.ShowJSS", true) then
    table.insert(rows, {
      label = "JSS",
      value = stats.jssText or JumpStats.Format.Percent(stats.jss, 1),
      color = JumpStats.Format.GetJSSColor(stats.jss),
    })
  end

  if GetSetting("JHUD.ShowEfficiency", true) then
    table.insert(rows, {
      label = "Efficiency",
      value = JumpStats.Format.Percent(stats.efficiency, 1),
      color = JumpStats.Format.GetEfficiencyColor(stats.efficiency),
    })
  end

  if GetSetting("JHUD.ShowSPJ", true) then
    table.insert(rows, {
      label = "SPJ",
      value = JumpStats.Format.Number(stats.strafesPerJump or stats.strafes, 0),
      color = JumpStats.Format.GetTextColor(),
    })
  end

  return rows
end

function JumpStats.Format.SSJ(stats)
  local parts = {}

  table.insert(parts, kColorSSJHeader)
  table.insert(parts, "[SSJ] ")

  if not stats then
    return parts
  end

  if stats.prestrafe then
    table.insert(parts, JumpStats.Format.GetTextColor())
    table.insert(parts, "Prestrafe: ")
    table.insert(parts, kColorSSJNumber)
    table.insert(parts, JumpStats.Format.Velocity(stats.velocity))
    return parts
  end

  if GetSetting("SSJ.ShowJump", true) then
    JumpStats.Format.AddChatStat(parts, "J: ", tostring(stats.jumps or 0), kColorSSJNumber)
  end

  if GetSetting("SSJ.ShowVelocity", true) then
    JumpStats.Format.AddChatStat(parts, "Vel: ", JumpStats.Format.Velocity(stats.velocity), kColorSSJNumber)
  end

  if GetSetting("SSJ.ShowGain", true) then
    JumpStats.Format.AddChatStat(parts, "G% ", JumpStats.Format.Number(stats.gain, 1), JumpStats.Format.GetGainColor(stats.gain))
  end

  if GetSetting("SSJ.ShowSync", true) then
    JumpStats.Format.AddChatStat(parts, "S% ", JumpStats.Format.Number(stats.sync, 1), JumpStats.Format.GetSyncColor(stats.sync))
  end

  if GetSetting("SSJ.ShowJSS", true) then
    JumpStats.Format.AddChatStat(parts, "Y% ", tostring(stats.jssText or JumpStats.Format.Number(stats.jss, 1)), JumpStats.Format.GetGainColor(stats.gain))
  end

  if GetSetting("SSJ.ShowEfficiency", true) then
    JumpStats.Format.AddChatStat(parts, "E% ", JumpStats.Format.Number(stats.efficiency, 1), JumpStats.Format.GetEfficiencyColor(stats.efficiency))
  end

  if GetSetting("SSJ.ShowSPJ", true) then
    JumpStats.Format.AddChatStat(parts, "S# ", JumpStats.Format.Number(stats.strafesPerJump or stats.strafes, 0), kColorSSJNumber)
  end

  return parts
end

function JumpStats.Format.AddChatStat(parts, label, value, value_color)
  if #parts > 2 then
    table.insert(parts, JumpStats.Format.GetTextColor())
    table.insert(parts, " | ")
  end

  table.insert(parts, JumpStats.Format.GetTextColor())
  table.insert(parts, label)
  table.insert(parts, value_color or kColorSSJNumber)
  table.insert(parts, value)
end

function JumpStats.Format.AddChatPart(parts, text, color)
  if #parts > 2 then
    table.insert(parts, JumpStats.Format.GetTextColor())
    table.insert(parts, " | ")
  end

  table.insert(parts, color or JumpStats.Format.GetTextColor())
  table.insert(parts, text)
end

function JumpStats.Format.GetTextColor()
  return JumpStats.Util.ColorFromTable(GetSetting("Colors.Text", {r = 255, g = 255, b = 255, a = 255}))
end

function JumpStats.Format.GetGoodColor()
  return JumpStats.Util.ColorFromTable(GetSetting("Colors.Good", {r = 90, g = 220, b = 90, a = 255}))
end

function JumpStats.Format.GetWarningColor()
  return JumpStats.Util.ColorFromTable(GetSetting("Colors.Warning", {r = 255, g = 210, b = 90, a = 255}))
end

function JumpStats.Format.GetBadColor()
  return JumpStats.Util.ColorFromTable(GetSetting("Colors.Bad", {r = 255, g = 90, b = 90, a = 255}))
end

function JumpStats.Format.GetThresholdColor(stat_name, value)
  value = tonumber(value) or 0

  local thresholds = nil
  if JumpStats.Config and JumpStats.Config.GetStatThresholds then
    thresholds = JumpStats.Config.GetStatThresholds(stat_name)
  end

  if not thresholds then
    return JumpStats.Format.GetTextColor()
  end

  if value >= thresholds.Good then
    return JumpStats.Format.GetGoodColor()
  end

  if value >= thresholds.Warning then
    return JumpStats.Format.GetWarningColor()
  end

  return JumpStats.Format.GetBadColor()
end

function JumpStats.Format.GetVelocityColor(velocity)
  return JumpStats.Format.GetThresholdColor("Velocity", velocity or 0)
end

function JumpStats.Format.GetGainColor(gain)
  gain = tonumber(gain) or 0

  if gain >= 94 then
    return kColorPurple
  elseif gain >= 90 then
    return kColorPink
  elseif gain >= 80 then
    return kColorAqua
  elseif gain >= 77 then
    return kColorDarkGreen
  elseif gain >= 73 then
    return kColorGreen
  elseif gain >= 70 then
    return kColorLightGreen
  elseif gain >= 60 then
    return kColorOrange
  end

  return kColorRed
end

function JumpStats.Format.GetSyncColor(sync)
  sync = tonumber(sync) or 0

  if sync == 100 then
    return kColorPurple
  elseif sync >= 96 then
    return kColorAqua
  elseif sync >= 93 then
    return kColorGreen
  elseif sync >= 90 then
    return kColorLightGreen
  elseif sync >= 88 then
    return kColorOrange
  end

  return kColorRed
end

function JumpStats.Format.GetEfficiencyColor(efficiency)
  efficiency = tonumber(efficiency) or 0

  if efficiency >= 85 then
    return kColorPurple
  elseif efficiency >= 80 then
    return kColorAqua
  elseif efficiency >= 77 then
    return kColorDarkGreen
  elseif efficiency >= 73 then
    return kColorGreen
  elseif efficiency >= 70 then
    return kColorLightGreen
  elseif efficiency >= 67 then
    return kColorOrange
  end

  return kColorRed
end

function JumpStats.Format.GetJSSColor(jss)
  return JumpStats.Format.GetThresholdColor("JSS", jss or 0)
end

function JumpStats.Format.GetPrestrafeColor(velocity)
  velocity = tonumber(velocity) or 0

  if velocity >= 278 then
    return kColorPurple
  elseif velocity >= 275 then
    return kColorAqua
  elseif velocity >= 272 then
    return kColorGreen
  elseif velocity >= 268 then
    return kColorOrange
  end

  return kColorRed
end

function JumpStats.Format.WithAlpha(color, alpha)
  return WithAlpha(color, alpha)
end
