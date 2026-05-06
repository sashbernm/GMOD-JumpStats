-- Shared declarations first.
JumpStats = JumpStats or {}

JumpStats.kVersion = JumpStats.kVersion or "0.5.0"
JumpStats.Version = JumpStats.kVersion
JumpStats.debug_enabled = JumpStats.debug_enabled or false
JumpStats.Debug = JumpStats.debug_enabled

JumpStats.Config = JumpStats.Config or {}
JumpStats.Util = JumpStats.Util or {}
JumpStats.Net = JumpStats.Net or {}
JumpStats.Spectators = JumpStats.Spectators or {}

local function CreateFallbackLogger(prefix)
  local logger = {}

  local function Print(level, message)
    message = tostring(message or "")

    if level and level ~= "" then
      print("[" .. prefix .. "] " .. level .. ": " .. message)
      return
    end

    print("[" .. prefix .. "] " .. message)
  end

  function logger:Info(message)
    Print("", message)
  end

  function logger:Warn(message)
    Print("WARNING", message)
  end

  function logger:Error(message)
    Print("ERROR", message)
  end

  return logger
end

if BetterLog and BetterLog.Create then
  JumpStats.logger = JumpStats.logger or BetterLog:Create("JumpStats")
else
  JumpStats.logger = JumpStats.logger or CreateFallbackLogger("JumpStats")
end

if CLIENT then
  JumpStats.Client = JumpStats.Client or {}
  JumpStats.Settings = JumpStats.Settings or {}
  JumpStats.SettingsStore = JumpStats.SettingsStore or {}
  JumpStats.Commands = JumpStats.Commands or {}
  JumpStats.Menu = JumpStats.Menu or {}
  JumpStats.RunState = JumpStats.RunState or {}
  JumpStats.Sampler = JumpStats.Sampler or {}
  JumpStats.Calculator = JumpStats.Calculator or {}
  JumpStats.Format = JumpStats.Format or {}
  JumpStats.Tracker = JumpStats.Tracker or {}
  JumpStats.Fonts = JumpStats.Fonts or {}
  JumpStats.JHUD = JumpStats.JHUD or {}
  JumpStats.VelocityHUD = JumpStats.VelocityHUD or {}
  JumpStats.HUDController = JumpStats.HUDController or {}
  JumpStats.SSJ = JumpStats.SSJ or {}
end

if SERVER then
  JumpStats.Server = JumpStats.Server or {}
  JumpStats.ChatCommands = JumpStats.ChatCommands or {}
end

function JumpStats:GetVersion()
  return JumpStats.kVersion
end

function JumpStats.GetVersion()
  return JumpStats.kVersion
end

function JumpStats.DebugPrint(...)
  if not JumpStats.Debug and not JumpStats.debug_enabled then
    return
  end

  local parts = {}
  for index = 1, select("#", ...) do
    parts[index] = tostring(select(index, ...))
  end

  print("[JumpStats] " .. table.concat(parts, " "))
end

if JumpStats.logger and JumpStats.logger.Info then
  JumpStats.logger:Info("Initializing JumpStats " .. JumpStats:GetVersion() .. "!")
end
