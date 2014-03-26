function status = fwrite(obj, data)

  if nargin ~= 2
    error('wrong usage')
    print_help
    return
  end

  status = tcp_write(obj.status, data);

end


function print_help()
     fprintf("Write data to a tcp interface.\n\n")
     fprintf("TCP - instance of OCTAVE_TCP class.\n")
     fprintf("DATA - data to be written to the tcp interface.  Can be either of String or uint8 type.\n")
end
