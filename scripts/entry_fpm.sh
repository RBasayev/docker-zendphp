#!/bin/bash

zendphp-env2config.sh -q

# shellcheck source=./ZendPHP-Common.lib
. $(command -v ZendPHP-Common.lib)

if [ $# -eq 0 ]; then
	exec php-fpm --nodaemonize --force-stderr -y $PHP_D_PATH/../php-fpm.conf
elif [ "$1" == "--drop2web" ]; then
	# same, but without root processes at all
	usermod -aG tty zendphp
	chown -R zendphp:zendphp /var/www/site
	exec gosu zendphp php-fpm --nodaemonize --force-stderr -y $PHP_D_PATH/../php-fpm.conf
elif [ "$1" == "--testFPM" ]; then
	# special option to test the image after build
	php-fpm --daemonize --force-stderr -y $PHP_D_PATH/../php-fpm.conf
	exec timeout --preserve-status -k 3s 0.5s php-fpm-healthcheck
else
	exec "$@"
fi

wait
