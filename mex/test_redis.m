% test go-redis

% using host: 127.0.0.1
% using port 6379

assert(strcmp('PONG',redis_('PING')) == 1)
assert(strcmp('OK', redis_('flushdb')) == 1)
assert(strcmp('OK', redis_('SET A 1')) == 1)
assert(redis_('INCR A') == 2)
assert(redis_('DECR A') == 1)
assert(iscell(redis_('keys *')) == 1)