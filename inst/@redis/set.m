function status = set(obj, key, value)

R=obj.redis;

  if nargin == 2
    value=key;
    key=inputname(2);
    if isstruct(value)
      f=fieldnames(value);
      for n = 1:numel(f)
        status=rSet(R,  [key '.' f{n}], value.(f{n}));
      end
    else
      status=rSet(R, key, value);
    end
  elseif nargin == 3
    status=rSet(R, key, value);
  else
    disp('ERROR: redisSet needs 2 or 3 arguments! redisSet(R, key, value)');
  end

end

function status=rSet(R,key,value)
  lk=length(key);
  if 1 == iscell(value)
	disp('ERROR: cells are not supported!');
  elseif 1 == ischar(value)
        __redisWrite(R, 'SET',key,value);
        status=__redisRead(R, 5000);
  elseif 1 == numel(value)
	__redisWrite(R, 'SET', key, value);
        status=__redisRead(R, 5000);
  else % it's a matrix...i hope so!
	dim=sprintf('%d ' ,size(value)); % save original dimensions
        % do not append, DEL and recreate!
        __redisWrite(R, 'EXISTS', key);
        status=__redisRead(R, 5000);
        if strfind (status,':1') == 1
                warning('Your choosen variable already exist in redis and will be overwritten!')
                __redisWrite(R, 'DEL', key);
                 status=__redisRead(R, 5000);
        end
	__redisWrite(R, 'RPUSH', key, dim);
	status=[status __redisRead(R, 5000)];

	__redisWrite(R, 'RPUSH', key, value(:));
	status=[status __redisRead(R, 5000)];
  end
end
