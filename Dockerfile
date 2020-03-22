FROM php:7.4.4-apache-buster

ARG COMPOSER_VERSION="1.9.1"
ARG COMPOSER_CHECKSUM="1f210b9037fcf82670d75892dfc44400f13fe9ada7af9e787f93e50e3b764111"

RUN apt-get update \
 && apt-get install -y --no-install-recommends apt-utils systemd \
 && apt-get install -y --no-install-recommends git gosu ffmpeg \
      optipng pngquant jpegoptim gifsicle libpq-dev libsqlite3-dev locales zip unzip libzip-dev libcurl4-openssl-dev \
      libfreetype6 libicu-dev libjpeg62-turbo libpng16-16 libxpm4 libwebp6 libmagickwand-6.q16-6 \
      libfreetype6-dev libjpeg62-turbo-dev libpng-dev libxpm-dev libwebp-dev libmagickwand-dev mariadb-client less\
 && sed -i '/en_US/s/^#//g' /etc/locale.gen \
 && locale-gen && update-locale \
 && docker-php-source extract \
 && docker-php-ext-configure gd \
      --with-freetype \
      --with-jpeg \
      --with-webp \
      --with-xpm \
 && docker-php-ext-install pdo_mysql pdo_pgsql pdo_sqlite pcntl gd exif bcmath intl zip curl \
 && pecl install redis-5.2.1 \
 && docker-php-ext-enable pcntl gd exif zip curl redis \
 && a2enmod rewrite remoteip \
 && {\
     echo RemoteIPHeader X-Real-IP ;\
     echo RemoteIPTrustedProxy 10.0.0.0/8 ;\
     echo RemoteIPTrustedProxy 172.16.0.0/12 ;\
     echo RemoteIPTrustedProxy 192.168.0.0/16 ;\
     echo SetEnvIf X-Forwarded-Proto "https" HTTPS=on ;\
    } > /etc/apache2/conf-available/remoteip.conf \
 && a2enconf remoteip \
 && curl -LsS https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar -o /usr/bin/composer \
 && echo "${COMPOSER_CHECKSUM}  /usr/bin/composer" | sha256sum -c - \
 && chmod 755 /usr/bin/composer \
 && apt-get autoremove --purge -y \
       libfreetype6-dev libjpeg62-turbo-dev libpng-dev libxpm-dev libvpx-dev libmagickwand-dev \
 && rm -rf /var/cache/apt \
 && docker-php-source delete

RUN useradd -m pixelfed

COPY php.ini /usr/local/etc/php/conf.d/php.ini
COPY apache-config /etc/apache2/sites-available/000-default.conf

COPY pixelfed-setup.service /etc/systemd/system/pixelfed-setup.service
COPY pixelfed-httpd.service /etc/systemd/system/pixelfed-httpd.service
COPY pixelfed-worker.service /etc/systemd/system/pixelfed-worker.service

RUN systemctl enable pixelfed-setup && \
    systemctl enable pixelfed-httpd && \
    systemctl enable pixelfed-worker

USER pixelfed

RUN cd /home/pixelfed && \
    git clone https://github.com/pixelfed/pixelfed && \
    cd pixelfed && \
    composer install && \
    mkdir /home/pixelfed/storage && \
    mkdir /home/pixelfed/bootstrap

COPY httpd.sh /home/pixelfed/httpd.sh
COPY setup.sh /home/pixelfed/setup.sh
COPY worker.sh /home/pixelfed/worker.sh

USER root

ENTRYPOINT [ "/bin/systemd" ]