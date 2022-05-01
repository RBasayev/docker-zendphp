#!/bin/bash
set -e

# renaming so that $PHP_D_PATH is set to the CLI scan dir (see ZendPHP-Common.lib)
mv /usr/sbin/php-fpm /usr/sbin/php-fpm-BAK

# shellcheck source=./ZendPHP-Common.lib
. $(command -v ZendPHP-Common.lib)

zendphp-env2config.sh -q

# to compensate for unification of FPM and CLI
echo "disable_functions =" > $PHP_D_PATH/00-cli.ini
echo "expose_php = On" >> $PHP_D_PATH/00-cli.ini
echo "memory_limit = -1" >> $PHP_D_PATH/00-cli.ini

exec_cmd="exec"
if [ "$1" == "--drop2web" ]; then
	# same, but without root processes at all
	chown -R zendphp:zendphp /var/www/site
	exec_cmd="exec gosu zendphp"
	shift
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	$exec_cmd php "$@"
fi

$exec_cmd "$@"
