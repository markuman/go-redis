# go-redis

go-redis - **G**NU **O**ctave **redis** client

...but Matlab is supported too. When I doesn't support Matlab, someone else will do and I have to emulate it with Octave.

Tested with Linux and Mac OS X.


# Requirements

* Classdef support
  * Octave >= 4.0 _yeah, not released yet! :)_
  * Matlab >= R2012b? _(dunno when classdef was introduced...)_
* C-Compiler
* [hiredis library](https://github.com/redis/hiredis/)
* Linux or Mac OS X _(never tried with Windows)_


# Build instructions

### Matlab

You can compile it directly in the Matlab commandline.

    mex -lhiredis -I/usr/include/hiredis/ CFLAGS='-Wall -Wextra -fPIC -std=c99 -O2 -pedantic -g' redis_.c

Afterwards mv `redis_.mex*` from `mex` folder into `inst/private` folder.

### GNU Octave

Best way is to compile it from bash

    gcc -fPIC -I /usr/include/octave-3.8.2/octave/ -lm -I /usr/include/hiredis/ -lhiredis -std=c99 -shared -O2 redis_.c -o redis_.mex

Afterwards mv `redis_.mex` from `mex` folder into `inst/private` folder.

**Currently (3/19/2015) there is a bug in classdef. You have to do `addpath private` in octave as a workaround!**
https://savannah.gnu.org/bugs/?41723


# limitations & todo

* authentication is not supported yet
* write a Makefile and maybe add `hiredis` as a submodule to simplify the setup process



# usage


##### make a connection

        r = redis()
        r =

          redis with properties:

            hostname: '127.0.0.1'
                port: 6379

##### ping the redis server

        ret = r.ping

        ret =

        PONG

##### SET
`r.set(key, value)`
value can be a double or a char. doubles will be converted to char.

        ret = r.set('go-redis', 1)

        ret =

        OK

##### INCR & DECR
`r.incr(key)`

        ret = r.incr('go-redis')

        ret = 2

##### GET
`r.get(key)`
return type will always be a char!

        ret = r.get('go-redis')

        ret =

        2

##### array reply
An array reply will be transformed into a cell array in Octave/Matlab.

        octave:2> r.call('keys *')
        ans =
        {
          [1,1] = b
          [2,1] = A
        }


##### CALL
`r.call(command)`
for debugging and functions which are not directly supported by go-redis.




# deprecated go-redis version

For the older go-redis version - pure written in Octave using
[instrumen-control](http://octave.sourceforge.net/instrument-control/index.html) package - do `git checkout fcf757b`


