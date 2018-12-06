### SET, GET, GETSET, APPEND
`r.set(key, value)`
`r.get(key)`
`r.getset(key, value)`
`r.append(key, value)`

 * value can be a double or a char (expect `append` there it has to be a char)
 * doubles will be converted to char

        ret = r.set('go-redis', 1)

        ret =

        OK

  * return type of `GET*` commands will be a char or a double _(depends on the reply of hiredis)_