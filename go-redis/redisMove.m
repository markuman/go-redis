function value = redisMove(R, key, db)

redisWrite(R, 'MOVE', key, db);
value = redisRead(R, 5000);

% ":1\r\n" => char([58 49 13 10])
if !strcmp(value,char([58 49 13 10]))
  sprintf('WARNING: Failed to move key %s to database %d!', key, db)
end
