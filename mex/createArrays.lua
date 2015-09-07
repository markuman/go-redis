local function ones(keyname, numel)
  for n = 1,numel do
    local ret = redis.call("RPUSH", keyname .. ".values", "1")
  end
  return 0
end -- function ones

local function zeros(keyname, numel)
  for n = 1,numel do
    local ret = redis.call("RPUSH", keyname .. ".values", "0")
  end
  return 0
end -- function ones

local function rand(keyname, numel)
  -- local seed = redis.call('TIME') -- "@user_script: 19: Write commands not allowed after non deterministic commands"  lol
  local t = redis.call('INFO') 
  math.randomseed(string.match(t, 'uptime_in_seconds:(%d+)'))
  for n = 1,numel do
    local ret = redis.call("RPUSH", keyname .. ".values", tostring(math.random()))
  end
  return 0
end

if 'ones' == ARGV[1] then
  return ones(KEYS[1], ARGV[2])
elseif 'zeros' == ARGV[1] then
  return zeros(KEYS[1], ARGV[2])
elseif 'rand' == ARGV[1] then
  return rand(KEYS[1], ARGV[2])
end

