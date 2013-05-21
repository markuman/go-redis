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
    eval (sprintf ("dim = [%s];",tmp{3}));
    tmp = str2num ( strvcat ({tmp{5:2:end}}));
    value = reshape (tmp,[],dim);

  else
    __redisWrite (R, 'GET', key); 
	value = __redisRead (R, 5000);

	value = num2str (strsplit (value,'\r\n'){2});

  end
end
