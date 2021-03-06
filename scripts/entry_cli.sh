#!/bin/bash
set -e

zendphp-env2config.sh -q

# shellcheck source=./ZendPHP-Common.lib
. $(command -v ZendPHP-Common.lib)

exec_cmd="exec"
if [ "$1" == "--drop2web" ]; then
	# same, but without root processes at all
	chown -R web:site /var/www/site
	exec_cmd="exec gosu web"
	shift
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	$exec_cmd php "$@"
fi

$exec_cmd "$@"
