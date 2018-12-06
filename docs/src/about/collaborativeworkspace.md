# Collaborative Workspace

You can use `go-redis` as a collaborative workspace for GNU Octave and Matlab.

# Write your (interim) results in GNU Octave or Matlab

    >> m = rand(10,10,10,10,10);
    >> numel(m)
    
    ans =
    
          100000
    
    >> r = redis;
    >> r.precision = 16;
    >> tic, r.array2redis(m); toc
    Elapsed time is 0.206611 seconds.
    >> r.call('keys m*')
    
    ans = 
    
        'm'
        'm.dimension'
        'm.values'
    
    >> sum(sum(sum(sum(sum(m)))))
    
    ans =
    
              50197.9709091746
     
    >> 
    

# Read your (interim) results in GNU Octave or Matlab

    octave:1> r = redis;
    octave:2> tic, m = r.redis2array('m'); toc
    Elapsed time is 0.360481 seconds.
    octave:3> sum(sum(sum(sum(sum(m)))))
    ans =     50197.9709091746
    octave:4> 
