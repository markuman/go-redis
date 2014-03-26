function value = redisIncr(R, key)

  redisWrite (R, 'INCR', key);
  value=redisRead (R, 5000);

