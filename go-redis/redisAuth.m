function value = redisAuth(R, passphrase)

redisWrite(R, 'AUTH', passphrase);
value = redisRead(R, 5000);

% "+OK\r\n" => char([43 79 75 13 10])
if !strcmp(value,char([43 79 75 13 10]))
  warning('redis: auth not successful');
end
