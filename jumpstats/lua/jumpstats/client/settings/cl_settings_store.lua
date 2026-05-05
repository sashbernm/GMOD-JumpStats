JumpStats.SettingsStore = JumpStats.SettingsStore or {}

local kSettingsDirectory = "jumpstats"
local kSettingsFileName = "settings.json"
local kSettingsPath = kSettingsDirectory .. "/" .. kSettingsFileName
local kDataRealm = "DATA"

local kMigrationHandlers = {
  [1] = function(settings)
    settings.Version = 1
    return settings
  end,
}

function JumpStats.SettingsStore.GetDirectory()
  return kSettingsDirectory
end

function JumpStats.SettingsStore.GetFileName()
  return kSettingsFileName
end

function JumpStats.SettingsStore.GetPath()
  return kSettingsPath
end

function JumpStats.SettingsStore.EnsureDirectory()
  if file.Exists(kSettingsDirectory, kDataRealm) then
    return true
  end

  file.CreateDir(kSettingsDirectory)
  return file.Exists(kSettingsDirectory, kDataRealm)
end

function JumpStats.SettingsStore.HasSave()
  return file.Exists(kSettingsPath, kDataRealm)
end

function JumpStats.SettingsStore.Load()
  if not JumpStats.SettingsStore.HasSave() then
    return nil
  end

  local raw_json = file.Read(kSettingsPath, kDataRealm)

  if not raw_json or raw_json == "" then
    return nil
  end

  local success, decoded = pcall(util.JSONToTable, raw_json)

  if not success or type(decoded) ~= "table" then
    return nil
  end

  return JumpStats.SettingsStore.Migrate(decoded)
end

function JumpStats.SettingsStore.Save(settings)
  if type(settings) ~= "table" then
    return false
  end

  if not JumpStats.SettingsStore.EnsureDirectory() then
    return false
  end

  local success, json = pcall(util.TableToJSON, settings, true)

  if not success or not json or json == "" then
    return false
  end

  file.Write(kSettingsPath, json)
  return JumpStats.SettingsStore.HasSave()
end

function JumpStats.SettingsStore.GetVersion(settings)
  if type(settings) ~= "table" then
    return 0
  end

  return tonumber(settings.Version) or 0
end

function JumpStats.SettingsStore.GetTargetVersion()
  if JumpStats.Config then
    return tonumber(JumpStats.Config.kCurrentSettingsVersion or JumpStats.Config.CurrentSettingsVersion) or 1
  end

  return 1
end

function JumpStats.SettingsStore.Migrate(settings)
  if type(settings) ~= "table" then
    return nil
  end

  local current_version = JumpStats.SettingsStore.GetVersion(settings)
  local target_version = JumpStats.SettingsStore.GetTargetVersion()

  if current_version > target_version then
    settings.Version = target_version
    return settings
  end

  for version = current_version + 1, target_version do
    local migration_handler = kMigrationHandlers[version]

    if migration_handler then
      settings = migration_handler(settings) or settings
    end
  end

  settings.Version = target_version
  return settings
end

function JumpStats.SettingsStore.Delete()
  if JumpStats.SettingsStore.HasSave() then
    file.Delete(kSettingsPath)
  end

  return not JumpStats.SettingsStore.HasSave()
end
