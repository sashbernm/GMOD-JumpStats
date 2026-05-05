function JumpStats.Util.DeepCopy(value)
  if type(value) ~= "table" then
    return value
  end

  local copy = {}
  for key, child in pairs(value) do
    copy[JumpStats.Util.DeepCopy(key)] = JumpStats.Util.DeepCopy(child)
  end

  return copy
end

function JumpStats.Util.MergeDefaults(tbl, defaults)
  local merged = JumpStats.Util.DeepCopy(defaults or {})

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

function JumpStats.Util.SplitPath(path)
  local keys = {}

  for key in string.gmatch(tostring(path or ""), "[^%.]+") do
    table.insert(keys, key)
  end

  return keys
end

function JumpStats.Util.GetPath(tbl, path, fallback)
  local current = tbl

  for _, key in ipairs(JumpStats.Util.SplitPath(path)) do
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

function JumpStats.Util.SetPath(tbl, path, value)
  if type(tbl) ~= "table" then
    return false
  end

  local keys = JumpStats.Util.SplitPath(path)

  if #keys == 0 then
    return false
  end

  local current = tbl

  for index = 1, #keys - 1 do
    local key = keys[index]
    if type(current[key]) ~= "table" then
      current[key] = {}
    end

    current = current[key]
  end

  current[keys[#keys]] = value
  return true
end

function JumpStats.Util.Round(number, decimals)
  number = tonumber(number) or 0
  decimals = decimals or 0

  local multiplier = 10 ^ decimals
  return math.floor(number * multiplier + 0.5) / multiplier
end

function JumpStats.Util.Clamp(value, min_value, max_value)
  value = tonumber(value) or 0
  return math.max(min_value, math.min(max_value, value))
end

function JumpStats.Util.TableAverage(values)
  if not values or #values == 0 then
    return 0
  end

  local total = 0
  for _, value in ipairs(values) do
    total = total + (tonumber(value) or 0)
  end

  return total / #values
end

function JumpStats.Util.NormalizeYaw(yaw)
  yaw = tonumber(yaw) or 0

  while yaw > 180 do
    yaw = yaw - 360
  end

  while yaw < -180 do
    yaw = yaw + 360
  end

  return yaw
end

function JumpStats.Util.ColorFromTable(tbl)
  if not tbl then
    return Color(255, 255, 255, 255)
  end

  return Color(tbl.r or 255, tbl.g or 255, tbl.b or 255, tbl.a or 255)
end

function JumpStats.Util.TableFromColor(color)
  if not color then
    return {r = 255, g = 255, b = 255, a = 255}
  end

  return {
    r = color.r or 255,
    g = color.g or 255,
    b = color.b or 255,
    a = color.a or 255,
  }
end

function JumpStats.Util.IsValidPlayer(ply)
  return IsValid(ply) and ply:IsPlayer()
end

function JumpStats.Util.IsFirstPrediction()
  if IsFirstTimePredicted then
    return IsFirstTimePredicted()
  end

  return true
end
