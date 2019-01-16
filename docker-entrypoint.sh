#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

role=${CONTAINER_ROLE:-app}
horizon=${LARAVEL_HORIZON:false}
xdebug=${XDEBUG:false}

# Toggle xdebug
if [ "false" == "$xdebug" ]; then
    sed -i "s/^/;/" /usr/local/etc/php/conf.d/xdebug.ini
    sed -i "s/^/;/" /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
fi

# Use Horizon or plain queues
if [ "$role" = "queue" ]; then
    if [ -z "$horizon" ]; then
        horizon="false"
    fi

    if [ "$horizon" = "false" ]; then
        echo "Running the queue service..."
        cat /etc/supervisor/conf.d/laravel-worker.conf.tpl > /etc/supervisor/supervisord.conf
    fi

    if [ "$horizon" = "true" ]; then
        echo "Running the horizon service..."
        cat /etc/supervisor/conf.d/laravel-horizon.conf.tpl > /etc/supervisor/supervisord.conf
    fi
fi

# Set schedule service
if [ "$role" = "scheduler" ]; then

    # Start cron service
    service cron start
    echo "Running the schedule service..."
    
fi

exec "$@"