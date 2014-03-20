function reply = redisSave(R)

__redisWrite(R, 'SAVE');
reply = __redisRead(R, 5000);

if !strcmp(reply,"+OK\r\n")
  warning('redis failed to save the db to disk!');
end
