function value = select(obj, db)

R=obj.redis;

__redisWrite(R, 'SELECT', db);
value = __redisRead(R, 5000);

if !strcmp(value,"+OK\r\n")
  warning("redis failed to change the database!");
end
