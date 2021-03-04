#!/bin/bash

function usage(){
    cat <<EOU
Automate ZendPHP extensions compilation.

Build extension(s) - examples:
   # $(basename $0) build [--tgz] inotify-0.1.6 30-swoole

Create 0-byte files, e.g., for consistent COPY/ADD behavior in Docker.
   # $(basename $0) simulate [--tgz] mongodb 30-xhprof

The extension names can be specified using this simple convention:
  [priority-]name[-version]

Examples:
        swoole
        30-swoole
        swoole-4.5.2
        30-swoole-4.5.6

Default priority is 20.
The compiled modules are set up to be DISABLED.
To use, one must enable them first (try "zendphpctl ext help").
With --tgz the archive will be placed in file system root:
    /compiled_extensions.tgz

EOU
}

# shellcheck source=./ZendPHP-Common.lib
. $(command -v ZendPHP-Common.lib)


function zbuild(){

    PACK='echo -e --------\n\nSuccessfully built: '
    if [ "$1" == "--tgz" ]; then
        PACK='zpak'
        shift
    fi

    # Installing build tools
    if isCentos; then
        if [ $OS_VER -gt 7 ]; then
            dnf -y install dnf-plugins-core
            dnf config-manager --set-enabled PowerTools
        fi
        yum install -y gcc gcc-c++ make php${PHP_V}zend-php-devel php${PHP_V}zend-php-pear
        ln -s /opt/zend/php${PHP_V}zend/root/bin/pecl /usr/local/bin/pecl
    else
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y php$PHP_VER-zend-dev php$PHP_VER-zend-xml libssl-dev
    fi

    ok_list=''
    for xt in $@; do
        prefix=$(echo $xt | grep -oE '^[0-9]{2}-')
        [[ -n "$prefix" ]] && xt=${xt:3} || prefix="20-"
        suffix=$(echo $xt | grep -oE -- '-[\.0-9]+$')
        [[ -n "$suffix" ]] && xt=${xt:0:-${#suffix}}

        yes | pecl install -a $xt$suffix
        ok=$?
        # if build unsuccessful, continue to the next item
        [[ $ok -gt 0 ]] && echo "Compilation of $xt.so failed" && continue

        # if we end up here, the build was successful
        ok_list="$ok_list $xt"
        if isCentos; then
            ini_path=$PHP_D_PATH/DISABLED
            mkdir -p $ini_path
            echo -e "; Enable $xt extension module\nextension=$xt" > $ini_path/${prefix}${xt}.ini
        else
            echo -e "; configuration for php $xt module\n; priority=${prefix:0:2}\nextension=$xt.so" > $PHP_ETC_PATH/mods-available/$xt.ini
            touch /var/lib/php/modules/$PHP_VER-zend/registry/$xt
        fi
    done
    # If --tgz was specified, calling zpak for successfully built extensions
    $PACK $ok_list
}

function zsimulate(){

    PACK='echo -e --------\nSuccessfully simulated: '
    if [ "$1" == "--tgz" ]; then
        PACK='zpak'
        shift
    fi

    ok_list=''
    for xt in $@; do
        prefix=$(echo $xt | grep -oE '^[0-9]{2}-')
        [[ -n "$prefix" ]] && xt=${xt:3} || prefix="20-"
        # suffix (version) makes no sense here, but is still supported syntax
        suffix=$(echo $xt | grep -oE -- '-[\.0-9]+$')
        [[ -n "$suffix" ]] && xt=${xt:0:-${#suffix}}

        # if file exists, we consider the simulation for this item FAILED
        [[ -f $PHP_EXT_DIR/$xt.so ]] && echo "$xt.so already exists" && continue

        echo "Processing $xt.so"
        touch $PHP_EXT_DIR/$xt.so
        ok_list="$ok_list $xt"

        # simulated INI files are created empty, too
        if isCentos; then
            ini_path=$PHP_D_PATH/DISABLED
            mkdir -p $ini_path
            touch $ini_path/${prefix}${xt}.ini
        else
            touch $PHP_ETC_PATH/mods-available/$xt.ini
            touch /var/lib/php/modules/$PHP_VER-zend/registry/$xt
        fi
    done
    # If --tgz was specified, calling zpak for successfully built extensions
    $PACK $ok_list

}

function zpak(){
    echo "Will add these to TGZ: $@"
    for item in $@; do
        tar -rf /compiled_extensions.tar $PHP_EXT_DIR/$item.so
        if isCentos; then
            tar -rf /compiled_extensions.tar $PHP_D_PATH/DISABLED/??-$item.ini
        else
            tar -rf /compiled_extensions.tar $PHP_ETC_PATH/mods-available/$item.ini /var/lib/php/modules/$PHP_VER-zend/registry/$item
        fi
    done

    gzip -9 < /compiled_extensions.tar > /compiled_extensions.tgz
}


case "$1" in
    build|simulate)
        action=$1
        shift
        [[ ${#@} -gt 0 ]] || panic 1 "\nList of extensions to $action is empty\n"
        z$action $@
        ;;
    *) usage;;
esac
