# limitations

* `pipeline()` can not handle cluster instances!

* GNU Octave
  * there is a bug in classdef. You have to do `addpath private` in octave as a workaround! https://savannah.gnu.org/bugs/?41723
  * `inputname` is currently not supported in a classdef environment. So you have to name you array by yourself when using `array2redis`.


# todo

* maybe add `hiredis` as a submodule to simplify the setup process?
* improve c-code
* still some problems with unicodes between matlab and GNU Octave (it's a natural problem between octave and matlab)
* improve `pipeline` (subclass)
