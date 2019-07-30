FROM php:7.2-fpm

# Update packages and install composer and PHP dependencies.
RUN apt-get update && \
    mkdir -p /usr/share/man/man1 && \
    mkdir -p /usr/share/man/man7 && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    postgresql-client \
    libpq-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libbz2-dev \
	unzip \
    cron \
    supervisor \
    && pecl channel-update pecl.php.net \
    && pecl install apcu \
    && pecl install xdebug \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-enable xdebug mcrypt

# 
COPY ./xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# PHP Extensions
RUN docker-php-ext-install zip bz2 pdo_pgsql pdo_mysql pcntl \
&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
&& docker-php-ext-install gd

# Time Zone
RUN echo "date.timezone=${PHP_TIMEZONE:-UTC}" > $PHP_INI_DIR/conf.d/date_timezone.ini

# Display errors in stderr
RUN echo "display_errors=stderr" > $PHP_INI_DIR/conf.d/display-errors.ini

# Disable PathInfo
RUN echo "cgi.fix_pathinfo=0" > $PHP_INI_DIR/conf.d/path-info.ini

# Disable expose PHP
RUN echo "expose_php=0" > $PHP_INI_DIR/conf.d/path-info.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Laravel Schedule Cron Job:
RUN echo "* * * * * root /usr/local/bin/php /var/www/app/artisan schedule:run >> /dev/null 2>&1"  >> /etc/cron.d/laravel-scheduler
RUN chmod 0644 /etc/cron.d/laravel-scheduler

# Aliases
# docker-compose exec php-fpm art --> php artisan
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/artisan "$@"' > /usr/bin/art
RUN chmod +x /usr/bin/art
# docker-compose exec php-fpm migrate --> php artisan migrate
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/artisan migrate "$@"' > /usr/bin/migrate
RUN chmod +x /usr/bin/migrate


# Defines Redis as queue database.
ENV QUEUE_DRIVER=redis
ENV QUEUE_CONNECTION=redis
ENV QUEUE_NAME=default
ENV LARAVEL_HORIZON=false

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Use local configuration
COPY laravel-worker.conf.tpl /etc/supervisor/conf.d/laravel-worker.conf.tpl
COPY laravel-horizon.conf.tpl /etc/supervisor/conf.d/laravel-horizon.conf.tpl

# ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD . /var/www/app
WORKDIR /var/www/app

COPY ./docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN ln -s /usr/local/bin/docker-entrypoint.sh /
ENTRYPOINT ["docker-entrypoint.sh"]

# # Add user for laravel application
# RUN groupadd -g 1000 www
# RUN useradd -u 1000 -ms /bin/bash -g www www

# # Change current user to www
# USER www

# # Copy existing application directory contents
# COPY . /var/www

# # Copy existing application directory permissions
# COPY --chown=www:www . /var/www



EXPOSE 9000
CMD ["php-fpm"]

# CMD ["/bin/sh", "-c", "php-fpm -D | tail -f storage/logs/laravel.log"]
