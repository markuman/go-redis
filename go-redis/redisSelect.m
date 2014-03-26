function value = redisSelect(R, db)

redisWrite(R, 'SELECT', db);
value = redisRead(R, 5000);

if !strcmp(value,char([43 79 75 13 10]))
  warning("redis failed to change the database!");
end
