% test go-redis

% using host: 127.0.0.1
% using port 6379
% !! caution !! -- this will flush the database
str = input('This test will delete all databases of your redis instance on 127.0.0.1 6379.\n To continue type "YES": ','s');
if strcmp('YES', str)

    OK = @(x) strcmp('OK', x);

    %% testing redis() class
    setup
    addpath('../inst/')
    r = redis();
    % test basics
    assert(strcmp('PONG',r.ping()))
    assert(OK(r.call('flushall')))
    assert(OK(r.set('A', '1')))
    assert(r.incr('A') == 2)
    assert(strcmp('2', r.getset('A', 3)))
    assert(r.decr('A') == 2)
    assert(strcmp('string', r.type('A')))
    assert(r.exists('A') == 1)
    assert(r.del('A') == 1)
    assert(r.exists('A') == 0)
    assert(iscell(r.call('keys *')))
    assert(iscell(r.call({'keys','*'})))
    % test whitespaces in keys and values
    assert(OK(r.set('B', 'a whitespace value')))
    assert(strcmp('a whitespace value', r.get('B')))
    assert(OK(r.set('B space key', 'a whitespace value')))
    assert(strcmp('a whitespace value', r.get('B space key')))
    assert(r.exists('B space key') == 1)
    % test renameing and moving
    assert(OK(r.rename('B space key', 'B_key')))
    assert(r.exists('B space key') == 0)
    assert(r.exists('B_key') == 1)
    assert(r.move('B_key', 1) == 1)
    assert(r.exists('B_key') == 0)  
    r = r.db(1);
    assert(r.exists('B_key') == 1)
    r = r.db(0);
    % test append strlen and incr* decr* commands
    assert(r.append('mykey', 'O') == 1)
    assert(r.append('mykey', 'K') == 2)
    assert(OK(r.get('mykey')))
    assert(r.strlen('mykey') == 2)
    assert(r.incr('A') == 1)
    assert(r.incrby('A', 9) == 10)
    assert(r.decrby('A', 5) == 5)
    assert(strcmp('5.5', r.incrbyfloat('A', 0.5)))
    % test octave/matlab specific array commands
    assert(r.array2redis(reshape(1:24, 4, []), 'm') == 1)
    assert(all(all(reshape(1:24, 4, []) == r.redis2array('m'))))
    assert(r.numel('m') == 24)
    assert(all(r.size('m') == [4 6]))
    assert(all(all(r.range2array('m', [1 3], 3:5) == [9 13 17; 11 15 19])))
    assert(all(all(r.range2array('m', 1:3, 3:5) == [9 13 17; 10 14 18; 11 15 19])))
    assert(r.array2redis(reshape(1:27, 3, 3, 3), 'm') == 1)
    assert(all(all(all(reshape(1:27, 3, 3, 3) == r.redis2array('m')))))
    assert(r.numel('m') == 27)
    assert(all(r.size('m') == [3 3 3]))
    assert(all(all(r.range2array('m', [1 3], 1:3, 1) == [1 4 7; 3 6 9])))
    assert(all(all(all(r.range2array('m', [1 3], 1:3, 1:2) == cat(3,[1 4 7;3 6 9],[10 13 16;12 15 18])))))
    %% PIPELINE TEST
    assert(OK(r.call('SET M 0')))
    for n = 1:642
        r.call('INCR M');
    end
    assert(str2double(r.get('M')) == 642)
    
    assert(OK(r.call('SET M 0')))
    for n = 1:642
        r = r.pipeline('INCR M');
    end
    r = r.execute();
    assert(str2double(r.get('M')) == 642)
    
    for n = 1:642
        r = r.pipeline('SET M 5');
    end
    r = r.execute();
    assert(str2double(r.get('M')) == 5)
    
    assert(OK(r.call('SET M 0')))
    for n = 1:642
        r = r.pipeline({'INCR', 'M'});
    end
    r = r.execute();
    assert(str2double(r.get('M')) == 642)

   % test whitespace values in pipeline    
    r = r.pipeline({'SET', 'KEYNAME', 'WHITE SPACE'});
    r = r.pipeline({'SET', 'test1', '5'});
    r = r.execute();
    assert(strcmp('WHITE SPACE', r.get('KEYNAME')))
    % test mixed input type in pipeline (char, 1x1 cell, 1x2 cell, 1x3 cell)
    r = r.pipeline('SET THIS 0');
    r = r.pipeline('INCR THIS');
    r = r.pipeline({'INCR', 'THIS'});
    r = r.pipeline({'SET', 'PIPELINE', 'OK'});
    r = r.execute();
    assert(str2double(r.get('THIS')) == 2)
    assert(OK(r.get('PIPELINE')))

    % test ZADD and ZRANGE
    assert(r.call('ZADD list 1 some1') == 1)
    assert(r.call({'ZADD' 'list' '2' 'some2'}) == 1)
    assert(r.call('ZADD list 3 some3') == 1)
    k = r.call({'ZRANGE' 'list' '0' '1' 'withscores'});
    assert(strcmp('some11some22', [ k{:} ]))
    
    %% test list
    assert(r.rpush('mylist', 'OK') == 1)
    assert(r.rpush('mylist', 'world2') == 2)
    assert(OK(r.lpop('mylist')))
    assert(r.llen('mylist') == 1)
    assert(r.lpushx('myotherlist', 'hello') == 0)
    assert(r.lpush('mylist', 'hello') == 2)
    



    fprintf('\n everything passed\n')
end
