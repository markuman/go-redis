### PIPELINE
`r.pipeline(command)`
`r.execute()`

Using `r.pipeline` will speedup your writing commands 2-4x.

_But be aware, `pipeline()` is not implemented as a subclass! That means you have to put everything into a string by yourself at the moment._

But the cool thing is: the pipeline is executed automatically when a number of commands is reached. The default value of `r.batchsize` is `64`.
So you just need to call `r.execute()` (Yes, it takes no arguments!) one time when you're done to get execute the rest in your pipeline.

#### pipeline examples
    r = redis();
    r.call('SET M 0');
    tic
    for n = 1:5000
        r.call('INCR M');
    end
    toc

    tic
    for n = 1:5000
        r = r.pipeline('INCR M');
    end
    r = r.execute();
    toc

    tic
    for n = 1:5000
        r.call('SET M 5');
    end
    toc

    tic
    for n = 1:5000
        r = r.pipeline('SET M 5');
    end
    r = r.execute();
    toc


`command` can be a cell array too, like `r = r.pipeline({'INCR', 'A'}); r = r.pipeline({'INCR', 'A'});`.  


But you can pass a cell array of arguments too, to bypass the class functionality and its magic pipe execution.

    r.call({'SET A 0'; 'INCR A'; 'INCR A'})
