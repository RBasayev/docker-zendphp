#!/bin/bash

zendphp-env2config.sh -q

# shellcheck source=./ZendPHP-Common.lib
. $(command -v ZendPHP-Common.lib)

if [ $# -eq 0 ]; then
	exec php-fpm --nodaemonize --force-stderr -y $PHP_D_PATH/../php-fpm.conf
elif [ "$1" == "--drop-fpm" ]; then
	# same, but without root processes at all
	chown -R web:site /var/www/site
	exec gosu web php-fpm --nodaemonize --force-stderr -y $PHP_D_PATH/../php-fpm.conf
else
	exec "$@"
fi

wait
