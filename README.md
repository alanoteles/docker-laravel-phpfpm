# docker-laravel-phpfpm
Docker-compose script to build an entire Laravel 5.5> environment, with schedule/cron, queue/horizon and Xdebug. All features can be enabled/disable through environments variables.

To enabled XDEBUG, change the value of `XDEBUG` to "true" inside **phpfpm** section.. If this image will be on a production environment, change to "false".

If you will use queues, you can choose among basic queues service or Laravel Horizon. You can set the `LARAVEL_HORIZON` to "true" or "false", to enable or disable this feature. The queues/Horizon service runs with Redis database.

The Laravel Schedule service runs under Supervisor monitoring.

The queues and schedule service was configured as separated services to simplify the scaling job. You can add more replicas to the services more easily.
