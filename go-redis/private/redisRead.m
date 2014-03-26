function reply = redisRead(R, timeout, looptime)

if nargin < 3
  looptime=100;
end

  start=tic;

  % get reply type
  rtype = char (fread (R,1,timeout));   % minimum read count = 3 (status byte, \r\n)
  reply = rtype;

  if isempty (rtype)
    error ('unexpected reply');
  end
  
  % check for valid replies
  if ~(rtype == '+' || rtype == '-' || rtype == ':' || rtype == '$' || rtype == '*')
    error ('unexpected reply');
  end


  lastread = 0;
  fprintf(stdout,'\r');flush_stdout;
  
  % read complete response
  while (tic-start < timeout*1000) 
    fprintf(stdout,'%d', lastread); flush_stdout;
    
    reply = [reply char (fread (R,1000000,looptime))];
    % if read at least one byte, increase timeout
    if lastread < length(reply)
      timeout = timeout + looptime*1.5;
    end
    lastread = length(reply);

    fprintf(stdout,'                    \r');

    lines = length (strfind (reply, char([13 10])));
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
      bulkreplies = str2num (strsplit (reply, '\n'));    % interprete first line
      bulkreplies = bulkreplies{1}(2:end);
      if lines > 2 * bulkreplies
        break;
      end
    end
    
  end

end

function flush_stdout ()
  if exist ('OCTAVE_VERSION')~=0
    fflush(stdout);
  else
    drawnow('update');
  end
end

