function status = save(obj, key, value)

R=obj.redis;
  if nargin == 1
    __redisWrite(R, 'SAVE');
    reply = __redisRead(R, 5000);
    if !strcmp(reply,char([43 79 75 13 10]))
      warning('redis failed to save the db to disk!');
    end
  elseif nargin == 2
    value=key;
    key=inputname(2);
    status=rSet(R, key, value);
  else
    status=rSet(R, key, value);
  end

end

function status=rSet(R, key, value)

  lk=length(key);

%% FIXME
%% serialisieren von value hier!
%%  value=serialize(value);

  if 1 == ischar(value)
        __redisWrite(R, 'SET',key,value);
        status=__redisRead(R, 5000);
  end
end
