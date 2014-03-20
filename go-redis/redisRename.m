function pong = redisRename(R, key, newkey)

redisWrite(R, 'RENAME', key, newkey);
pong = redisRead(R, 5000);

if ~strcmp(pong,'+OK\r\n')
  warning('Doh! Something went wrong while renaming!');
end

end

