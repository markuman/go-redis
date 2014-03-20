function value = redisSelect(R, db)

redisWrite(R, 'SELECT', db);
value = redisRead(R, 5000);

if ~strcmp(value,'+OK\r\n')
  warning('redis failed to change the database!');
end

end
