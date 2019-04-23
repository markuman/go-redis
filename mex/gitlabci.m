% test go-redis

OK = @(x) strcmp('OK', x);

%% testing redis() class
addpath('../inst/')
r = redis('hostname', 'redis');
% test basics
assert(strcmp('PONG',r.ping()),
  'ping redis server')
assert(OK(r.call('flushall')),
  'flush database')
assert(OK(r.set('A', '1')),
  'set key "A"')
assert(r.incr('A') == 2,
  'increase key "A"')
assert(strcmp('2', r.getset('A', 3)),
  'get and set key "A"')
assert(r.decr('A') == 2,
  'decreate key "A"')
assert(strcmp('string', r.type('A')),
  'varify type key "A"')
assert(r.exists('A') == 1,
  'A must be exists')
assert(r.del('A') == 1,
  'delete key "A"')
assert(r.exists('A') == 0,
  '"A" must not exists"')
assert(iscell(r.call('keys *')),
  'return value must be a cell')
assert(iscell(r.call({'keys','*'})),
  'test is input type accept type cell')
% test whitespaces in keys and values
assert(OK(r.set('B', 'a whitespace value')),
  'test whitespace value string')
assert(strcmp('a whitespace value', r.get('B')),
  'check if whitespace value string is received correctly')
assert(OK(r.set('B space key', 'a whitespace value')),
  'test whitespace keyname')
assert(strcmp('a whitespace value', r.get('B space key')),
  'test receive whitespace keyname')
assert(r.exists('B space key') == 1,
  'whitespace keyname must exists')
% test renameing and moving
assert(OK(r.rename('B space key', 'B_key')),
  'test key renameing')
assert(r.exists('B space key') == 0,
  'previouse keyname must not exists')
assert(r.exists('B_key') == 1,
  'new keyname must exists')
assert(r.move('B_key', 1) == 1,
  'moving keyname to database 1')
assert(r.exists('B_key') == 0,
  'previouse keyname must not exists')  
r = r.db(1);
assert(r.exists('B_key') == 1,
  'keyname must exists in database 1')
r = r.db(0);
% test append strlen and incr* decr* commands
assert(r.append('mykey', 'O') == 1,
  'appending key with "O"')
assert(r.append('mykey', 'K') == 2,
  'appending key with "K"')
assert(OK(r.get('mykey')),
  'appended key must have value "OK"')
assert(r.strlen('mykey') == 2,
  'test string length command')
assert(r.incr('A') == 1,
  'test increase key')
assert(r.incrby('A', 9) == 10,
  'test increase by command')
assert(r.decrby('A', 5) == 5,
  'test decrease by command')
assert(strcmp('5.5', r.incrbyfloat('A', 0.5)),
  'test increase by float command')
% test octave/matlab specific array commands
assert(r.array2redis(reshape(1:24, 4, []), 'm') == 1,
  'save array to redis')
assert(all(all(reshape(1:24, 4, []) == r.redis2array('m'))),
  'test if array was save correctly with redis2array')
assert(r.numel('m') == 24,
  'array must have 24 elements')
assert(all(r.size('m') == [4 6]),
  'test correct 2D size of saved array')
assert(all(all(r.range2array('m', [1 3], 3:5) == [9 13 17; 11 15 19])),
  'receive a part of array with range2array')
assert(all(all(r.range2array('m', 1:3, 3:5) == [9 13 17; 10 14 18; 11 15 19])),
  'revice a pary or array with different syntax')
assert(r.array2redis(reshape(1:27, 3, 3, 3), 'm') == 1,
  'save 3D array in redis')
assert(all(all(all(reshape(1:27, 3, 3, 3) == r.redis2array('m')))),
  'test if 3D array is saved correctly in redis')
assert(r.numel('m') == 27,
  'saved array must have 27 elements')
assert(all(r.size('m') == [3 3 3]),
  'check for correct dimention of 3D array')
assert(all(all(r.range2array('m', [1 3], 1:3, 1) == [1 4 7; 3 6 9])),
  'read a part of array with range2array')
assert(all(all(all(r.range2array('m', [1 3], 1:3, 1:2) == cat(3,[1 4 7;3 6 9],[10 13 16;12 15 18])))),
  'read a part (but more data in 3rd dimention) with range2array')
%% PIPELINE TEST
assert(OK(r.call('SET M 0')),
  'test raw set command')
for n = 1:642
    r.call('INCR M');
end
assert(str2double(r.get('M')) == 642,
  'test result of multiple raw set commands')

assert(OK(r.call('SET M 0')),
  'prepare variable for pipeline test')
for n = 1:642
    r = r.pipeline('INCR M');
end
r = r.execute();
assert(str2double(r.get('M')) == 642,
  'test result of pipeline set command')

for n = 1:642
    r = r.pipeline('SET M 5');
end
r = r.execute();
assert(str2double(r.get('M')) == 5,
  'test result of pipeline with different inital value')

assert(OK(r.call('SET M 0')),
  'prepare pipeline test with cell input values')
for n = 1:642
    r = r.pipeline({'INCR', 'M'});
end
r = r.execute();
assert(str2double(r.get('M')) == 642,
  'test result of pipeline with cell values')

% test whitespace values in pipeline    
r = r.pipeline({'SET', 'KEYNAME', 'WHITE SPACE'});
r = r.pipeline({'SET', 'test1', '5'});
r = r.execute();
assert(strcmp('WHITE SPACE', r.get('KEYNAME')),
  'test different pipeline commands with cell values')
% test mixed input type in pipeline (char, 1x1 cell, 1x2 cell, 1x3 cell)
r = r.pipeline('SET THIS 0');
r = r.pipeline('INCR THIS');
r = r.pipeline({'INCR', 'THIS'});
r = r.pipeline({'SET', 'PIPELINE', 'OK'});
r = r.execute();
assert(str2double(r.get('THIS')) == 2,
  'mix pipeline input values')
assert(OK(r.get('PIPELINE')),
  'test result if mix pipeline commands')

% test ZADD and ZRANGE
assert(r.call('ZADD list 1 some1') == 1,
  'zadd value')
assert(r.call({'ZADD' 'list' '2' 'some2'}) == 1,
  'zadd more values')
assert(r.call('ZADD list 3 some3') == 1,
  'zadd more values')
k = r.call({'ZRANGE' 'list' '0' '1' 'withscores'});
assert(strcmp('some11some22', [ k{:} ]),
  'read range of list')

%% test list
assert(r.rpush('mylist', 'OK') == 1,
  'rpush list')
assert(r.rpush('mylist', 'world2') == 2,
  'rpush list once more')
assert(OK(r.lpop('mylist')),
  'lpop list')
assert(r.llen('mylist') == 1,
  'list lenth must be 1')
assert(r.lpushx('myotherlist', 'hello') == 0,
  'lpushx list')
assert(r.lpush('mylist', 'hello') == 2,
  'lpush list')

