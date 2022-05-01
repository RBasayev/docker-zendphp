# ZendPHPctl

### `zendphp-extensions.sh` and `zendphp-pickle-tool.sh` can be executed separately, but it's probably more convenient to use the "frontend" script `zendphpctl`

## Help for `zendphpctl`

This script helps with the most common ZendPHP management tasks.

Usage: `zendphpctl <subcommand> <parameters>`

Subcommands:
```
  - EXT | ext | extensions
|-----------------------------------------------------------------
|   Manage the extensions provided with ZendPHP.
|
|   Install extension(s) - examples:
|      # zendphpctl EXT install oci8
|      # zendphpctl EXT install oci8 pgsql soap
|   To install all available extensions, you can use:
|      # zendphpctl EXT list installable | xargs zendphpctl EXT install
|
|   Update installable list - example:
|      # zendphpctl EXT update
|
|   Uninstall extension - not implemented (no use case)
|
|   Enable extension(s) - examples:
|      # zendphpctl EXT enable oci8
|      # zendphpctl EXT enable oci8 pgsql soap
|
|   Disable extension(s) - examples:
|      # zendphpctl EXT disable oci8
|      # zendphpctl EXT disable oci8 pgsql soap
|
|   List extensions - examples:
|      # zendphpctl EXT list installed
|      # zendphpctl EXT list installable
|      # zendphpctl EXT list enabled
|      # zendphpctl EXT list disabled
|
|   NB: Things are a little weird with using '-' in some places
|   and '_' in others. I'll be trying to properly swap them - whatever
|   makes more sense for a specific action.
|   However, things happen, just be aware of this.
|
|-----------------------------------------------------------------

  - PICKLE | pickle
|-----------------------------------------------------------------
|   Automate ZendPHP extensions compilation.
|
|   Prepare the system for build by installing the necessary tools:
|      # zendphpctl PICKLE prepare
|
|   Build extension(s) - examples:
|      # zendphpctl PICKLE build [--tgz] inotify-0.1.6 30-swoole
|
|   Create 0-byte files, e.g., for consistent COPY/ADD behavior in Docker.
|      # zendphpctl PICKLE simulate [--tgz] mongodb 30-xhprof
|
|   The extension names can be specified using this simple convention:
|     [priority-]name[-version]
|
|   Examples:
|           swoole
|           30-swoole
|           swoole-4.5.2
|           30-swoole-4.5.6
|
|   Default priority is 20.
|   The compiled modules are set up to be DISABLED.
|   To use, one must enable them first (try "zendphpctl ext help").
|   With --tgz the archive will be placed in file system root:
|       /compiled_extensions.tgz
|
|-----------------------------------------------------------------

  - COMPOSER | getcomposer | installcomposer
|-----------------------------------------------------------------
|   Install Composer into the specified directory.
|
|   Example:
|      # zendphpctl getcomposer /usr/local/bin
|
|   The specified directory must exist before the installation.
|-----------------------------------------------------------------
```

## Help for `zendphp-env2config.sh`


Usage: simply run this script - it will process special environment variables.

Environment variables (in order of processing):
```

|  $ZDISABLE_EXTENSIONS
|     and
|  $ZENABLE_EXTENSIONS
|    - comma-separated (or, less preferably, space-separated) list of
|  PHP extensions to, respectively, disable or enable.
|  Running 'zendphpctl' under the hood.
|
|  Examples:
|    ZDISABLE_EXTENSIONS="exif, ftp, pcntl, sodium, tokenizer"
|    ZENABLE_EXTENSIONS=exif,ftp,pcntl,sodium,tokenizer
|    ZDISABLE_EXTENSIONS="exif ftp pcntl sodium tokenizer"
|    ZENABLE_EXTENSIONS="exif, ftp,pcntl,sodium tokenizer"

```
```
|  $ZCOMMENT_INI_KEYS
|    - comma-separated (or, less preferably, space-separated) list of
|  php.ini directives to comment, thus resetting such directives to
|  default values.
|
|  Example:
|    ZCOMMENT_INI_KEYS=disable_functions,variables_order
```
```
|  $ZSET_INI_<normalized_directive_name>
|     and
|  $ZADD_INI_KEYS
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
|    ZSET_INI_special_directive_two='This cou|d need c()mpl!cated escaping :('
|      (these will "register" two special directives, setting the first to
|        0 and the other one to a line of text enclosed in double quotes)
```
```
|  $ZSET_INI_KEYS
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
