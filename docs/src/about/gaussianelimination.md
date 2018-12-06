# Gaussian Elimination

### load script permanent into redis

    >> r = r.loadGaussian('go-redis/mex/gaussian.lua');

### general workflow in GNU Octave/Matlab

To solve A*x = b, let's create A and b.

    >> r = redis; % initialize
    >> a = rand(10,10); % create a 10x10 random matrix
    >> b = (1:10)'; % create b
    >> r.array2redis(a); % save a in redis
    >> r.array2redis(b); % save b in redis

### calculate gaussian elimination 

... the calculation is made by lua inside of redis.

    >> tic, x = r.gaussian('a','b'); toc  
    Elapsed time is 0.019226 seconds.  


### compare the result

Result calculated by GNU Octave/Matlab

    >> a\b

    ans =

        2.9227
       11.7630
      -20.2694
       16.8191
        3.1782
        2.1669
        7.7981
       -5.2681
      -19.7751
       22.5863

Result calculated by Lua in Redis



    >> x

    x =

        2.9227
       11.7630
      -20.2694
       16.8191
        3.1782
        2.1669
        7.7981
       -5.2681
      -19.7751
       22.5863

...if you get rounding problems, increase `r.precision` before storing the arrays.

### why?

Ever run out of memory in GNU Octave or Matlab? Well, 
- simple pump your huge matrices into a redis instance on a larger server.
- pray for fast bandwidth
- worry about visualization or varification methodes of those data


