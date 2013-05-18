function value = redisCommant(R, cmd, arg, opt)

lc=length(cmd);
la=length(arg);
lo=length(opt);
tcp_write(R,sprintf("*2\r\n$3\r\nGET\r\n$%d\r\n%s\r\n",lk,key));

value=char(tcp_read(R,10000000,1000));

