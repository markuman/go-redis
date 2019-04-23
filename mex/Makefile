octave_version := $(shell octave --version|head -n 1|awk '{ print $$4 }')

build:
	echo "using ${octave_version}"
	gcc -fPIC -std=c++11 -I /usr/include/octave-${octave_version}/octave/ -lm -I /usr/include/hiredis/ -lhiredis -shared -O2 -pedantic redis_.cpp -o redis_.mex
	cp redis_.mex ../inst/redis_.mex

gitlab_build:
	echo "using ${octave_version}"	
	mkoctfile -lhiredis -I/usr/include/hiredis --mex -fPIC -O3 -pedantic -std=c++11 -g redis_.cpp -o redis_.mex -o ../inst/redis_.mex
	
test:
	echo "YES" | octave-cli --eval 'quit(or(0, mUnittest("test_redis")))'

gitlab_ci_test:
	echo "YES" | octave-cli --eval 'quit(or(0, mUnittest("gitlabci")))'
