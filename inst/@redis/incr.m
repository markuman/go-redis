function value = incr(obj, key)

R=obj.redis;

  __redisWrite (R, 'INCR', key);
  value=__redisRead (R, 5000);

