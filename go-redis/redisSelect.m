function value = redisSelect(R, db)

__redisWrite(R, 'SELECT', db);
value = __redisRead(R, 5000);

if !strcmp(value,"+OK\r\n")
  warning("redis failed to change the database!");
end
