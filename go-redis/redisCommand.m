function value = redisCommand(R, Command, opt)

if nargin < 3
  redisWrite(R, Command);
  value = redisRead(R, 5000);
else
  redisWrite(R, Command, opt);
  value = redisRead(R, 5000);
end
