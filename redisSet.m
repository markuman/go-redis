function status = redisSet(R, key, value)

if nargin < 3,
  disp('ERROR: redisSet needs 3 arguments! redisSet(R, key, value)');
else
  lk=length(key);
  if 1 == iscell(value)
	disp('ERROR: cells are not supported!');
  elseif 1 < size(value,1) || 1 < size(value,2)
	dim=sprintf('%d' ,size(value,2)); % just the colum nr is needed for restoring the original dimension of the matrice
	ld=length(dim);
	tcp_write(R,sprintf("*3\r\n$5\r\nRPUSH\r\n$%d\r\n%s\r\n$%d\r\n%s\r\n",lk,key,ld,dim)); % the first value in our lrange is not a value from the matrice, it's just the colume indice number for restoring the matrice dimension
	values=reshape (value,[],1);
	% if it's a huge matrice, it may take a long long time! it's not a fault of redis!!
	for row = 1:size(values,1)
		val=num2str(values(row),16);
		lv=length(val);
		tcp_write(R,sprintf("*3\r\n$5\r\nRPUSH\r\n$%d\r\n%s\r\n$%d\r\n%s\r\n",lk,key,lv,val));
	end
%% tried to vectorized it - but it fails atm
%	values=num2str(values,7);
%	vallen(1:size(values,1),1)=length(values(:,1:end));
%	tcp_write(R,sprintf("*3\r\n$5\r\nRPUSH\r\n$%d\r\n%s\r\n$%d\r\n%s\r\n",lk,key,vallen(1:end),values(:,1:end)));
%	status=char(tcp_read(R,10000000,100)); % set time out higher for multiple value feedback!
  elseif 1 == isnumeric (value)
	lv=length(num2str(value,16));
	tcp_write(R,sprintf("*3\r\n$3\r\nSET\r\n$%d\r\n%s\r\n$%d\r\n%s\r\n",lk,key,lv,num2str(value,16)));
	status=char(tcp_read(R,10000000,5));
  else
	disp('WARNING: You are going to store a string! Take care when do redisGet in Octave! String import is not supported yet!');
	lv=length(value);
	tcp_write(R,sprintf("*3\r\n$3\r\nSET\r\n$%d\r\n%s\r\n$%d\r\n%s\r\n",lk,key,lv,value));
	status=char(tcp_read(R,10000000,5));
  end
end
