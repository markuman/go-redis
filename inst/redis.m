classdef redis
    %redis mex client for Matlab and GNU Octave
    % r = redis()
    % r = redis(hostname)
    % r = redis(hostname, port)
    % r = redis(hostname, port, db)
    % r = redis(hostname, port, db, pwd)

    properties
        hostname
        port
        db
        pwd
    end%properties

    methods

        %% classdef input validation
        function obj = redis(varargin)

            if nargin == 0
                obj.port        = 6379;
                obj.hostname    = '127.0.0.1';
                obj.db          = 0;
                obj.pwd         = '';
            end
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
                obj.pwd         = varargin{4};
            end

        end%obj redis

        %% redis functions
        function ret = set(r, key, value)

            ret = redis_(r.hostname, r.port, r.db, r.pwd, sprintf('SET %s %s', key, num2str(value)));

        end%set

        function ret = get(r, key)

            ret = redis_(r.hostname, r.port, r.db, r.pwd, sprintf('GET %s', key));

        end%get

        function ret = incr(r, key)

            ret = sscanf(redis_(r.hostname, r.port, r.db, r.pwd, sprintf('INCR %s', key)), '%d');

        end%incr

        function ret = decr(r, key)

            ret = sscanf(redis_(r.hostname, r.port, r.db, r.pwd, sprintf('DECR %s', key)), '%d');

        end%decr

        function ret = ping(r)

            ret = redis_(r.hostname, r.port, r.db, r.pwd, 'PING');

        end%ping

        %% redis call command
        % for debugging and not directly supported redis functions
        function ret = call(r, command)

            ret = redis_(r.hostname, r.port, r.db, r.pwd, command);

        end%call

    end%methods

end%classdef

