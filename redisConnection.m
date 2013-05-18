function r = redisConnection(host, port)

if nargin < 1,
  host = '127.0.0.1';
end

if nargin < 2,
  port = 6379;
end

r = tcp(host, port);
