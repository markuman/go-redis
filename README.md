# go-redis

go-redis - The GNU Octave redis client


A [Redis](http://redis.io) client for [GNU Octave](http://www.gnu.org/software/octave/), written in pure Octave, using
[instrumen-control](http://octave.sourceforge.net/instrument-control/index.html) package.

This client works by establishing a TCP connection to the specified Redis server and using the [Redis protocol](http://redis.io/topics/protocol).
It's fast. It writes 1*10^6 Values in ~10 seconds (tested on AMD E-450) on localhost.


# Versions

### go-redis [developer Version]

    git clone https://github.com/markuman/go-redis.git

 * (will be go-redis-2.0 one day)
 * some improvements + matlab compatibility (maybe, maybe not...not finished yet)

##### mex

redis.c is a `mex` function using [hiredis](https://github.com/redis/hiredis/).

MATLAB

    mex -lhiredis -I/usr/include/hiredis/ CFLAGS='-Wall -Wextra -fPIC -std=c99 -O4 -pedantic -g' redis.c

GNU OCTAVE

    gcc -fPIC -I /usr/include/octave-3.8.2/octave/ -lm -I /usr/include/hiredis/ -lhiredis -shared redis.c -o redis.mex

Usage

    octave:1> ret = redis("PING")
    ret = PONG
    octave:2> ret = redis(sprintf("SET PI %f", pi))
    ret = OK
    octave:3> ret = redis("GET PI")
    ret = 3.141593
    octave:4> ret = redis("127.0.0.1", "PING")
    ret = PONG
    octave:5> ret = redis("127.0.0.1", 6379, "PING")
    ret = PONG



### go-redis 1.0 [stable]

    git clone https://github.com/markuman/go-redis.git && cd go-redis
    git checkout b8b6b1d

* for Octave >= 3.6, instrument-control >= 0.2, redis >= 2.6


# Documentation

## set and get in go-redis

set can save single values (num or str) or numeric n-dimension Matrix _(and structs of depth one)_.
Furthermore, it is important to know, how go-redis is saving n-dimension Matrix. It use RPUSH (a list of values) in redis and reshape
in octave. But the first(!) value in the RPUSH list is reservated for the dimension of your Matrix. This is important, if you want to use the
values with other applications or programming languages too! E.g. for 4x7 Matrix, the first Value is "4 7 ".

## usage

Make a redis connection:

    r = redis()                 % connect to localhost on port 6379
    r = redis('192.168.1.1')    % connect to 192.168.1.1 on port 6379
    r = redis('foo.com', 4242)  % connect to foo.com on port 4242

Authenticate if needed:

    status = auth(r,'password');

For set are no options. It knows if you want to store a string, a matrice or a single value.

    status = set(r,'keyName',variablename);
    % if you don't name a keyname, the name of the variable will be taken as keyname
    status = set(r,variablename);

For get are no options too

    matrix = get(r,'keyName');

To test the connection or keep your session alive, you can use redisPing

    pong = redisPing(r)

To change the database on the connected redis server, use redisSelect. By default, redisConnection connects to database 0, whitch is the first
database

    feedback = select(r,2); % Connects to the 3rd database

Increase or Decrease Integer Values

    incr(r,'keyname'); % just increase a value without feedback
    tmp = decr(r,'keyname'); % decrease a value and asign the new value to 'tmp' variable in octave

Rename or moving keys

    rename(r,'oldkeyname','newkeyname');

To get the size of the database

    size_of_db = dbsize(r);

Synchronously save the dataset to disk

    reply = save(r);

With command you can use any command with redis. But the output is raw! So you have to parse the output by yourself (redis protocol)! You
just want to use this for debugging. At least, you need two or three arguments (atm very limited)!

    redis 127.0.0.1:6379[1]> keys *
    1) "test"
    2) "wurst"
    ----
    octave:7> command(R,'keys','*')
    ans = *2
    $4
    test
    $5
    wurst

    redis 127.0.0.1:6379> LLEN SportB
    (integer) 3
    ----
    octave:9> command(R,'LLEN', 'SportB')
    ans = :3

    redis 127.0.0.1:6379> ping
    PONG
    ----
    octave:10> command(R,'PING')
    ans = +PONG


# Thanks
* https://github.com/dac922/

