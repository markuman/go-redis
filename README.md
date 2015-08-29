# go-redis

go-redis - **G**NU **O**ctave **redis** client

...but Matlab is supported too. When I don't support Matlab, someone else will do and I have to emulate it with Octave.

Tested with Linux and Mac OS X.

For more detailed information next to this `README.md`, take a look at the Wiki

* [Data-Structure](https://github.com/markuman/go-redis/wiki/Data-Structure)
* [Collaborative Workspace](https://github.com/markuman/go-redis/wiki/Collaborative-Workspace)
* [Gaussian Elimination](https://github.com/markuman/go-redis/wiki/Gaussian-elimination)


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

From GNU Octave commandline

    mkoctfile -Wall -Wextra -v -I/usr/include/hiredis --mex redis_.c -lhiredis -std=c99

Afterwards mv `redis_.mex` from `mex` folder into `inst/private` folder.

**Currently (3/19/2015) there is a bug in classdef. You have to do `addpath private` in octave as a workaround!**
https://savannah.gnu.org/bugs/?41723

### Bash

You can compile it in bash too

    gcc -fPIC -I /usr/include/octave-3.8.2/octave/ -lm -I /usr/include/hiredis/ -lhiredis -std=c99 -shared -O2 redis_.c -o redis_.mex


# todo

* write a Makefile and maybe add `hiredis` as a submodule to simplify the setup process
* improve c-code
* still some problems with unicodes...
* more unittests

# limitations

* GNU Octave and Matlab
  * `sscan`/nested cells as return are not supported yet

* GNU Octave
  * there is a bug in classdef. You have to do `addpath private` in octave as a workaround! https://savannah.gnu.org/bugs/?41723
  * `inputname` is currently not supported in a classdef environment. So you have to name you array by yourself when using `array2redis`.



## basics

### initialize redis class

	>> help redis
	 redis mex client for Matlab and GNU Octave
  	r = redis()
  	r = redis(hostname)
  	r = redis(hostname, port)
  	r = redis(hostname, port, db)
  	r = redis(hostname, port, db, pwd)

### properties

 * `hostname`
   * type char
 * `port`
   * type double
 * `db`
   * type double
   * database number to use
 * `pwd`
   * type char
   * auth password
 * `precision`
   * type double
   * number of decimal points
 * `silentOverwrite
   * type boolean
   * default `false` - will never overwrite existing keys


## usage

### make a connection

    >> r = redis()

	r =

           hostname: '127.0.0.1'
               port: 6379
                 db: 0
             passwd: ''
          precision: 4
    silentOverwrite: 0
          batchsize: 64

### ping the redis server

        ret = r.ping

        ret =

        PONG

### SET
`r.set(key, value)`

 * value can be a double or a char
 * doubles will be converted to char
 * if value is a char with whitespaces, it will be serialized. for more informations, take a look at the wiki

        ret = r.set('go-redis', 1)

        ret =

        OK

### INCR & DECR
`r.incr(key)`
return type will be double.

        ret = r.incr('go-redis')

        ret = 2

##### GET
`r.get(key)`
return type will be a char or a double _(depends on the reply of hiredis)_

        ret = r.get('go-redis')

        ret =

        2

### DEL
`r.del(key)`
return will be true or false

        >> r.del('s')

        ans =

             1

### TYPE
`r.type(key)`
return will be a string

        >> r.del('s')

        ans =

             1

### array reply
An array reply will be transformed into a cell array in Octave/Matlab.

        octave:2> r.call('keys *')
        ans =
        {
          [1,1] = b
          [2,1] = A
        }


### CALL
`r.call(command)`

* for debugging 
* functions that are directly supported by redis() class
* for disable the overhead of redis() class functions

### PIPELINE
`r.pipeline(command)` 
`r.execute()` 

Using `r.pipeline` will speedup your writing commands 2-3x.

_But be aware, Currently `pipeline()` is not implemented as a subclass! That means you have to put everything into a string by yourself at the moment._

But the cool thing is: the pipeline is executed automatically when a number of commands is reached. The default value of `r.batchsize` is `64`.
So you just need to call `r.execute()` (Yes, it takes no arguments!) one time when you're done to get execute the rest in your pipeline.

#### pipeline examples
    r = redis();
    r.call('SET M 0');
    tic
    for n = 1:5000
        r.call('INCR M');
    end
    toc
    
    tic
    for n = 1:5000
        r = r.pipeline('INCR M');
    end
    r = r.execute();
    toc
    
    tic
    for n = 1:5000
        r.call('SET M 5');
    end
    toc
    
    tic
    for n = 1:5000
        r = r.pipeline('SET M 5');
    end
    r = r.execute();
    toc


But you can pass a cell array of arguments too, to bypass the class functionality and its magic pipe execution.

    r.call({'SET A 0'; 'INCR A'; 'INCR A'})

### GNU OCtave and Matlab special

#### array2redis
`r.array2redis(array, name)`
For storing a multidimension numeric array in redis

        >> r.array2redis(rand(3,3), 'm')

        ans =

             1

#### redis2array
`r.redis2array(name)`
For reading a multidimension numeric array from redis back into workspace

        >> r.redis2array('m')

        ans =

            0.8147    0.9134    0.2785
            0.9058    0.6324    0.5469
            0.1270    0.0975    0.9575



# deprecated go-redis version

For the older go-redis version - pure written in Octave using
[instrumen-control](http://octave.sourceforge.net/instrument-control/index.html) package - do `git checkout fcf757b`



