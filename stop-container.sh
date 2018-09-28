#!/bin/sh

# Stop PHP
kill -s TERM $(cat /run/php/php7.2-fpm.pid)

# Stop nginx
nginx -s stop
