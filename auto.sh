#!/bin/bash

function usage(){
    cat <<EoUsage

This script can build, test and push images of zendPHP 7.4, 8.0 and 8.1 on CentOS 8 and Ubuntu 20.04.

auto.sh <action> <PHP ver.>

         test       7.4
          OR         OR
         push       8.1

$0 <build|test|push> <7.4|8.0|8.1>

Other zendPHP versions don't make sense right now. Versions prior to 7.3 require a license from Zend even to be installed (https://www.zend.com/contact-us). I have no plans on pushing these onto my Docker Hub.

EoUsage

    exit 1
}

[[ -z $(echo "$1" | grep -E 'build|test|push') ]] && usage
    action=$1

[[ -z $(echo "$2" | grep -E '7.4|8.0|8.1') ]] && usage
    zVer="$2"
    zV="${zVer//.}"
    [[ $zV -gt 80 ]] && latest='-t rbasayev/zendphp:latest'
    zVshort="${zVer:0:1}"

function r-a-c(){
    # Run-And-Check
    # Usage: r-a-c "Short Description" <command with arguments>

    desc=$1
    shift
    "$@"
    code=$?
    if [ "$code" != "0" ]; then
        echo "'$desc' failed (code $code)":
        history | tail -1 |  sed -r "s|^[ 0-9]+r-a-c ['\"]*${desc}['\"] |   |"
        exit $code
    else
        echo "'$desc'   ... OK"
    fi
}

# This set is needed for the history to work
set -o history

if [ "$action" == "build" ]; then
    r-a-c "Building Ubuntu 20.04" docker build --build-arg ZENDPHP_VERSION=$zVer $latest -t rbasayev/zendphp:$zVshort-ubuntu -t rbasayev/zendphp:$zVer-ubuntu-20.04-fpm -f Dockerfile.Ubuntu-20.04 .
    r-a-c "Building CentOS 8" docker build --build-arg ZENDPHP_VERSION=$zVer -t rbasayev/zendphp:$zVshort-centos -t rbasayev/zendphp:$zVer-centos-8-fpm -f Dockerfile.CentOS-8 .
elif  [ "$action" == "test" ]; then
    r-a-c "Ubuntu: php version" docker run --rm rbasayev/zendphp:$zVer-ubuntu-20.04-fpm php -r "(PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION == '$zVer') ? exit(0) : exit(1);"
    r-a-c "Ubuntu: try PHP FPM" docker run --rm rbasayev/zendphp:$zVer-ubuntu-20.04-fpm --testFPM 2> /dev/null

    r-a-c "CentOS 8: php version" docker run --rm rbasayev/zendphp:$zVer-centos-8-fpm php -r "(PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION == '$zVer') ? exit(0) : exit(1);"
    r-a-c "CentOS 8: try PHP FPM" docker run --rm rbasayev/zendphp:$zVer-centos-8-fpm --testFPM 2> /dev/null
elif  [ "$action" == "push" ]; then
    # r-a-c "Login to Docker Hub" docker login -u $DHUB_USER -p $DHUB_TOKEN
    [[ -n "$latest" ]] && docker push rbasayev/zendphp:latest
    docker push rbasayev/zendphp:$zVer-ubuntu-20.04-fpm
    docker push rbasayev/zendphp:$zVer-centos-8-fpm
    docker push rbasayev/zendphp:$zVshort-ubuntu
    docker push rbasayev/zendphp:$zVshort-centos
else
    echo "How did we end up here?!"
fi
