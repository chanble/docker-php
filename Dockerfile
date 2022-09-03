FROM php:7.1-fpm-stretch
COPY pecl/* /tmp/pecl/
RUN  set -ex; \
  savedAptMark="$(apt-mark showmanual)"; \
  echo 'deb http://mirrors.aliyun.com/debian/ stretch main non-free contrib' > /etc/apt/sources.list \
  && echo 'deb-src http://mirrors.aliyun.com/debian/ stretch main non-free contrib' >> /etc/apt/sources.list \
  && echo 'deb http://mirrors.aliyun.com/debian-security stretch/updates main' >> /etc/apt/sources.list \
  && echo 'deb-src http://mirrors.aliyun.com/debian-security stretch/updates main' >> /etc/apt/sources.list \
  && echo 'deb http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib' >> /etc/apt/sources.list \
  && echo 'deb-src http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib' >> /etc/apt/sources.list \
  && echo 'deb http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib' >> /etc/apt/sources.list \
  && echo 'deb-src http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib' >> /etc/apt/sources.list \
  && echo "Asia/Shanghai" > /etc/timezone \
  && apt-get update \
  && apt-get -y --no-install-recommends install \
    libcurl4-openssl-dev \
    libxml2 libxml2-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libmcrypt-dev \
    libmemcached-dev \
  && docker-php-ext-configure gd  --with-freetype-dir=/usr/include/ --with-png-dir=/usr/include/ --with-jpeg-dir=/usr/include/\
  && docker-php-ext-install \
    bcmath \
    exif \
    gd \
    mcrypt \
    mysqli \
    opcache \
    pcntl \
    pdo_mysql \
    shmop \
    soap \
    sockets \
    sysvsem \
    xmlrpc \
    zip \
  # && pecl install https://pecl.php.net/get/yac-2.0.2.tgz https://pecl.php.net/get/memcached-3.0.4.tgz  https://pecl.php.net/get/memcache-4.0.5.2.tgz https://pecl.php.net/get/redis-3.1.6.tgz https://pecl.php.net/get/igbinary-2.0.5.tgz https://pecl.php.net/get/msgpack-2.0.2.tgz https://pecl.php.net/get/mongodb-1.5.3.tgz \
  && yes '' | pecl install /tmp/pecl/yac-2.0.2.tgz /tmp/pecl/memcached-3.0.4.tgz  /tmp/pecl/memcache-4.0.5.2.tgz /tmp/pecl/igbinary-2.0.5.tgz /tmp/pecl/redis-3.1.6.tgz  /tmp/pecl/msgpack-2.0.2.tgz /tmp/pecl/mongodb-1.5.3.tgz \
  && docker-php-ext-enable yac memcache memcached redis igbinary msgpack mongodb \
  && apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
      | awk '/=>/ { print $3 }' \
      | sort -u \
      | xargs -r dpkg-query -S \
      | cut -d: -f1 \
      | sort -u \
      | xargs -rt apt-mark manual; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    apt-get clean ; \
    docker-php-source delete; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*;
WORKDIR /tmp
RUN apt-get update \
  && apt-get -y --no-install-recommends install \
    # nginx 需要
    libpcre3-dev \
    openssl \
    libssl-dev \
    zlib1g-dev \
    net-tools \
    procps \
  && curl -L -O http://tengine.taobao.org/download/tengine-2.2.2.tar.gz \
  && tar zxvf tengine-2.2.2.tar.gz && cd tengine-2.2.2 \
  && ./configure --prefix=/usr/local/nginx --with-pcre  --with-http_sysguard_module --with-http_concat_module \
  && make && make install && cd .. \
  && rm -rf ./* && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

COPY php.ini /usr/local/etc/php/php.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.conf
COPY docker-entrypoint.sh /usr/local/bin/

RUN rm -rf /usr/local/etc/php/php.ini-* /usr/local/etc/php-fpm.d /usr/local/etc/php-fpm.conf.default \
  && chmod +x /usr/local/bin/docker-entrypoint.sh;

EXPOSE 9000

WORKDIR /app