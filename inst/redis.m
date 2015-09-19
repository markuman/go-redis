classdef redis < handle
    %redis mex client for Matlab and GNU Octave
    % r = redis()
    % r = redis(hostname)
    % r = redis(hostname, port)
    % r = redis(hostname, port, db)
    % r = redis(hostname, port, db, passwd)
    % r = redis(hostname, port, db, passwd, precision)
    % r = redis(hostname, port, db, passwd, precision, batchsize)

    properties        
        precision
        batchsize
        verboseCluster
    end % properties
    
    properties (SetAccess = private, Hidden = true)
        hostname
        port
        dbnr
        passwd
        objectHandle; % Handle to the underlying C++ redis connection class instance
    end % private hidden properties

    properties (Access = protected)
       swap
       count
       gaussian_hash
       array_hash
       is_cluster
       is_octave
    end % protected access
    
    methods

        %% constructor - construct a new connection to the redis server
        function self = redis(varargin)
            
            % init class variables
            self.port            = 6379;
            self.hostname        = '127.0.0.1';
            self.dbnr            = 0;
            self.passwd          = '';
            self.precision       = 4;
            self.batchsize       = 64;
            self.swap            = cell(self.batchsize,1);
            self.count           = 0;
            self.gaussian_hash   = 'd27dd80c5140dc267180c03888ba933f8fa0324b';
            self.array_hash      = '91f730fc8f3613bd11019977f72ddd205b6d5f85';
            self.is_cluster      = false;
            self.verboseCluster  = true;
            self.is_octave       = true;
            
            if nargin >= 1
                self.hostname    = varargin{1};
            end
            if nargin >= 2
                self.port        = varargin{2};
            end
            if nargin >= 3
                self.dbnr        = varargin{3};
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
            
            % create a new connection to the redis server
            self.objectHandle = redis_('new', self.hostname, self.port, self.dbnr, self.passwd);
            
            % test connection
            if ~strcmp('PONG', self.ping())
                error('cannot ping the redis instance')
            end
            
            % check if connected redis instance is a cluster
            tmp = self.call('CLUSTER INFO');
            if ~isempty(strfind(tmp, 'cluster_'))
                self.is_cluster = true;
            end
            
            if (exist('OCTAVE_VERSION', 'builtin') ~= 5) 
                self.is_octave = false;
            end
            
        end%obj redis

        %% destructor - destroy the C++ redis connection class instance
        function delete(self)
            redis_('delete', self.objectHandle);
        end
        
        % change database number
        function self = db(self, newdbnr)
            if (newdbnr ~= self.dbnr)
                self.dbnr = newdbnr;
                self.objectHandle = redis_('new', self.hostname, self.port, self.dbnr, self.passwd);
            end
        end % changeDB
        
        % change connection to another redis instance in the cluster
        function newobjectHandle = move2cluster(self, newhost, newport)
            self.port           = newport;
            self.hostname       = newhost;
            newobjectHandle     = redis_('new', self.hostname, self.port, self.dbnr, self.passwd);            
        end % changeDB

        %% redis call command
        % for debugging and not directly supported redis functions
        function ret = call(self, command)
            % command can be a single string, but than, keynames and values
            % are not whitespace-safe
            % when the command it a cell, separated in command, key, value,
            % than everything is whitespace-safe

            ret = redis_('command', self.objectHandle, command);

            if self.is_cluster
                if ~isempty(strfind(ret, 'MOVED '))
                    if (self.verboseCluster), disp(ret), end
                    newport = regexp(ret, ':(\d+)', 'tokens');
                    newport = str2double (newport{1});
                    newhost = regexp(ret, '.*? \d+ (.*?):', 'tokens');                    
                    newhost = cell2mat (newhost{1});

                    self.objectHandle = self.move2cluster(newhost, newport);
                    ret = self.call(command);
                end                
            end

        end%call

        %% redis functions
        function ret = set(self, key, value)
            if ischar(key)
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

        function ret = getset(self, key, value)
            if ischar(key)
                if isnumeric(value)
                    ret = self.call({'GETSET', key, num2str(value, self.precision) });
                elseif ischar(value)
                    ret = self.call({'GETSET', key, value});
                else
                    error('value must be a char or numeric')
                end
            else
                error('key must be a char')
            end
        end%set

        function ret = append(self, key, value)
            if ischar(key)
                if ischar(value)
                    ret = self.call({'APPEND', key, value});
                else
                    error('value must be a char')
                end
            else
                error('key must be a char')
            end
        end%append

        function ret = get(self, key)

            if ischar(key)
                ret = self.call({'GET', key});
            else
                error('keyname must be a whitespace-free string')
            end

        end%get

        function ret = incr(self, key)
            ret = self.call({'INCR', key});
        end%incr

        function ret = incrby(self, key, value)
            ret = self.call({'INCRBY', key, num2str(value)});
        end%incrby

        function ret = incrbyfloat(self, key, value)
            ret = self.call({'INCRBYFLOAT', key, num2str(value)});
        end%incrbyfloat

        function ret = decr(self, key)
            ret = self.call({'DECR', key});
        end%decr

        function ret = decrby(self, key, value)
            ret = self.call({'DECRBY', key, num2str(value)});
        end%decrby

        function ret = strlen(self, key)
            ret = self.call({'STRLEN', key});
        end%strlen

        function ret = ping(self)
            ret = self.call('PING');
        end%ping

        function ret = save(self)
            ret = self.call('SAVE');
        end%save

        function ret = del(self, varargin)
            ret = self.call({'DEL', varargin{:}});
        end%del

        function ret = rename(self, oldkeyname, newkeyname)
            if ischar(oldkeyname) && ischar(newkeyname)
                ret = self.call({'RENAME', oldkeyname, newkeyname});
            else
                error('keynames have to be chars')
            end
        end%rename

        function ret = move(self, keyname, db)
            if ischar(keyname)
                ret = self.call({'MOVE', keyname, num2str(db)});
            else
                error('keynames have to be chars')
            end
        end%move

        function ret = exists(self, keyname)
            if ischar(keyname)
                ret = self.call({'EXISTS', keyname});
            else
                error('Input must be a char')
            end
        end%exists

        function ret = type(self, keyname)
            if ischar(keyname)
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
            elseif iscell(command)
                self.count = self.count + 1;
                self.swap(self.count, 1:size(command,2)) = command;
                
                if (self.count == self.batchsize)
                    self = self.pipeline(true);
                end
                
            elseif (command)
                emptyInd = ~cellfun(@isempty, self.swap(:,1));
                % self.call(self.swap(~cellfun('isempty',self.swap)));
                self.call(self.swap(emptyInd, :));
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

            if self.is_octave && (nargin == 2)
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
                    self.del(varname);
                    self.del([varname '.values']);
                    self.del([varname '.dimension']);
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

        function ret = numel(self, keyname)
            % determine number of elements in an Octave/Matlab array
            dimensionVar    = self.exists([keyname '.dimension']);
            if (dimensionVar)
                dimension   = self.call(sprintf('LRANGE %s.dimension 0 -1', keyname));
                ret = prod(str2double(dimension)');
            else
                % keyname is not an Octave/Matlab array
                ret = NaN;
            end
        end%numel

        function ret = size(self, keyname)
            % determine size of an Octave/Matlab array
            dimensionVar    = self.exists([keyname '.dimension']);
            if (dimensionVar)
                dimension   = self.call(sprintf('LRANGE %s.dimension 0 -1', keyname));
                ret = str2double(dimension)';
            else
                % keyname is not an Octave/Matlab array
                ret = NaN;
            end
        end%size

        function ret = range2array(self, keyname, varargin)

            dimensionVar    = self.exists([keyname '.dimension']);
            if (dimensionVar)
                origin_dimension   = self.call(sprintf('LRANGE %s.dimension 0 -1', keyname));

                % only 2D and 3D arrays are supported!!!
                if numel(varargin) == 2
                    % build linear indizes of origin array stored in redis
                    [x, y]          = meshgrid(varargin{1}, varargin{2});
                    origin_pairs    = [x(:) y(:)];
                    origin_linInd   = sub2ind(str2double(origin_dimension), origin_pairs(:,1), origin_pairs(:,2));
                    % build dimension of reguested range
                    dimension       = [numel(varargin{1}), numel(varargin{2})];
                    [nx, ny]        = meshgrid(varargin{1} - min(varargin{1}) + 1, varargin{2} - min(varargin{2}) + 1);
                    pairs           = [nx(:) ny(:)];
                    linInd          = sub2ind(max(pairs), pairs(:,1), pairs(:,2));
                elseif numel(varargin) == 3
                    [x, y, z]       = meshgrid(varargin{1}, varargin{2}, varargin{3});
                    origin_pairs    = [x(:) y(:) z(:)];
                    origin_linInd   = sub2ind(str2double(origin_dimension)', origin_pairs(:,1), origin_pairs(:,2), origin_pairs(:,3));
                    dimension       = [numel(varargin{1}), numel(varargin{2}), numel(varargin{3})];
                    [nx, ny, nz]    = meshgrid(varargin{1} - min(varargin{1}) + 1, varargin{2} - min(varargin{2}) + 1, varargin{3} - min(varargin{3}) + 1);
                    pairs           = [nx(:) ny(:) nz(:)];
                    linInd          = sub2ind(max(pairs), pairs(:,1), pairs(:,2), pairs(:,3));
                else
                    error('error')
                end

                tmp    = zeros(numel(origin_linInd),1);
                % matlab/octave index starts by 1, redis index starts by 0.
                % maybe this can be improved. sort origin_linInd and read
                % indices in blocks with lrange
                for n = 1:numel(origin_linInd)
                    tmp(n) = str2double(self.call({'LINDEX', [keyname '.values'], num2str(origin_linInd(n) - 1)}));
                end%for

                if numel(dimension) == 2
                    % lol
%                     ret = reshape(tmp, flip(dimension))';
                    ret = NaN(max(pairs));
                    ret(linInd) = tmp;
                    ret(isnan(ret)) = [];
                    ret = reshape(ret, dimension);

                else
                    ret = NaN(max(pairs));
                    ret(linInd) = tmp;
                    ret(isnan(ret)) = [];
                    ret = reshape(ret, dimension);
                end
            end
        end%range2array

        %% HIGH EXPERIMENTAL
        % https://github.com/markuman/go-redis/wiki/Gaussian-elimination
        function ret = gaussian(self, a, b)
            retVar = self.call(sprintf('EVALSHA %s 2 %s %s', self.gaussian_hash, a, b));
            ret = self.redis2array(retVar);
        end

        function ret = rand(self, key, varargin)
            dimension = cell2mat(varargin);
            n         = prod(dimension);
            if (1 == self.exists(key))
                self.del(key);
                self.del([key '.values']);
                self.del([key '.dimension']);
            end
            assert(self.call(sprintf('EVALSHA %s 1 %s rand %d', self.array_hash, key, n)) == 0, 'Looks like createArrays.lua isn''t loaded into your redis instance');
            % save dimension in a key
            assert(self.call(sprintf('RPUSH %s.dimension %s', key, num2str(dimension))) == numel(dimension), 'failed to save dimension of the array');
            % group values and dimension
            assert(self.call(sprintf('SADD %s %s.values %s.dimension', key, key, key)) == 2, 'failed to group dimension list and values list');
            ret = true;
        end%rand

        function ret = ones(self, key, varargin)
            dimension = cell2mat(varargin);
            n         = prod(dimension);
            if (1 == self.exists(key))
                self.del(key);
                self.del([key '.values']);
                self.del([key '.dimension']);
            end
            assert(self.call(sprintf('EVALSHA %s 1 %s ones %d', self.array_hash, key, n)) == 0, 'Looks like createArrays.lua isn''t loaded into your redis instance');
            % save dimension in a key
            assert(self.call(sprintf('RPUSH %s.dimension %s', key, num2str(dimension))) == numel(dimension), 'failed to save dimension of the array');
            % group values and dimension
            assert(self.call(sprintf('SADD %s %s.values %s.dimension', key, key, key)) == 2, 'failed to group dimension list and values list');
            ret = true;
        end%ones

        function ret = zeros(self, key, varargin)
            dimension = cell2mat(varargin);
            n         = prod(dimension);
            if (1 == self.exists(key))
                self.del(key);
                self.del([key '.values']);
                self.del([key '.dimension']);
            end
            assert(self.call(sprintf('EVALSHA %s 1 %s zeros %d', self.array_hash, key, n)) == 0, 'Looks like createArrays.lua isn''t loaded into your redis instance');
            % save dimension in a key
            assert(self.call(sprintf('RPUSH %s.dimension %s', key, num2str(dimension))) == numel(dimension), 'failed to save dimension of the array');
            % group values and dimension
            assert(self.call(sprintf('SADD %s %s.values %s.dimension', key, key, key)) == 2, 'failed to group dimension list and values list');
            ret = true;
        end%zeros

        function self = loadGaussian(self, file)
            fid = fopen(file,'r');
            if fid >= 3
                luastring = fread (fid, 'char=>char').';
                self.gaussian_hash = self.call({'SCRIPT', 'LOAD', luastring});
                fclose(fid);
            else
                error('failed to load file private/gaussian.lua')
            end%if
        end%function

        function self = loadcreateArrays(self, file)
            fid = fopen(file,'r');
            if fid >= 3
                luastring = fread (fid, 'char=>char').';
                self.array_hash = self.call({'SCRIPT', 'LOAD', luastring});
                fclose(fid);
            else
                error('failed to load file private/gaussian.lua')
            end%if
        end%function

    end%methods

end%classdef

