#!/usr/bin/env bash
set -eu -o pipefail
mkdir -p /run/php
php-fpm7.0 --fpm-config /etc/php/7.0/fpm/php-fpm.conf -R
cron
apachectl -DFOREGROUND
