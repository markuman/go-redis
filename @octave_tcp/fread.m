function [data, count] = fread(obj, N, timeout)

  [data, count] = tcp_read (obj, N, timeout);

end

function print_help()

  fprintf("[DATA, COUNT] = fwrite (TCP, N, TIMEOUT)\n")

end

