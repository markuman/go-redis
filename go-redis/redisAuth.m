function value = redisAuth(R, passphrase)

redisWrite(R, 'AUTH', passphrase);
value = redisRead(R, 5000);

if ~strcmp(value,'+OK\r\n')
  warning('redis: auth not successful');
end
