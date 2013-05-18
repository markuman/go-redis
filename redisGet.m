function value = redisGet(R, key)

if nargin < 2,
  disp('ERROR: redisGet needs 2 arguments! redisGet(R, key)');
else
  lk=length(key);
  tcp_write(R,sprintf("*2\r\n$4\r\nTYPE\r\n$%d\r\n%s\r\n",lk,key));
  t=char(tcp_read(R,1000,5)(2:end-2));
  if 1 == (strcmp(t,'list'))
	tcp_write(R,sprintf("*4\r\n$6\r\nLRANGE\r\n$%d\r\n%s\r\n$1\r\n0\r\n$8\r\n67108864\r\n",lk,key)); % just a high number. i hope it's enough! 1024*8*1024*8
	in.char=char(tcp_read(R,10000000,50)); % set time out 10 times as GET. should be enough for safe
	in.n=strfind (in.char,"\n");
	dim=str2num(in.char(in.n(1,2)+1:in.n(1,3)-2));
	for i=4:2:size(in.n,2)-1
		tmp(((i/2)-1),1)=str2num(in.char(in.n(1,i)+1:in.n(1,i+1)-2));
	end
	value=reshape (tmp,[],dim);
  else
  	tcp_write(R,sprintf("*2\r\n$3\r\nGET\r\n$%d\r\n%s\r\n",lk,key));
	value=str2num(char(tcp_read(R,10000000,5)(5:end-2)));
  end
end
