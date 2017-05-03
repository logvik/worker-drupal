FROM php:7.1-fpm

MAINTAINER Viktorov Konstantin "e@logvik.com"
ENV DEBIAN_FRONTEND noninteractive

# Update system
RUN \
  apt-get update && \
  apt-get install -y \
  apt-utils \
  curl \
  logrotate \
  g++ \
  wget \
  git

RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
    echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
    wget -O- http://www.dotdeb.org/dotdeb.gpg | apt-key add -

RUN \
  apt-get update && \
  apt-get install -y \
  locales \
  iptables \
  nano

# Ensure UTF-8
# RUN locale-gen en_US.UTF-8
# ENV LANG       en_US.UTF-8
# ENV LC_ALL     en_US.UTF-8

# Prevent restarts when installing
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Basic packages
RUN \
  apt-get -y install \
  re2c \
  php-pear \
  openssl \
  libc-client-dev \
  libkrb5-dev \
  libxml2-dev \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libmcrypt-dev \
  libpng12-dev \
  libc-client-dev \
  libkrb5-dev \
  libgd-dev \
  libicu-dev \
  libbz2-dev \
  libcurl4-openssl-dev
  
RUN docker-php-ext-install dom curl iconv intl mcrypt mysqli pdo_mysql curl json zip mbstring bz2 \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install gd \
	&& docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
	&& docker-php-ext-install imap \
	&& docker-php-ext-configure bcmath \
	&& docker-php-ext-install bcmath \
	&& docker-php-ext-configure opcache --enable-opcache --enable-opcache-file \
	&& docker-php-ext-install opcache 

RUN apt-get install -y php7.0-dev

RUN pecl channel-update pecl.php.net
RUN pecl install redis mongodb \
     && docker-php-ext-enable redis \
     && docker-php-ext-enable mongodb

RUN printf "\n" | pecl install -f apcu \
     && docker-php-ext-enable apcu

RUN apt-get -y install supervisor mailutils mysql-client

#Install jsmin
RUN cd /tmp \
	&& git clone -b feature/php7 https://github.com/sqmk/pecl-jsmin.git \
	&& cd /tmp/pecl-jsmin \
	&& phpize \
	&& ./configure \
	&& make \
	&& make install clean \
	&& docker-php-ext-enable jsmin \
	&& rm -R /tmp/*

#Tune for opcache
RUN mkdir -p /var/opt/opcache
ADD ./config/php/opcache.ini /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

#Install composer
RUN /usr/bin/curl -sS https://getcomposer.org/installer | /usr/local/bin/php
RUN /bin/mv composer.phar /usr/local/bin/composer

# Install Composer and Drush
RUN /usr/local/bin/composer self-update
RUN /usr/local/bin/composer global require drush/drush:8.*
RUN ln -s /root/.composer/vendor/drush/drush/drush /usr/local/bin/drush

#Install Shadow deamon Firewall
RUN cd /tmp && git clone https://github.com/zecure/shadowd_php.git
RUN mkdir -p /usr/share/shadowd/php && cp -R /tmp/shadowd_php/src/* /usr/share/shadowd/php
RUN rm -R /tmp/shadowd_php

#Install Tideways
RUN echo 'deb http://s3-eu-west-1.amazonaws.com/qafoo-profiler/packages debian main' > /etc/apt/sources.list.d/tideways.list && \
    curl -sS 'https://s3-eu-west-1.amazonaws.com/qafoo-profiler/packages/EEB5E8F4.gpg' | apt-key add - && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq install tideways-php && \
    apt-get autoremove --assume-yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

### Add configuration files
# Supervisor
ADD ./config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Tideways
ADD ./config/php/tideways.ini /usr/local/etc/php/conf.d/docker-php-ext-tideways.ini

# PHP
RUN mkdir -p /var/log/php-fpm
RUN rm /usr/local/etc/php-fpm.d/docker.conf \
    && rm /usr/local/etc/php-fpm.d/www.conf.default \
    && rm /usr/local/etc/php-fpm.d/zz-docker.conf
ADD ./config/php/www.conf /usr/local/etc/php-fpm.d/www.conf
ADD ./config/php/php.ini /usr/local/etc/php/php.ini
ADD ./config/php/php-fpm.conf /usr/local/etc/php-fpm.conf

# Shadow deamon
ADD ./config/shadowd/connectors.ini /etc/shadowd/connectors.ini

# Deploy from git
COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

# Prepare directory
#RUN rm -R /var/www
#RUN mkdir -p /var/www
RUN chown -R www-data:www-data /var/www
WORKDIR /var/www

# Define mountable directories.
VOLUME ["/opt/logs", "/var/www"]

# Add logrotate
ADD ./config/logrotate/php-fpm /etc/logrotate.d/php-fpm

# Cron
CMD ["service", "cron", "restart"]

# Supervisord
CMD ["/usr/bin/supervisord", "-n"]

EXPOSE 9000