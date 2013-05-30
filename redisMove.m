function value = redisMove(R, key, db)

__redisWrite(R, 'MOVE', key, db);
value = __redisRead(R, 5000);

if strcmp(value,":1\r\n")
  sprintf('Key %s successful moved to database %d!', key, db)
elseif strcmp(value,":0\r\n")
  sprintf('WARNING: Failed to move key %s to database %d!', key, db)
else
  sprintf('ERROR!')
end
