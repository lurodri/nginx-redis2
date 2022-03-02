FROM openresty/openresty:alpine

# Install base to compile nginx and redis2-module
#RUN apk update
#RUN apk upgrade
#RUN apk add pcre-dev

# Copy compiled assets to final image
#COPY --from=builder /nginx-${NGINX_VERSION}/objs/nginx /usr/sbin/nginx
#COPY --from=builder /nginx-${NGINX_VERSION}/objs/*.so /usr/lib/nginx/modules/

# Copy entire configuration
#COPY --from=builder /etc/nginx/ /etc/nginx/

# Copy original configuration from the builder
#COPY --from=builder /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original

# Copy configuration with load_module /usr/lib/nginx/modules/ngx_http_redis2_module.so
COPY nginx.conf /etc/nginx/nginx.conf
COPY localhost.conf /etc/nginx/conf.d/default.conf
RUN  mkdir -p /etc/nginx/lua-script/
COPY lua-script/redis.lua /etc/nginx/lua-script/redis.lua
