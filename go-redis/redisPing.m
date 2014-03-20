function pong = redisPing(R)

redisWrite(R, 'PING');
pong = redisRead(R, 5000);

if ~strcmp(pong,'+PONG\r\n')
  warning('redis do not respond!');
end

end
