function reply = redisRead(R, timeout, looptime)

switch nargin
    case ~3
	looptime=100;
end

  start=tic;

  % get reply type
  rtype = char (tcp_read (R,1,timeout));   % minimum read count = 3 (status byte, \r\n)
  reply = rtype;

  if isempty (rtype)
    error ('unexpected reply');
  end
  
  % check for valid replies
  if ~(rtype == '+' || rtype == '-' || rtype == ':' || rtype == '$' || rtype == '*')
    error ('unexpected reply');
  end


  lastread = 0;
  ## FIXME
  # fflush for matlab ...
  fprintf(stdout,'\r');fflush(stdout);
  
  % read complete response
  while (tic-start < timeout*1000) 
    fprintf(stdout,'%d', lastread); fflush(stdout);
    
    reply = [reply char (tcp_read (R,1000000,looptime))];
    % if read at least one byte, increase timeout
    if lastread < length(reply)
      timeout = timeout + looptime*1.5;
    end
    lastread = length(reply);

    fprintf(stdout,'                    \r');

    lines = length (strfind (reply, '\r\n'));
    % break after first line for error, status and integer replies
    if (rtype == '+' || rtype == '-' || rtype == ':') && lines > 0
      break;
    end
    
    % bulk reply is always two lines
    if rtype == '$' && lines > 1
      break;
    end
   
    % multi bulk reply, not binary, not integer safe !
    if rtype == '*' && lines > 0
      bulkreplies = str2double (strsplit (reply, '\n'){1}(2:end));    % interprete first line
      if lines > 2 * bulkreplies
        break;
      end
    end
    
  end

end
