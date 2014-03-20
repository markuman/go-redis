function reply = redisSave(R)

redisWrite(R, 'SAVE');
reply = redisRead(R, 5000);

if ~strcmp(reply,'+OK\r\n')
  warning('redis failed to save the db to disk!');
end

end
