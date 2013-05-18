# redis-octave beta

This package is ~basically syntax compatible to https://raw.github.com/dantswain/redis-matlab/

A [Redis](http://redis.io) client for GNU/Octave, written in pure Octave, using instrumen-control 0.2.0 package.  Markus Bergholz, markuman@gmail.com 05/2013.

This client works by establishing a TCP connection to the specified Redis server and using the [Redis protocol](http://redis.io/topics/protocol).

timeout is static hardcodet to 5ms! maybe you have to enlarge it, special when your redis server is not localhost!

## Working

* redisConnect
* redisSet 
* redisGet 
* redisAuth

## Not working

* redisGet (For reading strings!)

## Not tested

* redisDisconnection

## ToDo

* redisCommand
* vectorize redisSet for storing matrice (it has got a poore performance for huge matrices atm!)
* handling strings in redisGet
* make it work with matlab too
* implement SMEMBERS
* improve dynamic timeouts

# Example

    octave:459> clear all
    octave:460> R=redisConnection();
    octave:461> redisAuth(R,'foobared');
    octave:462> m=rand(10,10);
    octave:463> format long g
    octave:464> sum(sum(m))
    ans =     50.6336480069586
    octave:465> redisSet(R,'matrix5',m);
    octave:466> redisSet(R,'singleValue5',sum(sum(m)));
    octave:467> clear m
    octave:468> newm=redisGet(R,'matrix5');
    octave:469> sum(sum(newm))
    ans =     50.6336480069586
    octave:470> oldmsum=redisGet(R,'singleValue5')
    oldmsum =     50.6336480069586

# Thanks
* https://github.com/dac922/
