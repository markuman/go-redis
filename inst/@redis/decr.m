function value = decr(obj, key)

R=obj.redis;

  __redisWrite (R, 'DECR', key);
  value=__redisRead (R, 5000);

