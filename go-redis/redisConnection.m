function r = redisConnection(host, port)

switch nargin
    case 0
	host='127.0.0.1';
	port=6379;
    case 1
        port=6379;
end

if exist ('OCTAVE_VERSION')~=0
	r = tcp(host, port);
else
	r = tcpip(host, port);
end

end
