function value = redisAuth(R, passphrase)

lp=length(passphrase);
tcp_write(R,sprintf("*2\r\n$4\r\nAUTH\r\n$%d\r\n%s\r\n",lp,passphrase));

value=char(tcp_read(R,1000,5)(1:end-2));

