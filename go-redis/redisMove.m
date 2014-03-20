function value = redisMove(R, key, db)

redisWrite(R, 'MOVE', key, db);
value = redisRead(R, 5000);

if ~strcmp(value,':1\r\n')
  sprintf('WARNING: Failed to move key %s to database %d!', key, db)
end

end
