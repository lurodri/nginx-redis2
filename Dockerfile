FROM nginx:alpine AS builder

# nginx:alpine contains NGINX_VERSION environment variable, like so:
ENV NGINX_VERSION 1.21.6
ENV OPENRESTY_VERSION 1.19.9.1
ENV REDIS2_MODULE_VERSION 0.15
ENV SET_MISC_MODULE_VERSION 0.32
ENV DEVEL_KIT 0.3.1

# Download sources
RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz && \
    wget "https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz" -O openresty.tar.gz

# Uncompress sources
RUN tar zxvf  nginx.tar.gz && \
    tar zxvf openresty.tar.gz

# Install base to compile nginx and redis2-module
RUN apk update
RUN apk upgrade
RUN apk add build-base
RUN apk add pcre-dev

COPY nginx.conf /etc/nginx/nginx.conf

RUN cd nginx-${NGINX_VERSION} && \
    ./configure --add-dynamic-module=../openresty-${OPENRESTY_VERSION}/bundle/redis2-nginx-module-${REDIS2_MODULE_VERSION} --add-dynamic-module=../openresty-${OPENRESTY_VERSION}/bundle/ngx_devel_kit-${DEVEL_KIT} --add-dynamic-module=../openresty-${OPENRESTY_VERSION}/bundle/set-misc-nginx-module-${SET_MISC_MODULE_VERSION} --without-http_gzip_module --modules-path=/usr/lib/nginx/modules/ --without-http_gzip_module --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --with-debug --with-cc-opt="-g -O0" && \
    make -j2 && \
    make modules && \
    make install

# ----------- #
# Final Image #
# ----------- #
FROM nginx:alpine

# nginx:alpine contains NGINX_VERSION environment variable, like so:
ENV NGINX_VERSION 1.21.6

# Install base to compile nginx and redis2-module
RUN apk update
RUN apk upgrade
RUN apk add pcre-dev

# Copy compiled assets to final image
COPY --from=builder /nginx-${NGINX_VERSION}/objs/nginx /usr/sbin/nginx
COPY --from=builder /nginx-${NGINX_VERSION}/objs/*.so /usr/lib/nginx/modules/

# Copy entire configuration
COPY --from=builder /etc/nginx/ /etc/nginx/

# Copy original configuration from the builder
COPY --from=builder /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original

# Copy configuration with load_module /usr/lib/nginx/modules/ngx_http_redis2_module.so
COPY nginx.conf /etc/nginx/nginx.conf
COPY localhost.conf /etc/nginx/conf.d/localhost.conf
