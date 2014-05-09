function value = command(obj, Command, opt)

R=obj.redis;

if nargin < 3
  __redisWrite(R, Command);
  value = __redisRead(R, 5000);
else
  __redisWrite(R, Command, opt);
  value = __redisRead(R, 5000);
end
