function value = redisGet (R, key)

if nargin < 2,
  disp('ERROR: redisGet needs 2 arguments! redisGet(R, key)');
else

  redisWrite (R, 'TYPE', key);
  t=redisRead (R, 5000);

  if strfind (t,'+list')
    redisWrite (R, 'LRANGE', key, 0, 7e6);
    reply = redisRead(R, 5000);

    reply(reply==13)=[];
    tmp = strsplit (reply, char(10));
    eval (sprintf ('dim = [%s];',tmp{3}));
    tmp = str2double ({tmp{5:2:end}});
    value = reshape (tmp,dim);

  else
    redisWrite (R, 'GET', key);
    reply = redisRead (R, 5000);

    reply(reply==13)=[];
    value = strsplit(reply,char(10)){2};
    if 1 == isnum(value)
      value = str2double (value);
    end

  end
end
