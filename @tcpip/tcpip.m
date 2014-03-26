# matlab compatibility hack
function obj = tcpip(varargin)
  if nargin == 2
    obj = init_fields;
    obj = class(obj, 'tcpip');
    obj.status = tcp(varargin{1}, varargin{2});
  end
end

function obj = init_fields()
  obj.status = [];
end


