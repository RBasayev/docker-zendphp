#!/bin/bash

function usage(){
    cat <<EoUsage

This script can build, test and push images of zendPHP 7.2-7.4 on CentOS 7, CentOS 8 and Ubuntu 20.04.

auto.sh <action> <PHP ver.>

         build      7.2
          OR         OR
         test       7.3
          OR         OR
         push       7.4

$0 <build|test|push> <7.2|7.3|7.4>

Other zendPHP versions don't make sense right now. Versions prior to 7.2 require a license from Zend even to be installed (https://www.zend.com/contact-us). I have no plans on pushing these onto my Docker Hub. Version 8 will be built on Docker Hub itself for now (and only on CentOS 8).

EoUsage

    exit 1
}

[[ -z $(echo "$1" | grep -E 'build|test|push') ]] && usage
    action=$1

[[ -z $(echo "$2" | grep -E '7.2|7.3|7.4') ]] && usage
    zVer="$2"
    zV="${zVer//.}"
    [[ $zV > 73 ]] && latest='-t rbasayev/zendphp:latest'

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

if [ "$action" == "build" ]; then
    r-a-c "Building Ubuntu" docker build --build-arg ZENDPHP_VERSION=$zVer $latest -t rbasayev/zendphp:ubuntu20-php$zV -f ubuntu/Dockerfile .
    r-a-c "Building CentOS 7" docker build  --build-arg OS_VERSION=7 --build-arg ZENDPHP_VERSION=$zVer -t rbasayev/zendphp:centos7-php$zV -f centos/Dockerfile .
    r-a-c "Building CentOS 8" docker build  --build-arg OS_VERSION=8 --build-arg ZENDPHP_VERSION=$zVer -t rbasayev/zendphp:centos8-php$zV -f centos/Dockerfile .
elif  [ "$action" == "test" ]; then
    r-a-c "Ubuntu: php version" docker run rbasayev/zendphp:ubuntu20-php$zV -r "(PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION == '$zVer') ? exit(0) : exit(1);"
    r-a-c "Ubuntu: enable Swoole" docker run -e ZENABLE_EXTENSIONS=swoole rbasayev/zendphp:ubuntu20-php$zV php -r 'swoole_version();'
    r-a-c "Ubuntu: try PHP FPM" docker run rbasayev/zendphp:ubuntu20-php$zV timeout --preserve-status -k 5s 0.5s entry_fpm.sh 2> /dev/null

    r-a-c "CentOS 7: php version" docker run rbasayev/zendphp:centos7-php$zV -r "(PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION == '$zVer') ? exit(0) : exit(1);"
    r-a-c "CentOS 7: enable Swoole" docker run -e ZENABLE_EXTENSIONS=swoole rbasayev/zendphp:centos7-php$zV php -r 'swoole_version();'
    r-a-c "CentOS 7: try PHP FPM" docker run rbasayev/zendphp:centos7-php$zV timeout --preserve-status -k 5s 0.5s entry_fpm.sh 2> /dev/null

    r-a-c "CentOS 8: php version" docker run rbasayev/zendphp:centos8-php$zV -r "(PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION == '$zVer') ? exit(0) : exit(1);"
    r-a-c "CentOS 8: enable Swoole" docker run -e ZENABLE_EXTENSIONS=swoole rbasayev/zendphp:centos8-php$zV php -r 'swoole_version();'
    r-a-c "CentOS 8: try PHP FPM" docker run rbasayev/zendphp:centos8-php$zV timeout --preserve-status -k 5s 0.5s entry_fpm.sh 2> /dev/null
elif  [ "$action" == "push" ]; then
    # r-a-c "Login to Docker Hub" docker login -u $DHUB_USER -p $DHUB_TOKEN
    [[ -n "$latest" ]] && docker push rbasayev/zendphp:latest
    docker push rbasayev/zendphp:ubuntu20-php$zV
    docker push rbasayev/zendphp:centos7-php$zV
    docker push rbasayev/zendphp:centos8-php$zV
else
    echo "How did we end up here?!"
fi
