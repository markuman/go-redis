function pong = redisPing(R)

redisWrite(R, 'PING');
pong = redisRead(R, 5000);

% "+PING\r\n" => char([43 80 79 78 71 13 10])
if !strcmp(pong,char([43 80 79 78 71 13 10]))
  warning('redis do not respond!');
end
