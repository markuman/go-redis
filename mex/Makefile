octave_version := $(shell octave --version|head -n 1|awk '{ print $$4 }')

build:
	echo "using ${octave_version}"
	gcc -fPIC -std=c++11 -I /usr/include/octave-${octave_version}/octave/ -lm -I /usr/include/hiredis/ -lhiredis -shared -O2 -pedantic redis_.cpp -o redis_.mex
	cp redis_.mex ../inst/redis_.mex

test:
	echo "YES" | octave-cli --eval 'quit(or(0, mUnittest("test_redis")))'
