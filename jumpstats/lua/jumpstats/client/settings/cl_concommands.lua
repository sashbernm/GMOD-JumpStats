JumpStats.Commands = JumpStats.Commands or {}

local kCommandNames = {
  Menu = "js_menu",
  Reset = "js_reset",
  ToggleJhud = "js_jhud",
  ToggleVelocityHud = "js_velhud",
  ToggleSsj = "js_ssj",
  Help = "js_help",
  SetJhudPosition = "js_jhud_pos",
  SetVelocityHudPosition = "js_velhud_pos",
}

local kHelpLines = {
  "JumpStats commands:",
  "  js_menu - open the JumpStats menu",
  "  js_reset - reset all JumpStats settings",
  "  js_jhud - toggle the jump stats HUD",
  "  js_velhud - toggle the velocity HUD",
  "  js_ssj - toggle SSJ chat output",
  "  js_jhud_pos <x> <y> - set JHUD position using 0.0 to 1.0 screen ratios",
  "  js_velhud_pos <x> <y> - set velocity HUD position using 0.0 to 1.0 screen ratios",
}

JumpStats.Commands.initialized = JumpStats.Commands.initialized or false

function JumpStats.Commands.Initialize()
  if JumpStats.Commands.initialized then
    return
  end

  concommand.Add(kCommandNames.Menu, function()
    JumpStats.Commands.OpenMenu()
  end)

  concommand.Add(kCommandNames.Reset, function()
    JumpStats.Commands.ResetSettings()
  end)

  concommand.Add(kCommandNames.ToggleJhud, function()
    JumpStats.Commands.ToggleJhud()
  end)

  concommand.Add(kCommandNames.ToggleVelocityHud, function()
    JumpStats.Commands.ToggleVelocityHud()
  end)

  concommand.Add(kCommandNames.ToggleSsj, function()
    JumpStats.Commands.ToggleSsj()
  end)

  concommand.Add(kCommandNames.Help, function()
    JumpStats.Commands.PrintHelp()
  end)

  concommand.Add(kCommandNames.SetJhudPosition, function(ply, cmd, args)
    JumpStats.Commands.SetJhudPosition(args)
  end)

  concommand.Add(kCommandNames.SetVelocityHudPosition, function(ply, cmd, args)
    JumpStats.Commands.SetVelocityHudPosition(args)
  end)

  JumpStats.Commands.initialized = true
end

function JumpStats.Commands.OpenMenu()
  if not JumpStats.Menu or not JumpStats.Menu.Open then
    JumpStats.Commands.PrintChatMessage("Menu is not available.")
    return
  end

  JumpStats.Menu.Open()
end

function JumpStats.Commands.ResetSettings()
  if not JumpStats.Settings or not JumpStats.Settings.Reset then
    JumpStats.Commands.PrintChatMessage("Settings are not available.")
    return
  end

  JumpStats.Settings.Reset()
  JumpStats.Commands.PrintChatMessage("Settings reset.")
end

function JumpStats.Commands.ToggleJhud()
  if not JumpStats.Settings or not JumpStats.Settings.Toggle then
    JumpStats.Commands.PrintChatMessage("Settings are not available.")
    return
  end

  JumpStats.Settings.Toggle("HUD.JHUDEnabled")

  local enabled = JumpStats.Settings.Get("HUD.JHUDEnabled", true)
  local state = enabled and "enabled" or "disabled"

  JumpStats.Commands.PrintChatMessage("Jump HUD " .. state .. ".")
end

function JumpStats.Commands.ToggleVelocityHud()
  if not JumpStats.Settings or not JumpStats.Settings.Toggle then
    JumpStats.Commands.PrintChatMessage("Settings are not available.")
    return
  end

  JumpStats.Settings.Toggle("HUD.VelocityHUDEnabled")

  local enabled = JumpStats.Settings.Get("HUD.VelocityHUDEnabled", true)
  local state = enabled and "enabled" or "disabled"

  JumpStats.Commands.PrintChatMessage("Velocity HUD " .. state .. ".")
end

function JumpStats.Commands.ToggleSsj()
  if not JumpStats.Settings or not JumpStats.Settings.Toggle then
    JumpStats.Commands.PrintChatMessage("Settings are not available.")
    return
  end

  JumpStats.Settings.Toggle("SSJ.Enabled")

  local enabled = JumpStats.Settings.Get("SSJ.Enabled", true)
  local state = enabled and "enabled" or "disabled"

  JumpStats.Commands.PrintChatMessage("SSJ " .. state .. ".")
end

function JumpStats.Commands.SetJhudPosition(args)
  local success = JumpStats.Commands.SetPosition(
      "JHUD.X",
      "JHUD.Y",
      args,
      "Usage: js_jhud_pos <x> <y> where x and y are between 0.0 and 1.0")

  if not success then
    return
  end

  JumpStats.Commands.PrintChatMessage("Jump HUD position updated.")
end

function JumpStats.Commands.SetVelocityHudPosition(args)
  local success = JumpStats.Commands.SetPosition(
      "VelocityHUD.X",
      "VelocityHUD.Y",
      args,
      "Usage: js_velhud_pos <x> <y> where x and y are between 0.0 and 1.0")

  if not success then
    return
  end

  JumpStats.Commands.PrintChatMessage("Velocity HUD position updated.")
end

function JumpStats.Commands.PrintHelp()
  for _, line in ipairs(kHelpLines) do
    JumpStats.Commands.PrintConsoleMessage(line)
  end

  JumpStats.Commands.PrintChatMessage("Command list printed to console.")
end

function JumpStats.Commands.PrintChatMessage(message)
  message = tostring(message or "")

  if message == "" then
    return
  end

  if chat and chat.AddText and Color then
    chat.AddText(Color(120, 220, 120), "[JumpStats] ", Color(255, 255, 255), message)
    return
  end

  JumpStats.Commands.PrintConsoleMessage(message)
end

function JumpStats.Commands.PrintConsoleMessage(message)
  message = tostring(message or "")

  if message == "" then
    return
  end

  print("[JumpStats] " .. message)
end

function JumpStats.Commands.GetCommandName(command_key)
  return kCommandNames[command_key]
end

function JumpStats.Commands.ParseRatio(value)
  local ratio = tonumber(value)

  if not ratio then
    return nil
  end

  if ratio < 0 or ratio > 1 then
    return nil
  end

  return ratio
end

function JumpStats.Commands.SetPosition(x_path, y_path, args, usage_text)
  if not JumpStats.Settings or not JumpStats.Settings.Set or not JumpStats.Settings.Save then
    JumpStats.Commands.PrintChatMessage("Settings are not available.")
    return false
  end

  args = args or {}

  local x = JumpStats.Commands.ParseRatio(args[1])
  local y = JumpStats.Commands.ParseRatio(args[2])

  if not x or not y then
    JumpStats.Commands.PrintConsoleMessage(usage_text)
    JumpStats.Commands.PrintChatMessage(usage_text)
    return false
  end

  JumpStats.Settings.Set(x_path, x)
  JumpStats.Settings.Set(y_path, y)
  JumpStats.Settings.Save()

  if JumpStats.Settings.Apply then
    JumpStats.Settings.Apply()
  end

  return true
end