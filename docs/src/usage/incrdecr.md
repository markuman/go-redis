### INCR, DECR
`r.incr(key)` `r.incrby(key, double)` `r.incrbyfloat(key, double)`
`r.decr(key)` `r.decrby(key, double)`

* `r.precision` will handle the decimal places for `*by...` command.
* return type will be double.

        ret = r.incr('go-redis')

        ret = 2