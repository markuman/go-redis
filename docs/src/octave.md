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

#### range2array
`r.range2array(name, x, y, z)`
For reading just a range of an array which is stored in redis.

* it only support 2D and 3D numerical arrays


