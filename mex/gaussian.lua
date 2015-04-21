local function columnMajorOrder(col, row, nbRows)
  return (col-1) * nbRows + (row-1) + 1
end

local function gaussian(A,b, nbRows)

  local n = #(b)
  local x = {}
  for ind = 1,n do
    x[ind] = 0
  end -- for

  -- forward elimination
  for k = 1,n-1 do

    for i = k+1,n do
      local symInd  = columnMajorOrder(k, k, nbRows)
      local workInd = columnMajorOrder(k, i, nbRows)
      local xmult = A[workInd]/A[symInd]
      for j = k+1,n do
        local kjInd = columnMajorOrder(j, k, nbRows)
        local ijInd = columnMajorOrder(j, i, nbRows)
        A[ijInd] = A[ijInd] - xmult * A[kjInd]
      end -- for j

    b[i] = b[i] - xmult * b[k];
    end -- for i

  end -- for k

  local symInd = columnMajorOrder(n, n, nbRows)
  x[n] = b[n]/A[symInd]

  for i = n-1,1,-1 do

      local sumOfb = b[i]
      for j = i+1,n do
        local workInd = columnMajorOrder(j, i, nbRows)
        sumOfb = sumOfb - A[workInd] * x[j]
      end
      local symInd = columnMajorOrder(i, i, nbRows)
      x[i] = sumOfb/A[symInd]
  end

  return x

end -- function


local reqA = redis.call("EXISTS", KEYS[1] .. '.values')
local reqB = redis.call("EXISTS", KEYS[2] .. '.values')
if (1 == reqA) and (1 == reqB) then
  local A = redis.call("lrange", KEYS[1] .. '.values', "0", "-1")
  local b = redis.call("lrange", KEYS[2] .. '.values', "0", "-1")
  local rows = redis.call("lrange", KEYS[1] .. '.dimension', "0", "-1")
  local x = gaussian(A,b,rows[1])
  if (0 == redis.call("EXISTS", KEYS[1] .. KEYS[2] .. '.values')) and (0 == redis.call("EXISTS", KEYS[1] .. KEYS[2] .. '.dimension')) then
    for n = 1,#(x) do
      redis.call("RPUSH", KEYS[1] .. KEYS[2] .. '.values', x[n])
    end
    redis.call("RPUSH", KEYS[1] .. KEYS[2] .. '.dimension', #(x))
    redis.call("RPUSH", KEYS[1] .. KEYS[2] .. '.dimension', 1)
    redis.call("SADD", KEYS[1] .. KEYS[2], KEYS[1] .. KEYS[2] .. '.values', KEYS[1] .. KEYS[2] .. '.dimension')
  end
  return KEYS[1] .. KEYS[2]
end

