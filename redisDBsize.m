function dbsize = redisDBsize(R)

__redisWrite(R, 'DBSIZE');
dbsize = __redisRead(R, 5000);

