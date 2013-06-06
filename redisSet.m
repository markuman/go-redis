function status = redisSet(R, key, value)

if nargin < 3,
  disp('ERROR: redisSet needs 3 arguments! redisSet(R, key, value)');
else
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
