         local redis = require "resty.redis"
         local red = redis:new()
         local key = ngx.var.key; -- variable with the key to be used in the cache.
         if not key then
             ngx.log(ngx.ERR, "No key provided ", key)
             return ngx.exit(400)
         end 
         red:set_timeout(1000) -- 1 second for connection timeout with Redis.
         local ok, err = red:connect("redis", 6379) -- name resolution should be attached to aws's resolver to resolve ElastiCache hostnames.
         if not ok then
             ngx.log(ngx.ERR, "failed to connect to redis: ", err)
             return ngx.exit(500)
         end 
         local value, err = red:get(key)
         if not value then -- in case of an error trying to retrieve data from cache.
             ngx.log(ngx.ERR, "failed to get redis key: ", err)
             return ngx.exit(500)
         elseif value == ngx.null then -- in case it is cache miss, the request will be forwarded to the backend.
             ngx.log(ngx.ERR, "No key found ", key)
             -- copying the body to guarantee there is no change over the request, unless receiving it from cache if available otherwise pass to backend. 
             local response = ngx.location.capture(
                 '/backend', 
                 { method = ngx.HTTP_GET, always_forward_body = true, copy_all_vars = true }
             )
             ngx.status = response.status
             if response.body then
                 -- this is a strange name for a method to return response body to upstream, but that's the recommended in the openresty documentation.
		 -- https://github.com/openresty/lua-nginx-module#ngxprint
                 ngx.print(response.body) 
             end 
             -- using redis pipeline to guarantee we will execute the whole set of commands.
             red:init_pipeline()
             red:set(key, response.body)
	     -- it is setting time-to-live to 60 seconds. Has to be changed according to each scenario, also could be retrieved from request header .
             -- (https://redis.io/commands/expire)
             red:expire(key, 60)  
             local results, err = red:commit_pipeline()
             if not results then
                 ngx.log(ngx.ERR, "failed to connect to set redis key: ", err)
                return ngx.exit(500)
             end 
         else
             ngx.print(value)
             return ngx.exit(200)
         end
         return ngx.exit(ngx.status)
