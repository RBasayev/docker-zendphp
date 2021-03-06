#!/bin/bash

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
cat <<EOU

$0 <-q>

Usage:  simply run this script - it will process special environment variables.
        -q (quiet) will suppress the message
                    "There are no special environment variables to process"
        (made specially for nicer Docker entrypoints)

Environment variables (in order of processing):

-------------------------------------------------
|
|  \$ZDISABLE_EXTENSIONS
|     and
|  \$ZENABLE_EXTENSIONS
|    - comma-separated (or, less preferably, space-separated) list of
|  PHP extensions to, respectively, disable or enable.
|  Running 'zendphpctl' under the hood.
|
|  Examples:
|    ZDISABLE_EXTENSIONS="exif, ftp, pcntl, sodium, tokenizer"
|    ZENABLE_EXTENSIONS=exif,ftp,pcntl,sodium,tokenizer
|    ZDISABLE_EXTENSIONS="exif ftp pcntl sodium tokenizer"
|    ZENABLE_EXTENSIONS="exif, ftp,pcntl,sodium tokenizer"
|
-------------------------------------------------
|
|  \$ZCOMMENT_INI_KEYS
|    - comma-separated (or, less preferably, space-separated) list of
|  php.ini directives to comment, thus resetting such directives to
|  default values.
|
|  Example:
|    ZCOMMENT_INI_KEYS=disable_functions,variables_order
|
-------------------------------------------------
|
|  \$ZSET_INI_<normalized_directive_name>
|     and
|  \$ZADD_INI_KEYS
|    - to set a value for a particular php.ini directive. The directive
|  name is specified as part of the environment variable itself, while
|  dots (full stop) are replaced with underscores.
|    The directives specified in this way are compared with the "master
|  list" - the list of available directives obtained from ini_get_all().
|  If there is a need to add some some special directives to the master list,
|  this can be done with the help of \$ZADD_INI_KEYS - a comma-separated
|  (or, less preferably, space-separated) list of directives.
|    The values and directives specified in this way will be added to the
|  file '<scan directory>/zz_bottom.ini', thus overriding any previous values
|  in most cases.
|
|  Examples:
|    ZSET_INI_memory_limit=555M        (will set memory_limit to 555 megabytes)
|    ZSET_INI_session_name=MYAPPSESSID (will set session.name=MYAPPSESSID)
|
|    ZSET_INI_undefined_key="oops"     (will be ignored, as it's not in master)
|
|    ZADD_INI_KEYS=special.directive,special.directive_two
|    ZSET_INI_special_directive=0
|    ZSET_INI_special_directive_two='"This cou|d need c()mpl!cated escaping :("'
|      (these will "register" two special directives, setting the first to
|        0 and the other one to a line of text enclosed in double quotes)
|
-------------------------------------------------
|
|  \$ZSET_INI_KEYS
|    - comma-separated (or, less preferably, space-separated) list of
|  key-value pairs - directive=value. No filtering or sanitation is being
|  done on these. Every key-value pair is put on a separate line in the
|  file '<scan directory>/zz_bottom.ini'.
|    In most cases this is the most convenient, quick and readable way to
|  modify php.ini directives.
|    Again: virtually no safeguards! You're responsible for escaping etc.
|
|  Example:
|    ZSET_INI_KEYS="memory_limit=60M,post_max_size=50M,upload_max_filesize=40M"
|
-------------------------------------------------

EOU
exit
fi


# shellcheck source=./ZendPHP-Common.lib
. $(command -v ZendPHP-Common.lib)

function plain(){
    # convert comma- and/or space-separated list to space-separated
    echo $1 | sed -e 's|,| |g' -e 's|  | |g'
}

# Getting the list of all the $ZSET_INI_* variables
sets=$(env | grep -oE '^ZSET_INI_[a-zA-Z0-9_]+' | xargs)

if [ -z "$sets""$ZCOMMENT_INI_KEYS""$ZADD_INI_KEYS""$ZDISABLE_EXTENSIONS""$ZENABLE_EXTENSIONS" ]; then
    # Quiet mode for "ideologically proper" entrypoint scripts
    [[ "$1" == "-q" ]] && exit 0
    panic 0 "There are no special environment variables to process"
fi


# Disabling/enabling extensions is quite simple
# (is there need for eye candy, consistent with Commenting and Adding?)
if [ -n "$ZDISABLE_EXTENSIONS" ]; then
    zendphpctl EXT disable $(plain "$ZDISABLE_EXTENSIONS")
fi
if [ -n "$ZENABLE_EXTENSIONS" ]; then
    zendphpctl EXT enable $(plain "$ZENABLE_EXTENSIONS")
fi

# Commenting (also simple) before anything else
if [ -n "$ZCOMMENT_INI_KEYS" ]; then
    echo -e "\nCommenting INI keys:"
    for commDir in $(plain "$ZCOMMENT_INI_KEYS"); do
        [[ "$commDir" == "extension" ]] && echo "  - not commenting 'extension' - too ambiguous" && continue
        [[ "$commDir" == "zend_extension" ]] && echo "  - not commenting 'zend_extension' - too ambiguous" && continue
        echo "  - will try to comment '$commDir'"
        commDir=${commDir//./\\.}
        sed --follow-symlinks -ri "s|^\s*($commDir\s*=)|;\1|g" $PHP_D_PATH/*.ini $PHP_INI
    done
fi


# $ZADD_INI_KEYS makes no sense without $ZSET_INI_*, not testing for it here
if [ -n "$sets" ]; then
    echo -e "\nSetting new values for INI directives:"
    # Building the master list of directives
    master=$(php -r 'print_r(implode("\n",array_keys(ini_get_all())));')

    # Adding directives to the master list from $ZADD_INI_KEYS
    # (the list is comma-separated, spaces should be ignored)
    # e.g.: ZADD_INI_KEYS="zend.allow_tunnel, special_key_one,special.key_two"
    if [ -n "$ZADD_INI_KEYS" ];then
        # removing spaces, then replacing commas with new line characters
        additions=$(echo "$ZADD_INI_KEYS" | sed -e 's| ||g' -e 's|,|\n|g')
        master="$master"$'\n'"$additions"
    fi

    # making sure we have new line in this file
    echo >> $PHP_D_PATH/zz_bottom.ini

    for setVar in $sets; do
        # setTemplate produces something like 'session[_\.]save[_\.]path'
        setTemplate=$(echo $setVar | sed -e 's|ZSET_INI_||g' -e 's|_|[_\.]|g')
        setDir=$(echo "$master" | grep -E $setTemplate)

        [[ -z "$setDir" ]] && echo "  - pattern '$setTemplate' not found in the master list" && continue

        # Trying to detect whether the directive value requiers double quotes
        setValue="${!setVar}"
        specialChars="$(echo "$setValue" | sed 's|[a-zA-Z0-9\._/-]||g')"
        [[ -n "$specialChars" ]] && setValue='"'$setValue'"'

        echo "  - adding $setDir=$setValue."
        echo "$setDir=$setValue" >> $PHP_D_PATH/zz_bottom.ini
    done
fi


# $ZSET_INI_KEYS - apart from potential escaping issues, probably the most convenient method
setKeys="$(echo $ZSET_INI_KEYS | sed -e 's| ||g' -e 's|,|\n|g')"
if [ -n "$setKeys" ]; then
    # making sure we have new line in this file
    echo >> $PHP_D_PATH/zz_bottom.ini
    echo -e "\nSetting complete INI directives:"
    echo "$setKeys" | sed 's|^|  - |g'
    echo "$setKeys" >> $PHP_D_PATH/zz_bottom.ini
fi
