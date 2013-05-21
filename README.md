# redis-octave beta

This package is ~basically syntax compatible to https://raw.github.com/dantswain/redis-matlab/

A [Redis](http://redis.io) client for [GNU/Octave](http://www.gnu.org/software/octave/), written in pure Octave, using 
[instrumen-control](http://octave.sourceforge.net/instrument-control/index.html) 0.2.0 package.

This client works by establishing a TCP connection to the specified Redis server and using the [Redis protocol](http://redis.io/topics/protocol).

## ToDo

* redisCommand (nor tested nor optimized)
* handling strings in redisGet
* make it work with matlab too (far far away)
* implement SMEMBERS (my needs atm)
* redisConnect for switching db inside a redis server
* implement redisPing

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

## redisSet and redisGet

redisSet can save single values (1x1 Matrix), a string or a nxn Matrix. But take care, reading a string (redisGet) is not implemented yet!
Furthermore, it is important to know, how redis-octave is saving a nxn Matrix in redis. It use RPUSH (a list of values) in redis and reshape 
in octave. But the first(!) value in the RPUSH list is reservated for the dimension of your Matrix. This is important, if you want to use the 
values with other applications or programming languages too! 

## usage 

Make a redis connection:
    R = redisConnection()                 % connect to localhost on port 6739
    R = redisConnection('foo.com')        % connect to foo.com on port 6739
    R = redisConnection('foo.com', 4242)  % connect to foo.com on port 4242

Authenticate if needed:
    status = redisAuth(R,'foobared');

For redisSet are no options. I knows if you want to store a string, a matrice or a single value.
    status = redisSet(R,'keyName',variablename);

For redisGet are no options too
    matrix = redisGet(R,'keyName');

# Thanks
* https://github.com/dac922/
