JumpStats.Client = JumpStats.Client or {}

JumpStats.Client.initialized = JumpStats.Client.initialized or false

local kInitializeOrder = {
  {module_name = "Settings", function_name = "Initialize", required = true},
  {module_name = "Fonts", function_name = "Initialize", required = false},
  {module_name = "Commands", function_name = "Initialize", required = true},
  {module_name = "RunState", function_name = "Initialize", required = false},
  {module_name = "Calculator", function_name = "Initialize", required = false},
  {module_name = "JHUD", function_name = "Initialize", required = false},
  {module_name = "VelocityHUD", function_name = "Initialize", required = false},
  {module_name = "SSJ", function_name = "Initialize", required = false},
  {module_name = "HUDController", function_name = "Initialize", required = false},
  {module_name = "Spectators", function_name = "InitializeClient", required = false},
  {module_name = "Tracker", function_name = "Initialize", required = false},
}

local function LogInfo(message)
  if JumpStats.logger and JumpStats.logger.Info then
    JumpStats.logger:Info(message)
    return
  end

  print("[JumpStats] " .. message)
end

local function LogWarning(message)
  if JumpStats.logger and JumpStats.logger.Warn then
    JumpStats.logger:Warn(message)
    return
  end

  print("[JumpStats] WARNING: " .. message)
end

local function InitializeModule(module_name, function_name, required)
  local module = JumpStats[module_name]

  if not module then
    if required then
      LogWarning("Missing required client module: " .. module_name)
    end

    return false
  end

  local initialize_func = module[function_name]

  if not initialize_func then
    if required then
      LogWarning("Missing required initializer: JumpStats." .. module_name .. "." .. function_name)
    end

    return false
  end

  initialize_func()
  return true
end

function JumpStats.Client.Initialize()
  if JumpStats.Client.initialized then
    return
  end

  for _, entry in ipairs(kInitializeOrder) do
    InitializeModule(entry.module_name, entry.function_name, entry.required)
  end

  JumpStats.Client.initialized = true
  LogInfo("Initialized Client!")
end

function JumpStats.Client.Reload()
  JumpStats.Client.initialized = false

  if JumpStats.Settings and JumpStats.Settings.Load then
    JumpStats.Settings.Load()
  end

  if JumpStats.Settings and JumpStats.Settings.Apply then
    JumpStats.Settings.Apply()
  end

  if JumpStats.Calculator and JumpStats.Calculator.Reset then
    JumpStats.Calculator.Reset()
  end

  if JumpStats.RunState and JumpStats.RunState.Reset then
    JumpStats.RunState.Reset("reload")
  end

  if JumpStats.JHUD and JumpStats.JHUD.Clear then
    JumpStats.JHUD.Clear()
  end

  if JumpStats.VelocityHUD and JumpStats.VelocityHUD.Clear then
    JumpStats.VelocityHUD.Clear()
  end

  JumpStats.Client.Initialize()
end