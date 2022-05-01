#!/bin/bash

function usage(){
    cat <<EOU
Manage the extensions provided with ZendPHP.

Install extension(s) - examples:
   # $(basename $0) install oci8
   # $(basename $0) install oci8 pgsql soap
To install all available extensions, you can use:
   # $(basename $0) list installable | xargs $(basename $0) install

Update installable list - example:
   # $(basename $0) update

Uninstall extension - not implemented (no use case)

Enable extension(s) - examples:
   # $(basename $0) enable oci8
   # $(basename $0) enable oci8 pgsql soap

Disable extension(s) - examples:
   # $(basename $0) disable oci8
   # $(basename $0) disable oci8 pgsql soap

List extensions - examples:
   # $(basename $0) list installed
   # $(basename $0) list installable
   # $(basename $0) list enabled
   # $(basename $0) list disabled

NB: Things are a little weird with using '-' in some places
and '_' in others. I'll be trying to properly swap them - whatever
makes more sense for a specific action.
However, things happen, just be aware of this.

EOU
}

# shellcheck source=./ZendPHP-Common.lib
. $(command -v ZendPHP-Common.lib)

function zenable(){
    if isCentos; then
        cd "$PHP_D_PATH/DISABLED" > /dev/null 2>&1 || panic 1 "There seems to be nothing disabled, i.e. nothing to re-enable here."
        for xt in "$@"; do
            iniFile=$(basename "$(find . -type f -name "*-${xt//-/_}.ini" )" 2> /dev/null)
            if [ -n "$iniFile" ]; then
                mv "$iniFile" ../ && echo "[OK] - '$xt' should be enabled now."
            else
                echo "Can't find '$xt' in DISABLED. Maybe already enabled?"
            fi
        done
    else
        # not making a distinction for cli and fpm - no use case
        phpenmod -v "${PHP_VER}-zend" "${@//-/_}"
    fi
}

function zdisable(){
    if isCentos; then
        cd "$PHP_D_PATH" > /dev/null 2>&1 || panic 1 "Can't jump to the scan directory"
        mkdir -p DISABLED
        for xt in "$@"; do
            iniFile=$(basename "$(find . -maxdepth 1 -type f -name "*-${xt//-/_}.ini")" 2> /dev/null)
            if [ -n "$iniFile" ]; then
                mv "$iniFile" DISABLED/ && echo "[OK] - '$xt' should be disabled now."
            else
                echo "INI for '$xt' - not found. Maybe already disabled?"
            fi
        done
    else
        # not making a distinction for cli and fpm - no use case
        phpdismod -v "${PHP_VER}-zend" "${@//-/_}"
    fi
}

function zupdate(){
    mkdir -p /etc/zendphp
    if isCentos; then
        yum list "php${PHP_V}zend-php-*" | \
            cut -d. -f1 | \
            grep -v "debuginfo" | \
            grep -vE "^php${PHP_V}zend-php-(devel|embedded|fpm|cgi|cli|common)\$" | \
        sort > /etc/zendphp/installable_extensions
        grep '^php' /etc/zendphp/installable_extensions | cut -c15- > /etc/zendphp/installable_extensions_short
        yum clean all
    else
        apt-get update
        apt-cache search --names-only "^php${PHP_VER}-zend-"| \
            cut -d' ' -f1 | \
            grep -vE "^php${PHP_VER}-zend-(dev|fpm|cgi|cli|common)\$" | \
        sort > /etc/zendphp/installable_extensions
        grep '^php' /etc/zendphp/installable_extensions | cut -c13- > /etc/zendphp/installable_extensions_short
        # 'apt-get clean' is not really necessary - targeting for Docker anyway
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    fi
}

function zinstall(){
    if [ $(cat /etc/zendphp/installable_extensions | wc -l) -lt 5 ]; then
    # Testing that the file exists and that it has a reasonable
    # number of lines (at least 5 - arbitrary number, but seems reasonable).
    # Some Zend images appear to not populate this file.
        zupdate
    fi

    list=""
    if isCentos; then
        for xt in $@; do
            list="$list $(grep -E "^php${PHP_V}zend-php-.*${xt//_/-}\$" /etc/zendphp/installable_extensions)"
        done
        if [ "X$(echo $list | xargs)X" == "XX" ]; then
            panic 1 "Extension(s) not installable:\n   $*\n"
        fi
        echo -e "Will try to install:\n   $list"
        echo "If you're trying to use this in a script, consider 'export YUM_y=-y'"
        echo
        # shellcheck disable=SC2154 #(variable expected from environment)
        yum $YUM_y install $list
        yum clean all
    else
        for xt in $@; do
            list="$list $(grep -E "^php${PHP_VER}-zend-${xt//_/-}\$" /etc/zendphp/installable_extensions)"
        done
        if [ "X$(echo $list | xargs)X" == "XX" ]; then
            panic 1 "Extension(s) not installable:\n   $*\n"
        fi
        echo -e "Will try to install:\n   $list"
        echo "If you're trying to use this in a script, consider 'export DEBIAN_FRONTEND=noninteractive'"
        echo
        apt-get update
        apt-get install -y $list
        apt-get autoclean
    fi
}

function zlist(){
    case $1 in
        installed)
            if isCentos; then
                rpm -qa "php${PHP_V}zend-php-*" --qf '%{NAME}\n' | grep -v "debuginfo" | grep -vE "^php${PHP_V}zend-php-(devel|embedded|fpm|cgi|cli|common)\$" | sed "s|^php${PHP_V}zend-php-||g" | sort
            else
                dpkg-query -f '${Package}\n' --show "php$PHP_VER-zend-*" | grep -vE "^php$PHP_VER-zend-(dev|fpm|cgi|cli|common)\$" | sed "s|^php${PHP_VER}-zend-||g" | sort
            fi
            ;;
        installable)
            sort < /etc/zendphp/installable_extensions_short
            ;;
        enabled)
            if isCentos; then
                cd "$PHP_D_PATH" 2> /dev/null && ls -1 *.ini | cut -d'-' -f2 | cut -d'.' -f1 | sort || panic 1 "Couldn't change to the scan directory. I've a feeling we're not in Kansas anymore..."
            else
                phpquery -d -v "$PHP_VER-zend" -s fpm -M | grep Enabled | cut -d' ' -f1 | sort
            fi
            ;;
        disabled)
            if isCentos; then
                cd "$PHP_D_PATH/DISABLED" 2> /dev/null || panic 5 "Nothing disabled yet. Not by me anyway..."
                [[ -z "$(ls -1 *.ini 2> /dev/null)" ]] && panic 3 "No disabled extensions found. Are you sure something's missing?" || ls -1 *.ini 2> /dev/null | cut -d'-' -f2 | cut -d'.' -f1 | sort
            else
                phpquery -d -v "$PHP_VER-zend" -s fpm -M | grep Disabled | sed -r 's|^No module matches ([0-9A-Za-z_]+).*$|\1|g' | sort
            fi
            ;;
        *) usage;;
    esac
}

case $1 in
    install|enable|disable)
        action=$1
        shift
        [[ ${#@} -gt 0 ]] || panic 1 "\nList of extensions to $action is empty\n"
        z$action $@
        ;;
    update)
        zupdate
        ;;
    list)
        shift
        zlist $1
        ;;
    *) usage;;
esac
