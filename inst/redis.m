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
    end%properties

    methods

        %% classdef input validation
        function obj = redis(varargin)
            
            obj.port        = 6379;
            obj.hostname    = '127.0.0.1';
            obj.db          = 0;
            obj.passwd      = '';
            obj.precision   = 4;
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

            ret = redis_(r.hostname, r.port, r.db, r.passwd, sprintf('SET %s %s', key, num2str(value, r.precision)));

        end%set

        function ret = get(r, key)

            ret = redis_(r.hostname, r.port, r.db, r.passwd, sprintf('GET %s', key));

        end%get

        function ret = incr(r, key)

            ret = redis_(r.hostname, r.port, r.db, r.passwd, sprintf('INCR %s', key));

        end%incr

        function ret = decr(r, key)

            ret = redis_(r.hostname, r.port, r.db, r.passwd, sprintf('DECR %s', key));

        end%decr

        function ret = ping(r)

            ret = redis_(r.hostname, r.port, r.db, r.passwd, 'PING');

        end%ping

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
                if ~ischar(name)
                    error('input 3 has to be a char')
                else
                    varname = name;
                end%if ~ischar
            else
                % get origin variablename of array
                % shit shit shit                
                varname = inputname(2);                
            end%if nargin
            
            if isnumeric(array)
                
                % save array in a list
                ret1 = redis_(r.hostname, r.port, r.db, r.passwd, sprintf('RPUSH %s.values %s', varname, num2str(array(:)', r.precision)));
                % save dimension in a key
                ret2 = redis_(r.hostname, r.port, r.db, r.passwd, sprintf('RPUSH %s.dimension %s', varname, num2str(size(array), r.precision)));
                % group values and dimension
                ret3 = redis_(r.hostname, r.port, r.db, r.passwd, sprintf('SADD %s %s.values %s.dimension', varname, varname, varname));
                
                if (isnumeric(ret1) && isnumeric(ret2) && isnumeric(ret3))
                    ret = true();
                else
                    ret = false();
                end
                
            else
                error('Input Array have to be numeric')
            end
            
        end%function array2redis
        
        function ret = redis2array(r, key)
            
            valueVar        = redis_(r.hostname, r.port, r.db, r.passwd, sprintf('EXISTS %s.values', key));
            dimensionVar    = redis_(r.hostname, r.port, r.db, r.passwd, sprintf('EXISTS %s.dimension', key));
            if (1 == valueVar) && (1 == dimensionVar)
                ret         = redis_(r.hostname, r.port, r.db, r.passwd, sprintf('LRANGE %s.values 0 -1', key));
                dimension   = redis_(r.hostname, r.port, r.db, r.passwd, sprintf('LRANGE %s.dimension 0 -1', key));
                ret = reshape(str2double(ret),str2double(dimension)');
            else
                ret = false();
            end%if
            
        end%function redis2array

    end%methods

end%classdef

