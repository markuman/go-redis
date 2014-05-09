function dbs = dbsize(obj)

R=obj.redis;

__redisWrite(R, 'DBSIZE');
dbsize = __redisRead(R, 5000);

