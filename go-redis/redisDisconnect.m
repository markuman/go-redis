function r = redisDisconnect(R)

redisWrite(R, 'QUIT');

% output is irrelavant, because redis reply +ok in any case while QUIT
% Futhermore, __redisWrite flush it (line 3) when calling
% r = __redisRead(R, 5000);

 tcp_close(R);

end
