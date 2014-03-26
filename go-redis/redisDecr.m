function value = redisDecr(R, key)

  redisWrite (R, 'DECR', key);
  value=redisRead (R, 5000);

