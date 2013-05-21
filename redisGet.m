function value = redisGet (R, key)

if nargin < 2,
  disp('ERROR: redisGet needs 2 arguments! redisGet(R, key)');
else

  __redisWrite (R, 'TYPE', key);
  t=__redisRead (R, 5000);

  if strfind (t,'+list')
    __redisWrite (R, 'LRANGE', key, 0, 7e6);
    reply = __redisRead(R, 5000);

    reply(reply==13)=[];
    tmp = strsplit (reply, char(10));
%    tmp = strsplit (reply,'\r\n');
%tmp = cell2mat ({tmp{5:2:end}})
%for i=4:2:size(in.n,2)-1
%		tmp(((i/2)-1),1)=str2num(in.char(in.n(1,i)+1:in.n(1,i+1)-2));
%	end
    eval (sprintf ("dim = [%s];",tmp{3}));
%    tmp = str2num (strjoin ({tmp{5:2:end}}));
    tmp = cellfun(@str2num, tmp, 'UniformOutput', false);
    tmp = cell2mat (tmp)(2:end);
    value = reshape (tmp,[],dim);

  else
    __redisWrite (R, 'GET', key); 
	value = __redisRead (R, 5000);

	value = num2str (strsplit (value,'\r\n'){2});

  end
end
