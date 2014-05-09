function obj = redis(host='127.0.0.1', port=6379)

obj = init_fields;
obj = class(obj, 'redis');
obj.redis = tcp(host, port);

end

function obj = init_fields()
    obj.redis=[];
end

