function pong = redisRename(R, key, newkey)

redisWrite(R, 'RENAME', key, newkey);
pong = redisRead(R, 5000);

if !strcmp(pong,char([43 79 75 13 10]))
  warning('Doh! Something went wrong while renaming!');
end

