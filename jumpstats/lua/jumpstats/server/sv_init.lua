JumpStats.Server = JumpStats.Server or {}

function JumpStats.Server.Initialize()
  JumpStats.Server.RegisterNetMessages()

  if JumpStats.ChatCommands then
    JumpStats.ChatCommands.Initialize()
  end

  if JumpStats.Spectators then
    JumpStats.Spectators.Initialize()
  end

  JumpStats.logger:Info("Initialized Server!")
end

function JumpStats.Server.RegisterNetMessages()
  JumpStats.Net.Register()
end
