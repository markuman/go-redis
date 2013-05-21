# redis-octave beta

This package is ~basically syntax compatible to https://raw.github.com/dantswain/redis-matlab/

A [Redis](http://redis.io) client for GNU/Octave, written in pure Octave, using instrumen-control 0.2.0 package.

This client works by establishing a TCP connection to the specified Redis server and using the [Redis protocol](http://redis.io/topics/protocol).

timeout is static hardcodet to 5ms! maybe you have to enlarge it, special when your redis server is not localhost!

## ToDo

* redisCommand
* handling strings in redisGet
* make it work with matlab too (far far away)
* implement SMEMBERS
* redisConnect for switching db inside a redis server

# Example

    octave:222> clear all
    octave:223> R=redisConnection();
    octave:224> redisAuth(R,'foobared');
    octave:225> e=rand(7,3)
    e =
    
       0.708814   0.396919   0.453007
       0.298450   0.194896   0.999266
       0.408579   0.816589   0.423225
       0.665347   0.174414   0.443947
       0.965165   0.565233   0.143128
       0.670602   0.337784   0.923062
       0.269081   0.138536   0.064445
    
    octave:226> redisSet(R,'e',e);
    octave:227> w=redisGet(R,'e');
    octave:228> w          
    w =
    
       0.708814   0.396919   0.453007
       0.298450   0.194896   0.999266
       0.408579   0.816589   0.423225
       0.665347   0.174414   0.443947
       0.965165   0.565233   0.143128
       0.670602   0.337784   0.923062
       0.269081   0.138536   0.064445
   
    octave:229> t=rand(1000,1000);
    octave:230> tic, redisSet(R,'t',t); toc
    Elapsed time is 10.5486 seconds.
    octave:231> 


# Thanks
* https://github.com/dac922/
