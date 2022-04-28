#!/bin/bash
set -e

zendphp-env2config.sh -q

# to compensate for unification of FPM and CLI
echo "disable_functions =" > /etc/zendphp/conf.d/00-cli.ini
echo "expose_php = On" >> /etc/zendphp/conf.d/00-cli.ini
echo "memory_limit = -1" >> /etc/zendphp/conf.d/00-cli.ini

# shellcheck source=./ZendPHP-Common.lib
. $(command -v ZendPHP-Common.lib)

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
