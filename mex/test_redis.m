% test go-redis

% using host: 127.0.0.1
% using port 6379
% !! caution !! -- this will flush the database
OK = @(x) strcmp('OK', x);

% build for testing
if (exist('OCTAVE_VERSION', 'builtin') == 5)
    mkoctfile -Wall -Wextra -v -I/usr/include/hiredis -O2 --mex redis_.c -lhiredis -std=c99 -o redis_.mex
else
    mex -lhiredis -I/usr/include/hiredis/ CFLAGS='-fPIC -std=c99 -O2 -pedantic -g' redis_.c -o redis_.mexa64
end

%% testing core redis_ mex function
assert(strcmp('PONG',redis_('PING')))
assert(OK(redis_('flushdb')))
assert(OK(redis_('SET A 1')))
assert(OK(redis_({'SET', 'B', 'a whitespace value'})))
assert(redis_('INCR A') == 2)
assert(redis_({'DECR', 'A'}) == 1)
assert(strcmp('string', redis_('TYPE A')))
assert(redis_('DEL A') == 1)
assert(iscell(redis_('keys *')))
assert(strcmp('a whitespace value', redis_({'GET', 'B'})))

%% testing redis() class
setup
addpath('../inst/')
r = redis();
assert(strcmp('PONG',r.ping()))
assert(OK(r.call('flushdb')))
assert(OK(r.set('A', '1')))
assert(OK(r.set('B', 'a whitespace value')))
assert(r.incr('A') == 2)
assert(r.decr('A') == 1)
assert(strcmp('string', r.type('A')))
assert(r.del('A') == 1)
assert(iscell(r.call('keys *')))
assert(iscell(r.call({'keys','*'})))
assert(strcmp('a whitespace value', r.get('B')))
assert(OK(r.set('B space key', 'a whitespace value')))
assert(strcmp('a whitespace value', r.get('B space key')))

fprintf('\n everything passed\n')