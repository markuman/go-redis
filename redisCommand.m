function value = redisCommand(R, Command, opt)

__redisWrite(R, Command, opt);
value = __redisRead(R, 5000);

