local kAddonRoot = "jumpstats/"


local kSharedFiles = {
  "sh_namespace.lua",
  "sh_util.lua",
  "sh_config.lua",
  "sh_net.lua",
}


local kServerFiles = {
  "server/sv_chat_commands.lua",
  "server/sv_spectators.lua",
  "server/sv_init.lua",
}


local kClientFiles = {
  "client/settings/cl_settings_store.lua",
  "client/settings/cl_settings.lua",
  "client/settings/cl_menu.lua",
  "client/settings/cl_concommands.lua",

  "client/stats/cl_run_state.lua",
  "client/stats/cl_sampler.lua",
  "client/stats/cl_calculator.lua",
  "client/stats/cl_format.lua",

  "client/hud/cl_fonts.lua",
  "client/hud/cl_jhud.lua",
  "client/hud/cl_velhud.lua",
  "client/chat/cl_ssj.lua",

  "client/cl_spectators.lua",

  "client/hud/cl_hud_controller.lua",

  "client/stats/cl_tracker.lua",

  "client/cl_init.lua",
}

local function FullPath(path)
  return kAddonRoot .. path
end

local function IncludeShared(path)
  local full_path = FullPath(path)

  if SERVER then
    AddCSLuaFile(full_path)
  end

  include(full_path)
end

local function IncludeServer(path)
  if not SERVER then
    return
  end

  include(FullPath(path))
end

local function IncludeClient(path)
  local full_path = FullPath(path)

  if SERVER then
    AddCSLuaFile(full_path)
    return
  end

  include(full_path)
end

local function IncludeList(files, include_func)
  for _, path in ipairs(files) do
    include_func(path)
  end
end

local function Bootstrap()
  IncludeList(kSharedFiles, IncludeShared)
  IncludeList(kClientFiles, IncludeClient)
  IncludeList(kServerFiles, IncludeServer)

  if SERVER and JumpStats and JumpStats.Server then
    JumpStats.Server.Initialize()
  end

  if CLIENT and JumpStats and JumpStats.Client then
    hook.Add("Initialize", "JumpStats.Client.Initialize", function()
      JumpStats.Client.Initialize()
    end)
  end
end

Bootstrap()
