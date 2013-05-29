function value = redisIncr(R, key)

  __redisWrite (R, 'INCR', key);
  value=__redisRead (R, 5000);

