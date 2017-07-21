#!/usr/bin/env bash
set -eu -o pipefail

COLOR_NONE='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'

function kill_and_wait() {
	kill -s $1 $2 > /dev/null 2>&1
	while kill -0 $2 > /dev/null 2>&1
	do
		sleep 1
	done
}

function php_start() {
	if [ ! -e /var/run/php/php7.0-fpm.pid ]; then
		echo -en "Starting php-fpm7.0 ... "
		php-fpm7.0 --fpm-config /etc/php/7.0/fpm/php-fpm.conf -R
		echo -e "[${COLOR_GREEN}ok${COLOR_NONE}]"
	fi
}

function php_stop() {
	if [ -e /var/run/php/php7.0-fpm.pid ]; then
		echo -en "Stopping php-fpm7.0 ... "
		kill_and_wait SIGTERM `cat /var/run/php/php7.0-fpm.pid`
		echo -e "[${COLOR_GREEN}ok${COLOR_NONE}]"
	fi
}

function apache_start() {
	if [ ! -e /var/run/apache2/apache2.pid ]; then
		echo -en "Starting apache ... "
		apachectl start
		echo -e "[${COLOR_GREEN}ok${COLOR_NONE}]"
	fi
}

function apache_stop() {
	if [ -e /var/run/apache2/apache2.pid ]; then
		echo -en "Stopping apache ... "
		apachectl stop
		echo -e "[${COLOR_GREEN}ok${COLOR_NONE}]"
	fi
}

function cron_start() {
	if [ ! -e /var/run/crond.pid ]; then
		echo -en "Starting cron ... "
		cron
		echo -e "[${COLOR_GREEN}ok${COLOR_NONE}]"
	fi
}

function cron_stop() {
	if [ -e /var/run/crond.pid ]; then
		echo -en "Stopping cron ... "
		kill_and_wait SIGTERM `cat /var/run/crond.pid`
		echo -e "[${COLOR_GREEN}ok${COLOR_NONE}]"
	fi
}

function init() {
	exec > >(setsid bash -c "printf -- \"-\$\$\" > /var/run/tee.pid; tee -ai /var/log/ubuntu-apache-php-root.log")
	exec 2>&1
	export STDERR_PID=$!

	local start_time=`date "+%Y-%m-%d %H:%M:%S"`
	echo -e "\n\n--------------------------------------------------------------------------------";
	echo -e "$start_time: log start";
	echo -e "--------------------------------------------------------------------------------";
	
	trap cleanup_on_exit SIGHUP SIGINT SIGTERM
	
	echo -en "Initializing ... "

	mkdir -p /var/run/apache2 /run/php /var/log/apache2
	chmod 0775 /var/log
	
	echo -e "[${COLOR_GREEN}ok${COLOR_NONE}]"

	php_start
	apache_start
	cron_start

	if type -t on_init > /dev/null; then
		on_init
	fi
	
	echo "Startup sequence complete."
}

function cleanup_on_exit() {
	echo -e "\nExit signal received. Shutting down the service."

	if type -t on_exit > /dev/null; then
		on_exit
	fi
	
	cron_stop
	apache_stop
	php_stop
	
	echo "Shutdown sequence complete."
	
	local end_time=`date "+%Y-%m-%d %H:%M:%S"`
	echo -e "--------------------------------------------------------------------------------"
	echo -e "$end_time: log end";
	echo -e "--------------------------------------------------------------------------------";
	
	kill_and_wait SIGTERM $STDERR_PID
	exec 2>/dev/null
	kill_and_wait SIGKILL $(< /var/run/tee.pid)
	
	exit
}

init

while true; do
	sleep 1
	if type -t on_tick > /dev/null; then
		on_tick
	fi
done
