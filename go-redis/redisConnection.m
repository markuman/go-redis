
function r = redisConnection(host, port)

switch nargin
    case 0
        host='127.0.0.1';
        port=6379;
    case 1
        port=6379;
end

r = tcpip(host, port);

end

