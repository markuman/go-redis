function r = redisConnection(host='127.0.0.1', port=6379)

r = tcp(host, port);
