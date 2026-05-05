JumpStats.ChatCommands = JumpStats.ChatCommands or {}

JumpStats.ChatCommands.initialized = JumpStats.ChatCommands.initialized or false

JumpStats.ChatCommands.menu_commands = {
  ["!jhud"] = true,
  ["/jhud"] = true,

  ["!jumpstats"] = true,
  ["/jumpstats"] = true,

  ["!js"] = true,
  ["/js"] = true,
}

function JumpStats.ChatCommands.Initialize()
  if JumpStats.ChatCommands.initialized then
    return
  end

  hook.Add("PlayerSay", "JumpStats.ChatCommands.PlayerSay", function(ply, text, team_chat)
    return JumpStats.ChatCommands.HandlePlayerSay(ply, text, team_chat)
  end)

  JumpStats.ChatCommands.initialized = true

  if JumpStats.Debug then
    JumpStats.logger:Info("Chat Commands Initialized!")
  end
end


function JumpStats.ChatCommands.Shutdown()
  hook.Remove("PlayerSay", "JumpStats.ChatCommands.PlayerSay")

  JumpStats.ChatCommands.initialized = false
end

function JumpStats.ChatCommands.HandlePlayerSay(ply, text, team_chat)
  if not JumpStats.ChatCommands.IsValidCaller(ply) then
    return text
  end

  local clean_text = JumpStats.ChatCommands.NormalizeText(text)

  if clean_text == "" then
    return text
  end

  if JumpStats.ChatCommands.IsMenuCommand(clean_text) then
    JumpStats.ChatCommands.OpenMenu(ply)
    return ""
  end

  return text
end

function JumpStats.ChatCommands.IsValidCaller(ply)
  if JumpStats.Util and JumpStats.Util.IsValidPlayer then
    return JumpStats.Util.IsValidPlayer(ply)
  end

  return IsValid(ply) and ply:IsPlayer()
end

function JumpStats.ChatCommands.NormalizeText(text)
  text = tostring(text or "")
  text = string.Trim(text)
  text = string.lower(text)

  return text
end

function JumpStats.ChatCommands.IsMenuCommand(text)
  return JumpStats.ChatCommands.menu_commands[text] == true
end

function JumpStats.ChatCommands.OpenMenu(ply)
  if not JumpStats.ChatCommands.IsValidCaller(ply) then
    return
  end

  ply:ConCommand("js_menu")
end

function JumpStats.ChatCommands.AddMenuCommand(command)
  local clean_command = JumpStats.ChatCommands.NormalizeText(command)

  if clean_command == "" then
    return false
  end

  JumpStats.ChatCommands.menu_commands[clean_command] = true
  return true
end

function JumpStats.ChatCommands.RemoveMenuCommand(command)
  local clean_command = JumpStats.ChatCommands.NormalizeText(command)

  if clean_command == "" then
    return false
  end

  JumpStats.ChatCommands.menu_commands[clean_command] = nil
  return true
end
