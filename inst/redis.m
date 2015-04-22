classdef redis
    %redis mex client for Matlab and GNU Octave
    % r = redis()
    % r = redis(hostname)
    % r = redis(hostname, port)
    % r = redis(hostname, port, db)
    % r = redis(hostname, port, db, passwd)

    properties
        hostname
        port
        db
        passwd
        precision
        silentOverwrite
    end%properties

    methods

        %% classdef input validation
        function obj = redis(varargin)
            
            obj.port            = 6379;
            obj.hostname        = '127.0.0.1';
            obj.db              = 0;
            obj.passwd          = '';
            obj.precision       = 4;
            obj.silentOverwrite = false;
            if nargin >= 1
                obj.hostname    = varargin{1};
            end
            if nargin >= 2
                obj.port        = varargin{2};
            end
            if nargin >= 3
                obj.db          = varargin{3};
            end
            if nargin >=4
                obj.passwd      = varargin{4};
            end

        end%obj redis

        %% redis functions
        function ret = set(r, key, value)

            if ischar(key) && (0 == any(isspace(key)))
                if r.exists(key) && (0 == r.silentOverwrite)
                    error('KEY %s exists already', key);
                end

                if iscell(value)
                    error('cell is not supported for set. Serilalize yourself')

                elseif isnumeric(value)
                    % delete %s.serialstring without checking, because it isn't
                    % a serialstring anymore
                    r.del([key '.serialstring']);
                    ret = r.call(sprintf('SET %s %s', key, num2str(value, r.precision))); 

                elseif ischar(value) && any(isspace(value))
                    % yeah, serialize it quick & dirty!
                    if (exist('OCTAVE_VERSION', 'builtin') == 5)
                        value = sprintf('%d,',uint8(value));
                    else
                        value = sprintf('%d,', unicode2native(char(uint8(value))));
                    end
                    redis_(r.hostname, r.port, r.db, r.passwd, sprintf('SET %s.serialstring 1', key));
                    ret = r.call(sprintf('SET %s %s', key, value));   

                end%if check classtype
            else
                error('Input "key" must be a whitespace-free string')
            end
            
        end%set

        function ret = get(r, key)
            
            if ischar(key) && (0 == any(isspace(key)))
                ret = r.call(sprintf('GET %s', key));
                if r.exists([key '.serialstring'])
                    if (exist('OCTAVE_VERSION', 'builtin') == 5)
                        ret = char(sscanf(ret, '%d,')');
                    else
                        ret = native2unicode(sscanf(ret, '%d,')');
                    end
                end
            else
                error('keyname must be a whitespace-free string')
            end

        end%get

        function ret = incr(r, key)

            ret = r.call(['INCR ' key]);

        end%incr

        function ret = decr(r, key)

            ret = r.call(['DECR ' key]);

        end%decr

        function ret = ping(r)

            ret = r.call('PING');

        end%ping
        
        function ret = del(r, varargin)
            
            %let's hope every input is a whitespace-free char
            vars = sprintf('%s ', varargin{:});
            ret = r.call(['DEL ' vars]);
            
        end%del
        
        function ret = exists(r, keyname)
            
            if ischar(keyname) && (0 == any(isspace(keyname)))
                ret = r.call(['EXISTS ' keyname]);
            else
                error('Input must be a whitespace-free string')
            end
            
        end%exists
        
        function ret = type(r, keyname)
            
            if ischar(keyname) && (0 == any(isspace(keyname)))
                ret = r.call(['TYPE ' keyname]);
            else
                error('Input must be a whitespace-free string')
            end
            
        end%type
            

        %% redis call command
        % for debugging and not directly supported redis functions
        function ret = call(r, command)

            ret = redis_(r.hostname, r.port, r.db, r.passwd, command);

        end%call
        
        %% Matlab/Octave special
        % save array in redis
        function ret = array2redis(r, array, name)
            
            if (exist('OCTAVE_VERSION', 'builtin') == 5) && (nargin == 2)
               error('Currently you have to name you array using array2redis in Octave')
            end%if
            
            if (nargin == 3)
                if ischar(name) && (0 == any(isspace(name)))
                    varname = name;
                else
                    error('input 3 has to be a char')
                end%if ~ischar
            else
                % get origin variablename of array
                varname = inputname(2);                
            end%if nargin
            
            if isnumeric(array)
                
                if (1 == r.exists(varname)) && (0 == r.silentOverwrite)
                    error('KEY %s exists already', varname);
                else
                    r.del(varname, [varname '.values'], [varname '.dimension']);
                end
                
                % save array in a list
                ret1 = r.call(sprintf('RPUSH %s.values %s', varname, num2str(array(:)', r.precision)));
                % save dimension in a key
                ret2 = r.call(sprintf('RPUSH %s.dimension %s', varname, num2str(size(array), r.precision)));
                % group values and dimension
                ret3 = r.call(sprintf('SADD %s %s.values %s.dimension', varname, varname, varname));
                
                if (isnumeric(ret1) && isnumeric(ret2) && isnumeric(ret3))
                    ret = true();
                else
                    ret = false();
                end
                
            else
                error('Input Array have to be numeric')
            end
            
        end%function array2redis
        
        function ret = redis2array(r, keyname)
            
            if ischar(keyname) && (0 == any(isspace(keyname)))
                valueVar        = r.exists([keyname '.values']);
                dimensionVar    = r.exists([keyname '.dimension']);
                if valueVar && dimensionVar
                    ret         = r.call(sprintf('LRANGE %s.values 0 -1', keyname));
                    dimension   = r.call(sprintf('LRANGE %s.dimension 0 -1', keyname));
                    ret = reshape(str2double(ret),str2double(dimension)');
                else
                    ret = false();
                end%if
            else
                error('Input must be the keyname (whitespace-free) of an array')
            end%if char
            
        end%function redis2array
        
        %% HIGH EXPERIMENTAL
        % https://github.com/markuman/go-redis/wiki/Gaussian-elimination
        function ret = gaussian(r, a, b)
            % currently sum of gaussian.lua
            % 15d33d14f48708a38a828adbfb1f464798ad8e59 in redis
            retVar = r.call(sprintf('EVALSHA 15d33d14f48708a38a828adbfb1f464798ad8e59 2 %s %s', a, b));
            ret = r.redis2array(retVar);
        end
       
% whitspaces fuckup!
%         function ret = loadGaussian(r)
%             fid = fopen('private/gaussian.lua','r');
%             if fid >= 3
%                 luastring = fread (fid, 'char=>char').';
%                 ret = redis_(r.hostname, r.port, r.db, r.passwd, sprintf('SCRIPT LOAD %s', luastring));
%                 fclose(fid);                
%             else
%                 error('failed to load file private/gaussian.lua')
%             end%if
%         end%function

    end%methods

end%classdef

