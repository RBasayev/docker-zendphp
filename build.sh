#!/bin/bash

# This script will build, test and push images of zendPHP:
#   - CentOS 7
#   - CentOS 8
#   - Ubuntu 20.04
# Why? Because I can.

if [ -z $(echo "$1" | grep -E '7.2|7.3|7.4') ]; then
cat <<EoUsage

$0 <zendPHP version>

The zendPHP version must be one of:
    7.2
    7.3
    7.4
Other versions don't make sense right now. Versions prior to 7.2 require a license from Zend even to be installed (https://www.zend.com/contact-us). I have no plans on pushing these onto my Docker Hub. Version 8 will be built on Docker Hub itself (and only on CentOS 8).

EoUsage
fi

function r-a-c(){
    # Run-And-Check
    # Usage: r-a-c "Short Description" <command with arguments>

    desc=$1
    shift
    "$@"
    code=$?
    if [ "$code" != "0" ]; then
        echo "'$desc' failed (code $code)":
        history | tail -1 |  sed -r "s|^[ 0-9]+r-a-c ['\"]*$desc['\"] |   |"
        exit $code
    else
        echo "'$desc'   ... OK"
    fi
}
# This set is needed for the history to work
set -o history

zVer="$1"
zV="${zVer//.}"
[[ $zV > 73 ]] && latest='-t rbasayev/zendphp:latest'

r-a-c "Building Ubuntu" docker build --build-arg ZENDPHP_VERSION=$zVer $latest -t rbasayev/zendphp:ubuntu20-php$zV -f ubuntu/Dockerfile .
r-a-c "Test: php version" docker run rbasayev/zendphp:ubuntu20-php$zV -r "(PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION == '$zVer') ? exit(0) : exit(1);"
r-a-c "Test: enable Swoole" docker run -e ZENABLE_EXTENSIONS=swoole rbasayev/zendphp:ubuntu20-php$zV php -r 'swoole_version();'
r-a-c "Test: try PHP FPM" docker run rbasayev/zendphp:ubuntu20-php$zV timeout --preserve-status -k 5s 0.5s entry_fpm.sh 2> /dev/null

r-a-c "Building CentOS 7" docker build  --build-arg OS_VERSION=7 --build-arg ZENDPHP_VERSION=$zVer -t rbasayev/zendphp:centos7-php$zV -f centos/Dockerfile .
r-a-c "Test: php version" docker run rbasayev/zendphp:centos7-php$zV -r "(PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION == '$zVer') ? exit(0) : exit(1);"
r-a-c "Test: enable Swoole" docker run -e ZENABLE_EXTENSIONS=swoole rbasayev/zendphp:centos7-php$zV php -r 'swoole_version();'
r-a-c "Test: try PHP FPM" docker run rbasayev/zendphp:centos7-php$zV timeout --preserve-status -k 5s 0.5s entry_fpm.sh 2> /dev/null

r-a-c "Building CentOS 8" docker build  --build-arg OS_VERSION=8 --build-arg ZENDPHP_VERSION=$zVer -t rbasayev/zendphp:centos8-php$zV -f centos/Dockerfile .
r-a-c "Test: php version" docker run rbasayev/zendphp:centos8-php$zV -r "(PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION == '$zVer') ? exit(0) : exit(1);"
r-a-c "Test: enable Swoole" docker run -e ZENABLE_EXTENSIONS=swoole rbasayev/zendphp:centos8-php$zV php -r 'swoole_version();'
r-a-c "Test: try PHP FPM" docker run rbasayev/zendphp:centos8-php$zV timeout --preserve-status -k 5s 0.5s entry_fpm.sh 2> /dev/null

r-a-c "Login to Docker Hub" docker login -u $DHUB_USER -p $DHUB_TOKEN

[[ -n "$latest" ]] && docker push rbasayev/zendphp:latest
docker push rbasayev/zendphp:ubuntu20-php$zV
docker push rbasayev/zendphp:centos7-php$zV
docker push rbasayev/zendphp:centos8-php$zV

