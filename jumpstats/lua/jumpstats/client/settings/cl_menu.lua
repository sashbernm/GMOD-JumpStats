JumpStats.Menu = JumpStats.Menu or {}

local kSaveDebounceId = "JumpStats.Menu.SaveDebounce"

local kTheme = {
  Background = Color(12, 14, 18, 245),
  Surface = Color(20, 23, 30, 255),
  SurfaceAlt = Color(27, 31, 40, 255),
  SurfaceHover = Color(35, 40, 52, 255),
  Stroke = Color(52, 59, 73, 255),
  StrokeSoft = Color(37, 42, 53, 255),
  Text = Color(238, 241, 247, 255),
  TextMuted = Color(151, 160, 176, 255),
  TextFaint = Color(98, 106, 122, 255),
  Accent = Color(80, 155, 255, 255),
  AccentDim = Color(30, 75, 135, 255),
  AccentSoft = Color(27, 48, 80, 255),
  Danger = Color(235, 95, 95, 255),
  Success = Color(95, 215, 145, 255),
  Warning = Color(245, 190, 80, 255),
}

local kSections = {
  {
    id = "hud",
    title = "HUD",
    subtitle = "Control the visible JumpStats display modules.",
    options = {
      {kind = "toggle", path = "HUD.JHUDEnabled", label = "Jump HUD", note = "Show jump, gain, sync, efficiency, and related stats."},
      {kind = "toggle", path = "HUD.VelocityHUDEnabled", label = "Velocity HUD", note = "Show current movement speed."},
      {kind = "toggle", path = "HUD.SpectatorHUDEnabled", label = "Spectator HUD", note = "Show stats while spectating another player."},
    },
  },
  {
    id = "jhud",
    title = "Jump HUD",
    subtitle = "Tune the jump-stat panel content and placement.",
    options = {
      {kind = "toggle", path = "JHUD.Background", label = "Background panel", note = "Draw a subtle backing panel behind jump stats."},
      {kind = "toggle", path = "JHUD.ShowJump", label = "Jump count", note = "Show the current jump number."},
      {kind = "toggle", path = "JHUD.ShowVelocity", label = "Velocity", note = "Show takeoff or current velocity."},
      {kind = "toggle", path = "JHUD.ShowGain", label = "Gain", note = "Show acceleration gain."},
      {kind = "toggle", path = "JHUD.ShowSync", label = "Sync", note = "Show strafe synchronization."},
      {kind = "toggle", path = "JHUD.ShowJSS", label = "JSS", note = "Show JumpStats score."},
      {kind = "toggle", path = "JHUD.ShowEfficiency", label = "Efficiency", note = "Show efficiency percentage."},
      {kind = "toggle", path = "JHUD.ShowSPJ", label = "Strafes per jump", note = "Show SPJ in the panel."},
      {kind = "slider", path = "JHUD.X", label = "Horizontal position", min = 0, max = 1, decimals = 2},
      {kind = "slider", path = "JHUD.Y", label = "Vertical position", min = 0, max = 1, decimals = 2},
      {kind = "choice", path = "JHUD.Align", label = "Text alignment", choices = {"left", "center", "right"}},
    },
  },
  {
    id = "velocity",
    title = "Velocity HUD",
    subtitle = "Adjust speed readout behavior and placement.",
    options = {
      {kind = "toggle", path = "VelocityHUD.ShowUnits", label = "Show units", note = "Append speed units to the velocity readout."},
      {kind = "slider", path = "VelocityHUD.X", label = "Horizontal position", min = 0, max = 1, decimals = 2},
      {kind = "slider", path = "VelocityHUD.Y", label = "Vertical position", min = 0, max = 1, decimals = 2},
    },
  },
  {
    id = "ssj",
    title = "SSJ Chat",
    subtitle = "Choose which stats are printed to chat after jumps.",
    options = {
      {kind = "toggle", path = "SSJ.Enabled", label = "Enable SSJ", note = "Print jump statistics in chat."},
      {kind = "toggle", path = "SSJ.ShowJump", label = "Jump count", note = "Include the jump number."},
      {kind = "toggle", path = "SSJ.ShowVelocity", label = "Velocity", note = "Include velocity."},
      {kind = "toggle", path = "SSJ.ShowGain", label = "Gain", note = "Include gain."},
      {kind = "toggle", path = "SSJ.ShowSync", label = "Sync", note = "Include sync."},
      {kind = "toggle", path = "SSJ.ShowJSS", label = "JSS", note = "Include JumpStats score."},
      {kind = "toggle", path = "SSJ.ShowEfficiency", label = "Efficiency", note = "Include efficiency."},
      {kind = "toggle", path = "SSJ.ShowSPJ", label = "Strafes per jump", note = "Include SPJ."},
    },
  },
  {
    id = "spectators",
    title = "Spectators",
    subtitle = "Control outgoing and incoming spectator stat sync.",
    options = {
      {kind = "toggle", path = "Spectators.SendStats", label = "Send my stats", note = "Let spectators receive your jump stats."},
      {kind = "toggle", path = "Spectators.ReceiveStats", label = "Receive target stats", note = "Show stats from the player you are watching."},
    },
  },
  {
    id = "fonts",
    title = "Fonts",
    subtitle = "Adjust display scale without editing Lua files.",
    options = {
      {kind = "slider", path = "Fonts.JHUDSize", label = "Jump HUD font size", min = 12, max = 64, decimals = 0},
      {kind = "slider", path = "Fonts.VelocitySize", label = "Velocity HUD font size", min = 12, max = 72, decimals = 0},
      {kind = "slider", path = "Fonts.MenuSize", label = "Menu font size", min = 12, max = 28, decimals = 0},
    },
  },
}

