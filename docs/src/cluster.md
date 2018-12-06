### CLUSTER 

`go-redis` support the redis-cluster automatically (when the redis instance is a cluster).

        >> r = redis('127.0.0.1', 30001)
        
        r = 
        
          redis with properties:
        
                 precision: 4
                 batchsize: 64
            verboseCluster: 1
        
        >> r.get('Z')
        MOVED 15295 127.0.0.1:30003
        
        ans =
        
        5
        
        >> r.get('A')
        MOVED 6373 127.0.0.1:30002
        
        ans =
        
        4
        
        >> r.verboseCluster = false;
        >> r.set('Z', 7)
        
        ans =
        
        OK
        
        >> r.get('Z')
        
        ans =
        
        7
