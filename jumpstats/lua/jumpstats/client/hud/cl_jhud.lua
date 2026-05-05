JumpStats.JHUD = JumpStats.JHUD or {}

JumpStats.JHUD.latest_stats = JumpStats.JHUD.latest_stats or nil
JumpStats.JHUD.last_update = JumpStats.JHUD.last_update or 0
JumpStats.JHUD.initialized = JumpStats.JHUD.initialized or false

local kCenterAlign = TEXT_ALIGN_CENTER
local kFadeDelay = 0.4
local kFadeDuration = 1.6
local kFullAlpha = 255

local kColorRed = Color(255, 46, 46, 255)
local kColorOrange = Color(255, 175, 28, 255)
local kColorLightGreen = Color(104, 247, 47, 255)
local kColorGreen = Color(0, 255, 0, 255)
local kColorDarkGreen = Color(6, 210, 0, 255)
local kColorAqua = Color(0, 255, 255, 255)
local kColorPink = Color(243, 68, 252, 255)
local kColorPurple = Color(255, 0, 255, 255)

local function GetSetting(path, fallback)
  if JumpStats.Settings and JumpStats.Settings.Get then
    return JumpStats.Settings.Get(path, fallback)
  end

  return fallback
end

local function GetNumber(value, decimals)
  if JumpStats.Format and JumpStats.Format.Number then
    return JumpStats.Format.Number(value, decimals)
  end

  value = tonumber(value) or 0
  return tostring(math.Round(value, decimals or 0))
end

local function GetVelocity(stats)
  return tonumber(stats and (stats.velocity or stats.vel)) or 0
end

local function GetJSS(stats)
  if not stats then
    return "0"
  end

  if stats.jssText ~= nil then
    return tostring(stats.jssText)
  end

  if stats.jssPct ~= nil then
    return tostring(stats.jssPct)
  end

  return GetNumber(stats.jss or 0, 0)
end

local function GetSPJ(stats)
  if not stats then
    return "0"
  end

  return GetNumber(stats.strafesPerJump or stats.spj or stats.strafes or 0, 0)
end

local function BuildTextParts(stats)
  local first_line = {}
  local second_line = {}

  if GetSetting("JHUD.ShowJump", true) then
    first_line[#first_line + 1] = tostring(stats.jumps or 0)
  end

  if GetSetting("JHUD.ShowVelocity", true) then
    first_line[#first_line + 1] = tostring(math.floor(GetVelocity(stats)))
  end

  if GetSetting("JHUD.ShowSync", true) then
    first_line[#first_line + 1] = GetNumber(stats.sync or 0, 1) .. "%"
  end

  if GetSetting("JHUD.ShowJSS", true) then
    first_line[#first_line + 1] = "(" .. GetJSS(stats) .. ")"
  end

  if GetSetting("JHUD.ShowGain", true) then
    second_line[#second_line + 1] = GetNumber(stats.gain or stats.gainAvg or 0, 1) .. "%"
  end

  if GetSetting("JHUD.ShowEfficiency", true) then
    second_line[#second_line + 1] = "(" .. GetNumber(stats.efficiency or 0, 1) .. ")"
  end

  if GetSetting("JHUD.ShowSPJ", true) then
    second_line[#second_line + 1] = GetSPJ(stats)
  end

  local lines = {}

  if #first_line > 0 then
    lines[#lines + 1] = table.concat(first_line, " ")
  end

  if #second_line > 0 then
    lines[#lines + 1] = table.concat(second_line, " ")
  end

  return table.concat(lines, "\n")
end

function JumpStats.JHUD.Initialize()
  if JumpStats.JHUD.initialized then
    return
  end

  hook.Add("HUDPaint", "JumpStats.JHUD.Paint", function()
    JumpStats.JHUD.Paint()
  end)

  JumpStats.JHUD.initialized = true
end

function JumpStats.JHUD.Shutdown()
  hook.Remove("HUDPaint", "JumpStats.JHUD.Paint")
  JumpStats.JHUD.initialized = false
end

function JumpStats.JHUD.SetStats(stats)
  JumpStats.JHUD.latest_stats = JumpStats.Util.DeepCopy(stats)
  JumpStats.JHUD.last_update = CurTime()
end

function JumpStats.JHUD.Clear()
  JumpStats.JHUD.latest_stats = nil
end

function JumpStats.JHUD.ShouldDraw()
  if not GetSetting("HUD.JHUDEnabled", true) then
    return false
  end

  if not JumpStats.JHUD.latest_stats then
    return false
  end

  return JumpStats.JHUD.GetAlpha() > 0
end

function JumpStats.JHUD.GetPosition()
  return ScrW() * GetSetting("JHUD.X", 0.5), ScrH() * GetSetting("JHUD.Y", 0.35)
end

function JumpStats.JHUD.GetText()
  local stats = JumpStats.JHUD.latest_stats

  if not stats then
    return ""
  end

  if stats.prestrafe then
    return "Prestrafe: " .. tostring(math.floor(GetVelocity(stats)))
  end

  return BuildTextParts(stats)
end

function JumpStats.JHUD.GetAlpha()
  local age = CurTime() - (JumpStats.JHUD.last_update or 0)

  if age <= kFadeDelay then
    return kFullAlpha
  end

  local fade_time = math.Clamp((age - kFadeDelay) / kFadeDuration, 0, 1)
  return math.floor(kFullAlpha * (1 - fade_time))
end

function JumpStats.JHUD.GetStatsColor()
  local stats = JumpStats.JHUD.latest_stats
  local alpha = JumpStats.JHUD.GetAlpha()

  if not stats then
    return Color(255, 255, 255, alpha)
  end

  local color = nil

  if stats.prestrafe then
    if JumpStats.Format and JumpStats.Format.GetPrestrafeColor then
      color = JumpStats.Format.GetPrestrafeColor(GetVelocity(stats))
    else
      color = kColorRed
    end
  else
    if JumpStats.Format and JumpStats.Format.GetGainColor then
      color = JumpStats.Format.GetGainColor(tonumber(stats.gain or stats.gainAvg) or 0)
    else
      color = kColorRed
    end
  end

  if JumpStats.Format and JumpStats.Format.WithAlpha then
    return JumpStats.Format.WithAlpha(color, alpha)
  end

  return Color(color.r, color.g, color.b, alpha)
end

function JumpStats.JHUD.Paint()
  if not JumpStats.JHUD.ShouldDraw() then
    return
  end

  local text = JumpStats.JHUD.GetText()
  if text == "" then
    return
  end

  local x, y = JumpStats.JHUD.GetPosition()
  draw.DrawText(text, JumpStats.Fonts.GetJHUDFont(), x, y, JumpStats.JHUD.GetStatsColor(), kCenterAlign)
end
