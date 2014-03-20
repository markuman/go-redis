function value = redisDecr(R, key)

  __redisWrite (R, 'DECR', key);
  value=__redisRead (R, 5000);

