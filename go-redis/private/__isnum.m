% http://rosettacode.org/wiki/Determine_if_a_string_is_numeric#Octave
function r = __isnum(a)
  if ( isnumeric(a) )
    r = 1;
  else
    o = str2double(a);
    r = !isnan(o);
  endif
endfunction
