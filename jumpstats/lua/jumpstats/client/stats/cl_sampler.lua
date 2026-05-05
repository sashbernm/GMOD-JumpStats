JumpStats.Sampler = JumpStats.Sampler or {}

JumpStats.Sampler.previous_yaw = JumpStats.Sampler.previous_yaw or 0
JumpStats.Sampler.previous_position = JumpStats.Sampler.previous_position or nil
JumpStats.Sampler.last_sample = JumpStats.Sampler.last_sample or nil

local kTeleportDistance = 512

local function GetVelocity(ply)
  if ply.GetAbsVelocity then
    return ply:GetAbsVelocity()
  end

  return ply:GetVelocity()
end

local function GetAngles(move_data, command)
  if command and command.GetViewAngles then
    return command:GetViewAngles()
  end

  if move_data and move_data.GetAngles then
    return move_data:GetAngles()
  end

  return Angle(0, 0, 0)
end

local function GetButtons(move_data, command)
  if command and command.GetButtons then
    return command:GetButtons()
  end

  if move_data and move_data.GetButtons then
    return move_data:GetButtons()
  end

  return 0
end

local function GetForwardMove(move_data, command)
  if command and command.GetForwardMove then
    return command:GetForwardMove()
  end

  if move_data and move_data.GetForwardSpeed then
    return move_data:GetForwardSpeed()
  end

  return 0
end

local function GetSideMove(move_data, command)
  if command and command.GetSideMove then
    return command:GetSideMove()
  end

  if move_data and move_data.GetSideSpeed then
    return move_data:GetSideSpeed()
  end

  return 0
end

function JumpStats.Sampler.Sample(ply, move_data, command)
  if not JumpStats.Util.IsValidPlayer(ply) then
    return nil
  end

  return JumpStats.Sampler.BuildSample(ply, move_data, command)
end

function JumpStats.Sampler.BuildSample(ply, move_data, command)
  local velocity = GetVelocity(ply)
  local angles = GetAngles(move_data, command)
  local yaw = angles.y or 0
  local previous_yaw = JumpStats.Sampler.previous_yaw or yaw
  local yaw_diff = JumpStats.Util.NormalizeYaw(yaw - previous_yaw)
  local angle_diff = JumpStats.Util.NormalizeYaw(previous_yaw - yaw)
  local forward_move = GetForwardMove(move_data, command)
  local side_move = GetSideMove(move_data, command)
  local position = ply:GetPos()
  local previous_position = JumpStats.Sampler.previous_position

  local sample = {
    ply = ply,
    tick = engine.TickCount and engine.TickCount() or 0,
    time = CurTime and CurTime() or 0,
    position = position,
    previousPosition = previous_position,
    velocity = velocity,
    absoluteVelocity = velocity,
    velocity2D = Vector(velocity.x, velocity.y, 0),
    speed2D = velocity:Length2D(),
    angles = angles,
    yaw = yaw,
    previousYaw = previous_yaw,
    yawDiff = yaw_diff,
    angleDiff = angle_diff,
    forwardMove = forward_move,
    sideMove = side_move,
    buttons = GetButtons(move_data, command),
    onGround = JumpStats.Sampler.IsOnGround(ply),
    ducking = JumpStats.Sampler.IsDucking(ply),
    waterLevel = ply:WaterLevel(),
    moveType = ply:GetMoveType(),
    maxSpeed = ply.GetMaxSpeed and ply:GetMaxSpeed() or 0,
    laggedMovement = ply.GetLaggedMovementValue and ply:GetLaggedMovementValue() or 1,
    teleported = JumpStats.Sampler.DetectTeleport(position, previous_position),
  }

  sample.wishDirection, sample.wishSpeed = JumpStats.Sampler.GetWishDirection(angles, forward_move, side_move)

  JumpStats.Sampler.previous_yaw = yaw
  JumpStats.Sampler.previous_position = position
  JumpStats.Sampler.last_sample = sample

  return sample
end

function JumpStats.Sampler.GetWishDirection(angles, forward_move, side_move)
  local move = Vector(forward_move or 0, side_move or 0, 0)
  local forward = angles:Forward()
  local side = angles:Right()

  forward.z = 0
  side.z = 0
  forward:Normalize()
  side:Normalize()

  local wish_velocity = Vector(
      forward.x * move.x + side.x * move.y,
      forward.y * move.x + side.y * move.y,
      0)
  local wish_speed = wish_velocity:Length()

  if wish_speed > 0 then
    wish_velocity:Normalize()
  end

  return wish_velocity, wish_speed
end

function JumpStats.Sampler.IsOnGround(ply)
  if ply.IsFlagSet and FL_ONGROUND then
    return ply:IsFlagSet(FL_ONGROUND)
  end

  return ply:OnGround()
end

function JumpStats.Sampler.IsDucking(ply)
  return ply:Crouching()
end

function JumpStats.Sampler.DetectTeleport(position, previous_position)
  if not position or not previous_position then
    return false
  end

  return position:Distance(previous_position) > kTeleportDistance
end

function JumpStats.Sampler.ResetHistory()
  JumpStats.Sampler.previous_yaw = 0
  JumpStats.Sampler.previous_position = nil
  JumpStats.Sampler.last_sample = nil
end