local function Clamp(value, min_value, max_value)
  value = tonumber(value) or min_value

  if math.Clamp then
    return math.Clamp(value, min_value, max_value)
  end

  return math.max(min_value, math.min(max_value, value))
end

local function SplitPath(path)
  local keys = {}

  for key in string.gmatch(tostring(path or ""), "[^%.]+") do
    table.insert(keys, key)
  end

  return keys
end

local function GetPath(tbl, path, fallback)
  local current = tbl

  for _, key in ipairs(SplitPath(path)) do
    if type(current) ~= "table" then
      return fallback
    end

    current = current[key]

    if current == nil then
      return fallback
    end
  end

  return current
end

local function GetDefaultValue(path, fallback)
  if not JumpStats.Config or not JumpStats.Config.GetDefaults then
    return fallback
  end

  local defaults = JumpStats.Config.GetDefaults()
  return GetPath(defaults, path, fallback)
end

local function ColorWithAlpha(color, alpha)
  return Color(color.r, color.g, color.b, alpha)
end

local function GetSetting(path, fallback)
  if not JumpStats.Settings or not JumpStats.Settings.Get then
    return fallback
  end

  local default_value = GetDefaultValue(path, fallback)
  return JumpStats.Settings.Get(path, default_value)
end

local function SetSetting(path, value)
  if not JumpStats.Settings or not JumpStats.Settings.Set then
    return false
  end

  JumpStats.Settings.Set(path, value)
  return true
end

local function SaveSettings()
  if JumpStats.Settings and JumpStats.Settings.Save then
    JumpStats.Settings.Save()
  end
end

local function QueueSave()
  if timer and timer.Create then
    timer.Create(kSaveDebounceId, 0.2, 1, SaveSettings)
    return
  end

  SaveSettings()
end

local function ApplySetting(path, value)
  if not SetSetting(path, value) then
    return false
  end

  QueueSave()
  return true
end

local function EnsureSettingsLoaded()
  if not JumpStats.Settings then
    return false
  end

  if JumpStats.Settings.Initialize and not JumpStats.Settings.initialized then
    JumpStats.Settings.Initialize()
    return true
  end

  if JumpStats.Settings.Load and not JumpStats.Settings.GetAll then
    JumpStats.Settings.Load()
    return true
  end

  if JumpStats.Settings.GetAll and not JumpStats.Settings.GetAll() and JumpStats.Settings.Load then
    JumpStats.Settings.Load()
  end

  return true
