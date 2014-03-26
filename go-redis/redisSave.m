function reply = redisSave(R)

redisWrite(R, 'SAVE');
reply = redisRead(R, 5000);

if !strcmp(reply,char([43 79 75 13 10]))
  warning('redis failed to save the db to disk!');
end
