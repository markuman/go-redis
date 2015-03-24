classdef redis
    %redis mex client for Matlab and GNU Octave
    % r = redis()
    % r = redis(hostname)
    % r = redis(hostname, port)

    properties
        hostname
        port
    end%properties

    methods

        %% classdef input validation

        function obj = redis(varargin)

            if nargin == 0
                obj.port        = 6379;
                obj.hostname    = '127.0.0.1';
            elseif nargin == 1
                obj.port        = 6379;
                obj.hostname    = varargin{1};
            else
                obj.port        = varargin{2};
                obj.hostname    = varargin{1};
            end

        end%obj redis

        %% redis functions
        function ret = set(r, key, value)

            ret = redis_(r.hostname, r.port, sprintf('SET %s %s', key, num2str(value)));

        end%set

        function ret = get(r, key)

            ret = redis_(r.hostname, r.port, sprintf('GET %s', key));

        end%get

        function ret = incr(r, key)

            ret = sscanf(redis_(r.hostname, r.port, sprintf('INCR %s', key)), '%d');

        end%incr

        function ret = decr(r, key)

            ret = sscanf(redis_(r.hostname, r.port, sprintf('DECR %s', key)), '%d');

        end%decr

        function ret = ping(r)

            ret = redis_(r.hostname, r.port, 'PING');

        end%ping

        %% redis call command
        % for debugging and not directly supported redis functions

        function ret = call(r, command)

            ret = redis_(r.hostname, r.port, command);

        end%call

    end%methods

end%classdef

