function pong = rename(obj, key, newkey)

R=obj.redis;

__redisWrite(R, 'RENAME', key, newkey);
pong = __redisRead(R, 5000);

if !strcmp(pong,"+OK\r\n")
  warning('Doh! Something went wrong while renaming!');
end

