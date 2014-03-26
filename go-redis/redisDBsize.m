function dbsize = redisDBsize(R)

redisWrite(R, 'DBSIZE');
dbsize = redisRead(R, 5000);