end

local function CreateFonts()
  surface.CreateFont("JumpStats.Menu.Title", {
    font = "Roboto",
    size = 26,
    weight = 800,
    antialias = true,
    extended = true,
  })

  surface.CreateFont("JumpStats.Menu.Section", {
    font = "Roboto",
    size = 20,
    weight = 700,
    antialias = true,
    extended = true,
  })

  surface.CreateFont("JumpStats.Menu.Body", {
    font = "Roboto",
    size = 16,
    weight = 500,
    antialias = true,
    extended = true,
  })

  surface.CreateFont("JumpStats.Menu.BodyBold", {
    font = "Roboto",
    size = 16,
    weight = 700,
    antialias = true,
    extended = true,
  })

  surface.CreateFont("JumpStats.Menu.Small", {
    font = "Roboto",
    size = 13,
    weight = 500,
    antialias = true,
    extended = true,
  })
end

local function PaintRoundPanel(radius, width, height, color, stroke_color)
  draw.RoundedBox(radius, 0, 0, width, height, color)

  if stroke_color then
    surface.SetDrawColor(stroke_color)
    surface.DrawOutlinedRect(0, 0, width, height, 1)
  end
end

local function MakeButton(parent, text, on_click, options)
  options = options or {}

  local button = vgui.Create("DButton", parent)
  button:SetText("")
  button:SetTall(options.tall or 40)
  button.Label = text
  button.IsPrimary = options.primary == true
  button.IsDanger = options.danger == true

  button.Paint = function(self, width, height)
    local base_color = kTheme.SurfaceAlt
    local text_color = kTheme.Text

    if self.IsPrimary then
      base_color = kTheme.Accent
    elseif self.IsDanger then
      base_color = ColorWithAlpha(kTheme.Danger, 32)
      text_color = kTheme.Danger
    end

    if self:IsHovered() then
      if self.IsPrimary then
        base_color = Color(98, 170, 255, 255)
      elseif self.IsDanger then
        base_color = ColorWithAlpha(kTheme.Danger, 48)
      else
        base_color = kTheme.SurfaceHover
      end
    end

    draw.RoundedBox(10, 0, 0, width, height, base_color)
    draw.SimpleText(self.Label, "JumpStats.Menu.BodyBold", width / 2, height / 2, text_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  button.DoClick = function()
    if on_click then
      on_click(button)
    end
  end

  return button
end

local function MakeCard(parent)
  local card = vgui.Create("DPanel", parent)
  card:Dock(TOP)
  card:DockMargin(0, 0, 10, 10)
  card:DockPadding(16, 14, 16, 14)
  card:SetTall(80)
  card.Paint = function(self, width, height)
    PaintRoundPanel(14, width, height, kTheme.Surface, kTheme.StrokeSoft)
  end

  return card
end

local function MakeToggle(parent, option, rebuild)
  local card = MakeCard(parent)
  card:SetTall(option.note and 88 or 60)

  local toggle = vgui.Create("DButton", card)
  toggle:Dock(FILL)
  toggle:SetText("")

  local function IsEnabled()
    return GetSetting(option.path, false) == true
  end

  toggle.Paint = function(self, width, height)
    local enabled = IsEnabled()
    local label_y = option.note and 18 or height / 2
    local note_y = 42

    draw.SimpleText(option.label, "JumpStats.Menu.BodyBold", 0, label_y, kTheme.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    if option.note then
      draw.SimpleText(option.note, "JumpStats.Menu.Small", 0, note_y, kTheme.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local switch_w = 46
    local switch_h = 24
    local switch_x = width - switch_w
    local switch_y = height / 2 - switch_h / 2
    local knob_size = 18
    local knob_x = enabled and (switch_x + switch_w - knob_size - 3) or (switch_x + 3)
    local switch_color = enabled and kTheme.Accent or kTheme.Stroke

    draw.RoundedBox(12, switch_x, switch_y, switch_w, switch_h, switch_color)
    draw.RoundedBox(9, knob_x, switch_y + 3, knob_size, knob_size, kTheme.Text)
  end

  toggle.DoClick = function()
    ApplySetting(option.path, not IsEnabled())

    if rebuild then
      rebuild(false)
    end
  end

  return card
end

local function MakeSlider(parent, option)
  local card = MakeCard(parent)
  card:SetTall(82)

  local label = vgui.Create("DLabel", card)
  label:Dock(TOP)
  label:SetTall(22)
  label:SetText(option.label)
  label:SetTextColor(kTheme.Text)
  label:SetFont("JumpStats.Menu.BodyBold")

  local slider = vgui.Create("DNumSlider", card)
  slider:Dock(TOP)
  slider:DockMargin(-8, 4, -4, 0)
  slider:SetTall(34)
  slider:SetText("")
  slider:SetMin(option.min or 0)
  slider:SetMax(option.max or 1)
  slider:SetDecimals(option.decimals or 0)
  slider:SetValue(GetSetting(option.path, option.min or 0))

  local initializing = true

  timer.Simple(0, function()
    if IsValid(slider) then
      initializing = false
    end
  end)

  slider.OnValueChanged = function(_, value)
    if initializing then
      return
    end

    local decimals = option.decimals or 0
    local multiplier = 10 ^ decimals
    local rounded_value = math.floor(value * multiplier + 0.5) / multiplier

    ApplySetting(option.path, rounded_value)
  end

  return card
end

local function MakeChoice(parent, option)
  local card = MakeCard(parent)
  card:SetTall(72)

  local label = vgui.Create("DLabel", card)
  label:Dock(LEFT)
  label:SetWide(230)
  label:SetText(option.label)
  label:SetTextColor(kTheme.Text)
  label:SetFont("JumpStats.Menu.BodyBold")

  local combo = vgui.Create("DComboBox", card)
  combo:Dock(RIGHT)
  combo:SetWide(180)
  combo:SetFont("JumpStats.Menu.Body")
  combo:SetTextColor(kTheme.Text)

  combo.Paint = function(self, width, height)
    draw.RoundedBox(10, 0, 0, width, height, kTheme.SurfaceAlt)
    surface.SetDrawColor(kTheme.Stroke)
    surface.DrawOutlinedRect(0, 0, width, height, 1)
  end

  local current_value = tostring(GetSetting(option.path, option.choices and option.choices[1] or ""))

  for _, choice in ipairs(option.choices or {}) do
    combo:AddChoice(choice, choice, choice == current_value)
  end

  combo:SetValue(current_value)

  combo.OnSelect = function(_, _, value)
    ApplySetting(option.path, value)
  end

  return card
end

local function MakeSectionHeader(parent, section)
  local header = vgui.Create("DPanel", parent)
  header:Dock(TOP)
  header:DockMargin(0, 0, 10, 10)
  header:SetTall(76)
  header.Paint = function(self, width, height)
    PaintRoundPanel(16, width, height, kTheme.AccentSoft, nil)
    draw.SimpleText(section.title, "JumpStats.Menu.Section", 18, 24, kTheme.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(section.subtitle or "", "JumpStats.Menu.Small", 18, 52, kTheme.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
  end

  return header
end

local function MakeNavButton(parent, section, active_section_id, on_click)
  local button = vgui.Create("DButton", parent)
  button:Dock(TOP)
  button:DockMargin(12, 0, 12, 8)
  button:SetTall(42)
  button:SetText("")
  button.Label = section.title

  button.Paint = function(self, width, height)
    local active = active_section_id == section.id
    local base_color = active and kTheme.AccentSoft or Color(0, 0, 0, 0)
    local text_color = active and kTheme.Text or kTheme.TextMuted

    if self:IsHovered() and not active then
      base_color = kTheme.SurfaceAlt
      text_color = kTheme.Text
    end

    draw.RoundedBox(10, 0, 0, width, height, base_color)

    if active then
      draw.RoundedBox(4, 0, 9, 4, height - 18, kTheme.Accent)
    end

    draw.SimpleText(self.Label, "JumpStats.Menu.BodyBold", 16, height / 2, text_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
  end

  button.DoClick = function()
    if on_click then
      on_click(section.id)
    end
  end

  return button
end

local function ConfigureScrollBar(scroll_panel)
  local vbar = scroll_panel:GetVBar()

  if not IsValid(vbar) then
    return
  end

  vbar:SetWide(8)
  vbar.Paint = function(_, width, height)
    draw.RoundedBox(4, 0, 0, width, height, kTheme.SurfaceAlt)
  end

  vbar.btnGrip.Paint = function(_, width, height)
    draw.RoundedBox(4, 0, 0, width, height, kTheme.Stroke)
  end

  vbar.btnUp.Paint = function() end
  vbar.btnDown.Paint = function() end
end

local function RebuildContent(content_panel, section_id, refresh_nav)
  content_panel:Clear()

  local selected_section = kSections[1]

  for _, section in ipairs(kSections) do
    if section.id == section_id then
      selected_section = section
      break
    end
  end

  MakeSectionHeader(content_panel, selected_section)

  for _, option in ipairs(selected_section.options or {}) do
    if option.kind == "toggle" then
      MakeToggle(content_panel, option, refresh_nav)
    elseif option.kind == "slider" then
      MakeSlider(content_panel, option)
    elseif option.kind == "choice" then
      MakeChoice(content_panel, option)
    end
  end
end

local function RebuildNav(nav_panel, active_section_id, on_select)
  nav_panel:Clear()

  local title = vgui.Create("DPanel", nav_panel)
  title:Dock(TOP)
  title:SetTall(94)
  title:DockMargin(16, 10, 16, 12)
  title.Paint = function(_, width, height)
    draw.SimpleText("JumpStats", "JumpStats.Menu.Title", 0, 26, kTheme.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("client settings", "JumpStats.Menu.Small", 2, 55, kTheme.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetDrawColor(kTheme.StrokeSoft)
    surface.DrawRect(0, height - 1, width, 1)
  end

  for _, section in ipairs(kSections) do
    MakeNavButton(nav_panel, section, active_section_id, on_select)
  end
end

local function MakeFooter(parent, frame, content_panel, get_active_section, set_active_section, rebuild_all)
  local footer = vgui.Create("DPanel", parent)
  footer:Dock(BOTTOM)
  footer:SetTall(66)
  footer:DockPadding(18, 12, 18, 12)
  footer.Paint = function(_, width, height)
    surface.SetDrawColor(kTheme.StrokeSoft)
    surface.DrawRect(0, 0, width, 1)
    draw.RoundedBoxEx(16, 0, 0, width, height, kTheme.Surface, false, false, true, true)
  end

  local close_button = MakeButton(footer, "Close", function()
    SaveSettings()
    frame:Close()
  end)
  close_button:Dock(RIGHT)
  close_button:SetWide(110)

  local save_button = MakeButton(footer, "Save", function()
    SaveSettings()
  end, {primary = true})
  save_button:Dock(RIGHT)
  save_button:DockMargin(0, 0, 10, 0)
  save_button:SetWide(110)

  local reset_button = MakeButton(footer, "Reset All", function()
    local function ResetAll()
      if JumpStats.Settings and JumpStats.Settings.Reset then
        JumpStats.Settings.Reset()
      end

      rebuild_all(get_active_section())
    end

    if Derma_Query then
      Derma_Query(
          "Reset every JumpStats client setting to its default value?",
          "Reset JumpStats Settings",
          "Reset",
          ResetAll,
          "Cancel")
      return
    end

    ResetAll()
  end, {danger = true})
  reset_button:Dock(LEFT)
  reset_button:SetWide(120)

  local reset_section_button = MakeButton(footer, "Reset Section", function()
    local active_section_id = get_active_section()
    local selected_section = nil

    for _, section in ipairs(kSections) do
      if section.id == active_section_id then
        selected_section = section
        break
      end
    end

    if not selected_section then
      return
    end

    for _, option in ipairs(selected_section.options or {}) do
      local default_value = GetDefaultValue(option.path, nil)

      if default_value ~= nil then
        SetSetting(option.path, default_value)
      end
    end

    SaveSettings()
    set_active_section(active_section_id)
    RebuildContent(content_panel, active_section_id, function()
      rebuild_all(active_section_id)
    end)
  end)
  reset_section_button:Dock(LEFT)
  reset_section_button:DockMargin(10, 0, 0, 0)
  reset_section_button:SetWide(140)

  return footer
end

function JumpStats.Menu.Open()
  if not EnsureSettingsLoaded() then
    if JumpStats.Commands and JumpStats.Commands.PrintChatMessage then
      JumpStats.Commands.PrintChatMessage("Settings are not available.")
    end

    return
  end

  if IsValid(JumpStats.Menu.frame) then
    JumpStats.Menu.frame:Close()
  end

  CreateFonts()

  local width = Clamp(ScrW() * 0.62, 860, 1040)
  local height = Clamp(ScrH() * 0.72, 560, 760)
  local active_section_id = JumpStats.Menu.last_section_id or "hud"

  local frame = vgui.Create("DFrame")
  JumpStats.Menu.frame = frame
  frame:SetSize(width, height)
  frame:Center()
  frame:SetTitle("")
  frame:ShowCloseButton(false)
  frame:SetDraggable(true)
  frame:SetSizable(false)
  frame:MakePopup()
  frame.Paint = function(_, frame_width, frame_height)
    draw.RoundedBox(18, 0, 0, frame_width, frame_height, kTheme.Background)
    surface.SetDrawColor(kTheme.Stroke)
    surface.DrawOutlinedRect(0, 0, frame_width, frame_height, 1)
  end

  local body = vgui.Create("DPanel", frame)
  body:Dock(FILL)
  body:DockPadding(0, 0, 0, 0)
  body.Paint = function() end

  local nav = vgui.Create("DPanel", body)
  nav:Dock(LEFT)
  nav:SetWide(190)
  nav.Paint = function(_, nav_width, nav_height)
    draw.RoundedBoxEx(18, 0, 0, nav_width, nav_height, kTheme.Surface, true, false, true, false)
    surface.SetDrawColor(kTheme.StrokeSoft)
    surface.DrawRect(nav_width - 1, 0, 1, nav_height)
  end

  local main = vgui.Create("DPanel", body)
  main:Dock(FILL)
  main:DockPadding(18, 18, 8, 0)
  main.Paint = function() end

  local scroll = vgui.Create("DScrollPanel", main)
  scroll:Dock(FILL)
  ConfigureScrollBar(scroll)

  local content = scroll:GetCanvas()
  content:DockPadding(0, 0, 0, 10)
  content.Paint = function() end

  local function GetActiveSection()
    return active_section_id
  end

  local function SetActiveSection(section_id)
    active_section_id = section_id
    JumpStats.Menu.last_section_id = section_id
  end

  local function RebuildAll(section_id)
    SetActiveSection(section_id or active_section_id)

    RebuildNav(nav, active_section_id, function(next_section_id)
      RebuildAll(next_section_id)
    end)

    RebuildContent(content, active_section_id, function()
      RebuildAll(active_section_id)
    end)
  end

  local footer = MakeFooter(main, frame, content, GetActiveSection, SetActiveSection, RebuildAll)
  footer:MoveToFront()

  RebuildAll(active_section_id)
end

function JumpStats.Menu.Close()
  if IsValid(JumpStats.Menu.frame) then
    JumpStats.Menu.frame:Close()
  end
end

function JumpStats.Menu.Toggle()
  if IsValid(JumpStats.Menu.frame) then
    JumpStats.Menu.Close()
    return
  end

  JumpStats.Menu.Open()
end
