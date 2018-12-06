# Requirements

* Classdef support
  * Octave >= 4.0
  * Matlab >= R2012b? _(dunno when classdef was introduced...)_
* C-Compiler
* [hiredis library](https://github.com/redis/hiredis/)
* Linux or Mac OS X _(never tried with Windows)_


# Build instructions

1. install a C compiler
    * Ubuntu: `sudo apt-get install build-essential`
    * Arch:   `sudo pacman -S base-devel`
    * Mac:    Install xcode
2. install [hiredis library](https://github.com/redis/hiredis/)
    * Ubuntu: `sudo apt-get install libhiredis-dev libhiredis0.10` _*for 14.04 LTS_
    * Arch:   `sudo pacman -S hiredis`
    * Mac:    `brew install hiredis`
3. mex.h
    * Distributed with your Matlab or GNU Octave installation
4. clone/download and build go-redis directly from Matlab/GNU Octave

        >> cd go-redis/mex
        >> setup
        >> % go where ever you want and just do "addpath ('go-redis/inst')"

The default path to hiredis is set to `/usr/include/hiredis`. You can change it by set a variable `LIBPATH` with a absolute path to hiredis before running the setup script.

5. optional - run tests

The `mex` folder contains a `test_redis.m` script with many `assert()` checks.

        >> test_redis
        This test will delete all databases of your redis instance on 127.0.0.1 6379.
        To continue type "YES": YES
        
            everything passed
        >> 


### Manually Matlab Instruction

You can compile it directly in the Matlab commandline.

    mex -lhiredis -I/usr/include/hiredis/ CFLAGS='-fPIC -O2 -pedantic -std=c++11 -g' redis_.cpp 

Afterwards mv `redis_.mex*` from `mex` folder into `inst/private` folder.

### Manually GNU Octave Instruction

From GNU Octave commandline

    mkoctfile -lhiredis -I/usr/include/hiredis --mex -fPIC -O2 -pedantic -std=c++11 -g redis_.cpp

Afterwards mv `redis_.mex` from `mex` folder into `inst/private` folder.

**Currently (3/19/2015) there is a bug in classdef. You have to do `addpath private` in octave as a workaround!**
https://savannah.gnu.org/bugs/?41723

### Manually Bash Instruction

You can compile it in bash too

    gcc -fPIC -I <PATH TO mex.h> -lm -I <PATH TO hiredis.h> -lhiredis -shared -O2 redis_.cpp -o redis_.mex

e.g.

    gcc -fPIC -std=c++11 -I /usr/include/octave-4.0.0/octave/ -lm -I /usr/include/hiredis/ -lhiredis -shared -O2 -pedantic redis_.cpp -o redis_.mex
