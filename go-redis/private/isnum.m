% originaly taken from: http://rosettacode.org/wiki/Determine_if_a_string_is_numeric#Octave
% ...small changes for being matlab compatible
function r = isnum(a)
  if ( isnumeric(a) )
    r = 1;
  else
    o = str2double(a);
    r = ~isnan(o);
  end
end
