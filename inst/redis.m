classdef redis
    %redis mex client for Matlab and GNU Octave
    % r = redis()
    % r = redis(hostname)
    % r = redis(hostname, port)
    % r = redis(hostname, port, db)
    % r = redis(hostname, port, db, passwd)
    % r = redis(hostname, port, db, passwd, precision)
    % r = redis(hostname, port, db, passwd, precision, batchsize)

    properties
        hostname
        port
        db
        passwd
        precision
        batchsize
    end%properties

    properties (Access = protected)
       swap
       count
    end

    methods

        %% classdef input validation
        function self = redis(varargin)
            self.port            = 6379;
            self.hostname        = '127.0.0.1';
            self.db              = 0;
            self.passwd          = '';
            self.precision       = 4;
            self.batchsize       = 64;
            self.swap            = cell(self.batchsize,1);
            self.count           = 0;
            if nargin >= 1
                self.hostname    = varargin{1};
            end
            if nargin >= 2
                self.port        = varargin{2};
            end
            if nargin >= 3
                self.db          = varargin{3};
            end
            if nargin >= 4
                self.passwd      = varargin{4};
            end
            if nargin >= 5
                self.precision   = varargin{5};
            end
            if nargin >= 6
                self.batchsize   = varargin{6};
            end

        end%obj redis

        %% redis call command
        % for debugging and not directly supported redis functions
        function ret = call(self, command)
            % command can be a single string, but than, keynames and values
            % are not whitespace-safe
            % when the command it a cell, separated in command, key, value,
            % than everything is whitespace-safe

            ret = redis_(self.hostname, self.port, self.db, self.passwd, command);

        end%call

        %% redis functions
        function ret = set(self, key, value)
            if ischar(key)
                if any(isspace(key))
                    key = ['"' key '"'];
                end
                if isnumeric(value)
                    ret = self.call({'SET', key, num2str(value, self.precision) });

                elseif ischar(value)
                    ret = self.call({'SET', key, value});
                else
                    error('value must be a char or numeric')
                end
            else
                error('key must be a char')
            end

        end%set

        function ret = get(self, key)

            if ischar(key)
                if any(isspace(key))
                    key = ['"' key '"'];
                end
                ret = self.call({'GET', key});
            else
                error('keyname must be a whitespace-free string')
            end

        end%get

        function ret = incr(self, key)
            if any(isspace(key))
                key = ['"' key '"'];
            end
            ret = self.call({'INCR', key});

        end%incr

        function ret = decr(self, key)
            if any(isspace(key))
                key = ['"' key '"'];
            end
            ret = self.call({'DECR', key});

        end%decr

        function ret = ping(self)

            ret = self.call('PING');

        end%ping

        function ret = del(self, varargin)

            ret = self.call({'DEL', varargin{:}});

        end%del

        function ret = exists(self, keyname)

            if ischar(keyname)
                if any(isspace(keyname))
                    keyname = ['"' keyname '"'];
                end
                ret = self.call({'EXISTS', keyname});
            else
                error('Input must be a char')
            end

        end%exists

        function ret = type(self, keyname)

            if ischar(keyname)
                if any(isspace(keyname))
                    keyname = ['"' keyname '"'];
                end
                ret = self.call({'TYPE', keyname});
            else
                error('Input must be a char')
            end

        end%type

        %% TODO SUBCLASS
        function self = pipeline(self, command)

            if ischar(command)
                self.count = self.count + 1;
                self.swap{self.count, 1} = command;

                if (self.count == self.batchsize)
                    self = self.pipeline(true);
                end

            elseif (command)
                self.call(self.swap(~cellfun('isempty',self.swap)));
                self.count = 0;
                self.swap = cell(self.batchsize,1);
            else
                error('input musst be a string')
            end


        end%pipeline

        function self = execute(self)
            self = self.pipeline(true);
        end%execute


        %% Matlab/Octave special
        % save array in redis
        function ret = array2redis(self, array, name)

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

                if (1 == self.exists(varname)) 
                    error('KEY %s exists already', varname);
                end

                % save array in a list
                ret1 = self.call(sprintf('RPUSH %s.values %s', varname, num2str(array(:)', self.precision)));
                % save dimension in a key
                ret2 = self.call(sprintf('RPUSH %s.dimension %s', varname, num2str(size(array), self.precision)));
                % group values and dimension
                ret3 = self.call(sprintf('SADD %s %s.values %s.dimension', varname, varname, varname));

                if (isnumeric(ret1) && isnumeric(ret2) && isnumeric(ret3))
                    ret = true();
                else
                    ret = false();
                end

            else
                error('Input Array have to be numeric')
            end

        end%function array2redis

        function ret = redis2array(self, keyname)

            if ischar(keyname) && (0 == any(isspace(keyname)))
                valueVar        = self.exists([keyname '.values']);
                dimensionVar    = self.exists([keyname '.dimension']);
                if valueVar && dimensionVar
                    ret         = self.call(sprintf('LRANGE %s.values 0 -1', keyname));
                    dimension   = self.call(sprintf('LRANGE %s.dimension 0 -1', keyname));
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
        function ret = gaussian(self, a, b)
            % currently sum of gaussian.lua
            % 15d33d14f48708a38a828adbfb1f464798ad8e59 in redis
            retVar = self.call(sprintf('EVALSHA 15d33d14f48708a38a828adbfb1f464798ad8e59 2 %s %s', a, b));
            ret = self.redis2array(retVar);
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

