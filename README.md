# Nginx Reverse Proxy with Redis Cache as distributed cache
Pretty simple sample of nginx used as reverse proxy with cache with Redis for a backend app. All running on docker compose

## Architecture
![image](https://user-images.githubusercontent.com/6126997/156380795-08238d52-5b12-46e0-bf47-83b00c8b6adb.png)

### 1) Request coming from a caller
All HTTP requests coming from the callers will go thru Ngnix.
### 2) Nginx is used as Reverse Proxy
Nginx uses [OpenResty Lua Module](https://github.com/openresty/lua-nginx-module) to look for the request's response on Redis Cache with [OpenResty Lua Redis](https://github.com/openresty/lua-resty-redis), if it is a cache hit it will contest the request with appropriate cache entry based on its $key. 
### 2) Backend in case of a Cache Miss
Otherwise, if the data is still not cached, Nginx will pass the request as-is to the backend and will store the backend's response on the cache, for the next requests, before sending it back to the caller.

## Run locally with docker-compose
### a) Compile Backend Redis, Java App & Nginx Reverse Proxy
`docker-compose build`
<br>
### b) Run docker compose running both containers
`docker-compose up`

## Test it locally
`curl -v http://localhost/cached`

