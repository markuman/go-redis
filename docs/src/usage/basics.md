# basics

## initialize redis class

`redis()` class is using inputParser, so you can switch inputarguments as you like

    >> help redis
     redis mex client for Matlab and GNU Octave
      r = redis()
      r = redis('hostname', '127.0.0.1')
      r = redis('port', 6379)
      r = redis('dbnr', 0)
      r = redis('password', 'foobar')
      r = redis('precision', 16)
      r = redis('batchsize', 128)
      r = redis('hostname', 'some.domain', 'password', 'thisone')

## properties

#### public (can be change during the session)

 * `precision`
   * type double
   * default: `4`
   * number of decimal points stored in `array2redis()`
 * `batchsize`
   * type double
   * default: `64`
   * when number of commands in `pipeline` == `batchsize`, it automatically execute the `pipeline`.
 * `verboseCluster`
   * boolean
   * default: `false`
   * prints information when changing the instance in a cluster like `MOVED 6373 127.0.0.1:30002`

#### private (can't be change during the session)

 * `hostname`
   * type char
   * default: `127.0.0.1`
 * `port`
   * type double
   * default: `6379`
 * `db`
   * type double
   * default: `0`
   * database number to use
 * `pwd`
   * type char
   * default: empty
   * auth password

## make a connection

    >> r = redis()
    
    r = 
    
      redis with properties:
    
             precision: 4
            batchsize: 64
       verboseCluster: 1


### ping the redis server

        ret = r.ping

        ret =

        PONG

### close the connection
    >> r.delete()
