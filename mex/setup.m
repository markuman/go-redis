%% setup 0.2

if (0 == exist('LIBPATH'))
  LIBPATH = '/usr/include/hiredis'; % not used yet
end

% error message
UNIX_ONLY = 'setup script only supports unix systems yet';

if (exist('OCTAVE_VERSION', 'builtin') == 5)
    %% setup for octave follows here
    if isunix
        try
            eval(['mkoctfile -lhiredis -I'LIBPATH ' --mex -fPIC -O3 -pedantic -std=c++11 -g redis_.cpp -o redis_.mex -o ../inst/redis_.mex'])
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
            eval(['mex -lhiredis -I' LIBPATH ' CFLAGS=''-fPIC -O3 -pedantic -std=c++11 -g'' redis_.cpp -o ../inst/private/redis_.mexa64'])
        catch
            error('something went wrong.\n Make sure mex is setup correctly (rerun mex -setup) and you''ve installed hiredis')
        end%try
    else
        error(UNIX_ONLY)
    end%if isunix
    
    
end%if MATLAB|OCTAVE
