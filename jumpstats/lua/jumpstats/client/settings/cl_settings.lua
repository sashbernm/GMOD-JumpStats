JumpStats.Settings = JumpStats.Settings or {}

JumpStats.Settings.data = JumpStats.Settings.data or nil
JumpStats.Settings.initialized = JumpStats.Settings.initialized or false

local function DeepCopy(value)
  if JumpStats.Util and JumpStats.Util.DeepCopy then
    return JumpStats.Util.DeepCopy(value)
  end

  if type(value) ~= "table" then
    return value
  end

  local copy = {}
  for key, child in pairs(value) do
    copy[DeepCopy(key)] = DeepCopy(child)
  end

  return copy
end

local function SplitPath(path)
  local keys = {}

  for key in string.gmatch(tostring(path or ""), "[^%.]+") do
    table.insert(keys, key)
  end

  return keys
end

local function GetPath(tbl, path, fallback)
  if JumpStats.Util and JumpStats.Util.GetPath then
    return JumpStats.Util.GetPath(tbl, path, fallback)
  end

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

local function SetPath(tbl, path, value)
  if JumpStats.Util and JumpStats.Util.SetPath then
    JumpStats.Util.SetPath(tbl, path, value)
    return
  end

  local keys = SplitPath(path)
  local current = tbl

  if #keys == 0 then
    return
  end

  for index = 1, #keys - 1 do
    local key = keys[index]

    if type(current[key]) ~= "table" then
      current[key] = {}
    end

    current = current[key]
  end

  current[keys[#keys]] = value
end

local function MergeDefaults(tbl, defaults)
  if JumpStats.Util and JumpStats.Util.MergeDefaults then
    return JumpStats.Util.MergeDefaults(tbl, defaults)
  end

  local merged = DeepCopy(defaults or {})

  local function MergeInto(destination, source)
    for key, value in pairs(source or {}) do
      if type(value) == "table" and type(destination[key]) == "table" then
        MergeInto(destination[key], value)
      else
        destination[key] = value
      end
    end
  end

  MergeInto(merged, tbl)
  return merged
end

local function StartsWith(value, prefix)
  value = tostring(value or "")
  prefix = tostring(prefix or "")

  if string.StartWith then
    return string.StartWith(value, prefix)
  end

  return string.sub(value, 1, #prefix) == prefix
end

local function GetCurrentSettingsVersion()
  if not JumpStats.Config then
    return 1
  end

  return tonumber(JumpStats.Config.kCurrentSettingsVersion or JumpStats.Config.CurrentSettingsVersion) or 1
end

local function GetDefaults()
  if JumpStats.Config and JumpStats.Config.GetDefaults then
    return JumpStats.Config.GetDefaults()
  end

  return {}
end

function JumpStats.Settings.Initialize()
  if JumpStats.Settings.initialized then
    return
  end

  JumpStats.Settings.Load()
  JumpStats.Settings.initialized = true

  if JumpStats.logger then
    JumpStats.logger:Info("Initialized settings")
  end
end

function JumpStats.Settings.Load()
  local defaults = GetDefaults()
  local saved = nil

  if JumpStats.SettingsStore and JumpStats.SettingsStore.Load then
    saved = JumpStats.SettingsStore.Load()
  end

  JumpStats.Settings.data = MergeDefaults(saved or {}, defaults)
  JumpStats.Settings.data.Version = GetCurrentSettingsVersion()
  JumpStats.Settings.Apply()

  return JumpStats.Settings.data
end

function JumpStats.Settings.Save()
  if type(JumpStats.Settings.data) ~= "table" then
    return false
  end

  if not JumpStats.SettingsStore or not JumpStats.SettingsStore.Save then
    return false
  end

  return JumpStats.SettingsStore.Save(JumpStats.Settings.data)
end

function JumpStats.Settings.Get(path, fallback)
  if type(JumpStats.Settings.data) ~= "table" then
    return fallback
  end

  return GetPath(JumpStats.Settings.data, path, fallback)
end

function JumpStats.Settings.Set(path, value)
  if type(JumpStats.Settings.data) ~= "table" then
    JumpStats.Settings.data = GetDefaults()
    JumpStats.Settings.data.Version = GetCurrentSettingsVersion()
  end

  SetPath(JumpStats.Settings.data, path, value)
  JumpStats.Settings.ApplyPath(path)

  return true
end

function JumpStats.Settings.Toggle(path)
  local current = JumpStats.Settings.Get(path, false)

  JumpStats.Settings.Set(path, not current)
  return JumpStats.Settings.Save()
end

function JumpStats.Settings.Reset()
  JumpStats.Settings.data = GetDefaults()
  JumpStats.Settings.data.Version = GetCurrentSettingsVersion()

  local saved = JumpStats.Settings.Save()
  JumpStats.Settings.Apply()

  return saved
end

function JumpStats.Settings.ResetPath(path)
  local default_value = nil

  if JumpStats.Config and JumpStats.Config.GetDefault then
    default_value = JumpStats.Config.GetDefault(path)
  else
    default_value = GetPath(GetDefaults(), path, nil)
  end

  if default_value == nil then
    return false
  end

  JumpStats.Settings.Set(path, DeepCopy(default_value))
  return JumpStats.Settings.Save()
end

function JumpStats.Settings.GetAll()
  return JumpStats.Settings.data
end

function JumpStats.Settings.SetAll(settings)
  if type(settings) ~= "table" then
    return false
  end

  JumpStats.Settings.data = MergeDefaults(settings, GetDefaults())
  JumpStats.Settings.data.Version = GetCurrentSettingsVersion()
  JumpStats.Settings.Apply()

  return true
end

function JumpStats.Settings.Apply()
  if JumpStats.Fonts and JumpStats.Fonts.Refresh then
    JumpStats.Fonts.Refresh()
  end
end

function JumpStats.Settings.ApplyPath(path)
  if StartsWith(path, "Fonts.") then
    if JumpStats.Fonts and JumpStats.Fonts.Refresh then
      JumpStats.Fonts.Refresh()
    end
  end
end
