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
        batchsize
    end%properties

    properties (Access = protected)
       swap
    end

    methods

        %% classdef input validation
        function self = redis(varargin)
            self.port            = 6379;
            self.hostname        = '127.0.0.1';
            self.db              = 0;
            self.passwd          = '';
            self.precision       = 4;
            self.silentOverwrite = false;
            self.batchsize       = 64;
            self.swap            = cell(self.batchsize,1);
            if nargin >= 1
                self.hostname    = varargin{1};
            end
            if nargin >= 2
                self.port        = varargin{2};
            end
            if nargin >= 3
                self.db          = varargin{3};
            end
            if nargin >=4
                self.passwd      = varargin{4};
            end

        end%obj redis

        %% redis call command
        % for debugging and not directly supported redis functions
        function ret = call(self, command)

            ret = redis_(self.hostname, self.port, self.db, self.passwd, command);

        end%call

        %% redis call command, which enables whitespace
        function ret = key_value_call(self, command, key, value)

            ret = redis_(self.hostname, self.port, self.db, self.passwd, key, value, [command ' %s %s']);

        end

        %% redis functions
        function ret = set(self, key, value)

            if ischar(key) && (0 == any(isspace(key)))
                if self.exists(key) && (0 == self.silentOverwrite)
                    error('KEY %s exists already', key);
                end

                if iscell(value)
                    error('cell is not supported for set. Serilalize yourself')

                elseif isnumeric(value)
                    % delete %s.serialstring without checking, because it isn't
                    % a serialstring anymore
                    self.del([key '.serialstring']);
                    ret = self.call(sprintf('SET %s %s', key, num2str(value, self.precision)));

                elseif ischar(value)
                    % the uggly part!!
                    self.del([key '.serialstring']);
                    if any(isspace(value))
                        % yeah, serialize it quick & dirty!
                        if (exist('OCTAVE_VERSION', 'builtin') == 5)
                            value = sprintf('%d,', uint8(value));
                        else
                            value = sprintf('%d,', unicode2native(value));
                        end
                        self.call(sprintf('SET %s.serialstring 1', key));
                    elseif (exist('OCTAVE_VERSION', 'builtin') ~= 5)
                        % matlab encoding is terrible
                        % it's a must have, otherwise it's not possible to
                        % save special characters from matlab
                        value = sprintf('%d,', unicode2native(value));
                        self.call(sprintf('SET %s.serialstring 1', key));
                    end%if isspace

                    ret = self.call(sprintf('SET %s %s', key, value));

                end%if check classtype
            else
                error('Input "key" must be a whitespace-free string')
            end

        end%set

        function ret = get(self, key)

            if ischar(key) && (0 == any(isspace(key)))
                ret = self.call(sprintf('GET %s', key));
                if self.exists([key '.serialstring'])
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

        function ret = incr(self, key)

            ret = self.call(['INCR ' key]);

        end%incr

        function ret = decr(self, key)

            ret = self.call(['DECR ' key]);

        end%decr

        function ret = ping(self)

            ret = self.call('PING');

        end%ping

        function ret = del(self, varargin)

            %let's hope every input is a whitespace-free char
            vars = sprintf('%s ', varargin{:});
            ret = self.call(['DEL ' vars]);

        end%del

        function ret = exists(self, keyname)

            if ischar(keyname) && (0 == any(isspace(keyname)))
                ret = self.call(['EXISTS ' keyname]);
            else
                error('Input must be a whitespace-free string')
            end

        end%exists

        function ret = type(self, keyname)

            if ischar(keyname) && (0 == any(isspace(keyname)))
                ret = self.call(['TYPE ' keyname]);
            else
                error('Input must be a whitespace-free string')
            end

        end%type

        %% TODO SUBCLASS
        function self = pipeline(self, command)

            persistent count
            if isempty(count)
                count = 0;
            end

            if ischar(command)
                count = count + 1;
                self.swap{count, 1} = command;

                if (count == self.batchsize)
                    self = self.pipeline(true);
                end

            elseif (command)
                self.call(self.swap(~cellfun('isempty',self.swap)));
                count = 0;
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

                if (1 == self.exists(varname)) && (0 == self.silentOverwrite)
                    error('KEY %s exists already', varname);
                else
                    self.del(varname, [varname '.values'], [varname '.dimension']);
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

