%% setup 0.1
LIBPATH = '/usr/include/hiredis'; % not used yet
UNIX_ONLY = 'setup script only supports unix systems yet';

if (exist('OCTAVE_VERSION', 'builtin') == 5)
    %% setup for octave follows here
    if isunix
        try
            mkoctfile -lhiredis -I/usr/include/hiredis --mex -fPIC -O2 -pedantic -g redis_.cpp -o redis_.mex
        catch
            error('something went wrong\n Make sure you''ve installes octave dev tools and hiredis')
        end%try
    else
        error(UNIX_ONLY)
    end%if isunix
    
else
    %% setup for matlab follows here
    if isunix
        try
            mex -lhiredis -I/usr/include/hiredis/ CFLAGS='-fPIC -O2 -pedantic -g' redis_.cpp -o ../inst/private/redis_.mexa64
        catch
            error('something went wrong.\n Make sure mex is setup correctly (rerun mex -setup) and you''ve installed hiredis')
        end%try
    else
        error(UNIX_ONLY)
    end%if isunix
    
    
end%if MATLAB|OCTAVE
