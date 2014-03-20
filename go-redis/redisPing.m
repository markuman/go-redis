function pong = redisPing(R)

__redisWrite(R, 'PING');
pong = __redisRead(R, 5000);

if !strcmp(pong,"+PONG\r\n")
  warning('redis do not respond!');
end
