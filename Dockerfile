FROM ubuntu:16.04

MAINTAINER Viktorov Konstantin "e@logvik.com"
ENV DEBIAN_FRONTEND noninteractive

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Update system
RUN apt-get update && apt-get dist-upgrade -y
RUN apt-get install -y nano

# Prevent restarts when installing
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Basic packages
RUN apt-get -y install apt-utils git curl apt-utils php7.0-dev php7.0-fpm php7.0-mysql php7.0-imap php7.0-mcrypt php7.0-curl php7.0-cli php7.0-gd php7.0-pgsql php7.0-sqlite php7.0-common php7.0-json php7.0-zip php7.0-mbstring
RUN pecl channel-update pecl.php.net
RUN pecl install redis jsmin
RUN printf "\n" | pecl install apcu
RUN apt-get -y install supervisor mailutils

#Install apcu
RUN echo "extension=apcu.so" > /etc/php/7.0/fpm/conf.d/20-apcu.ini
RUN echo "extension=apcu.so" > /etc/php/7.0/cli/conf.d/20-apcu.ini

#Install redis
RUN echo "extension=redis.so" > /etc/php/7.0/fpm/conf.d/20-redis.ini
RUN echo "extension=redis.so" > /etc/php/7.0/cli/conf.d/20-redis.ini

#Install jsmin
RUN cd /tmp && git clone -b feature/php7 https://github.com/sqmk/pecl-jsmin.git && cd /tmp/pecl-jsmin && phpize && ./configure && make && make install clean
RUN echo "extension=jsmin.so" > /etc/php/7.0/fpm/conf.d/20-jsmin.ini
RUN echo "extension=jsmin.so" > /etc/php/7.0/cli/conf.d/20-jsmin.ini

# Install Shadow deamon Firewall
RUN cd /tmp && git clone https://github.com/zecure/shadowd_php.git
RUN mkdir -p /usr/share/shadowd/php && cp -R /tmp/shadowd_php/src/* /usr/share/shadowd/php
RUN rm -R /tmp/shadowd_php

# Prepare directory
RUN mkdir -p /var/www
RUN chown -R www-data:www-data /var/www

#Create init directories
RUN service php7.0-fpm start

# Define mountable directories.
VOLUME ["/opt/logs", "/var/www"]

# Prepare directory
RUN mkdir -p /var/www
RUN chown -R www-data:www-data /var/www
WORKDIR /var/www

### Add configuration files
# Supervisor
ADD ./config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# PHP
ADD ./config/php/www.conf /etc/php/7.0/fpm/pool.d/www.conf
ADD ./config/php/php.ini /etc/php/7.0/fpm/php.ini
ADD ./config/php/php-fpm.conf /etc/php/7.0/fpm/php-fpm.conf

# Shadow demon
ADD ./config/shadowd/connectors.ini /etc/shadowd/connectors.ini

# Deploy from git
COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-n"]

EXPOSE 9000