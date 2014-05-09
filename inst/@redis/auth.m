function value = auth(obj, passphrase)

R=obj.redis;

__redisWrite(R, 'AUTH', passphrase);
value = __redisRead(R, 5000);

if !strcmp(value,"+OK\r\n")
  warning("redis: auth not successful");
end
