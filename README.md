# __Dockerized zendPHP__

### My Docker images for projects based on [zendPHP Enterprise](https://www.zend.com/products/zendphp-enterprise)
### Docker Hub https://hub.docker.com/r/rbasayev/zendphp
### GitHub https://github.com/RBasayev/docker-zendphp


>## __N.B.__ for Zend's official images, check zend.com
<br><br>

# What is this repo and why zendPHP?

On rare occasions when I develop something, I want to use predictable tools of high quality. And Docker.

# Is this for me?

If you can commit into this repository - yes, it's for you. Otherwise, most likely not.

# Tags

`:edge` = `:centos8-php80` - CentOS 8 with PHP 8.0

`:latest` = `:ubuntu20-php74` - Ubuntu 20.04 with PHP 7.4

`:centos8-php74` - CentOS 8 with PHP 7.4

`:centos7-php74` - CentOS 7 with PHP 7.4

Yes, PHP 7.4 is not the latest of PHP, but it seems to be the latest stable with zendPHP - I couldn't figure out how to install packages for building extensions on Ubuntu. In addition to that, we're still waiting for some big PHP projects to confirm the compatibility with PHP8. That's why the only PHP8 tag here is called __:edge__ (take, cut self, bleed, don't complain).

A little more information about how tags are built, read in [GitHubActions.md](https://github.com/RBasayev/docker-zendphp/blob/main/.github/GitHubActions.md).

# General Description

To simply run a zendPHP container:

`docker run -ti --rm rbasayev/zendphp`

Parameters will be passed on to PHP, for example:

`docker run -ti --rm rbasayev/zendphp -v`
```
PHP 7.4.15 (cli) (built: Feb  4 2021 11:44:13) ( NTS )
Copyright (c) The PHP Group
Zend Engine v3.4.0, Copyright (c) Zend Technologies
    with Zend OPcache v7.4.15, Copyright (c), by Zend Technologies
```


There is an option of running it with a non-root user __web__ using the __--drop2web__ parameter:

`docker run  -ti --rm rbasayev/zendphp --drop2web -r "system('ps faux');"`
```
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
web          1 18.0  0.3  58920 15452 pts/0    Ss+  12:50   0:00 php -r system('ps faux');
web         27  0.0  0.0   2612   536 pts/0    S+   12:50   0:00 sh -c ps faux
web         28  0.0  0.0   5900  2976 pts/0    R+   12:50   0:00  \_ ps faux`
```

# Extending this Image

This image has two flavors: FPM and CLI. The default is CLI. To switch to FPM mode:

```dockerfile
FROM rbasayev/zendphp
EXPOSE 9000
ENTRYPOINT ["entry_fpm.sh"]
```

For modifications related to PHP, especially for installing/enabling/disabling PHP extensions, use the `zendphpctl` script. For example:

```dockerfile
FROM rbasayev/zendphp
RUN set -e; \
    zendphpctl pecl build 30-xhprof; \
    zendphpctl ext enable swoole
```

More detals - [README-scripts.md](https://github.com/RBasayev/docker-zendphp/blob/main/scripts/README-scripts.md)

# Environment Variables

The image supports changing PHP configuration on container startup. Like in most of the images you've seen, I'm doing this through environment variables.

### __$ZDISABLE_EXTENSIONS__ and __$ZENABLE_EXTENSIONS__

Comma-separated (or, less preferably, space-separated) list of PHP extensions to, respectively, disable or enable. Running 'zendphpctl' under the hood.

### Examples:
```bash
ZDISABLE_EXTENSIONS="exif, ftp, pcntl, sodium, tokenizer"
ZENABLE_EXTENSIONS=exif,ftp,pcntl,sodium,tokenizer
ZDISABLE_EXTENSIONS="exif ftp pcntl sodium tokenizer"
ZENABLE_EXTENSIONS="exif, ftp,pcntl,sodium tokenizer"
```

### __$ZCOMMENT_INI_KEYS__

Comma-separated (or, less preferably, space-separated) list of php.ini directives to comment, thus resetting such directives to default values.

### Example:
```bash
COMMENT_INI_KEYS=disable_functions,variables_order
```

### **$ZSET_INI_<normalized_directive_name>** and __$ZADD_INI_KEYS__

To set a value for a particular php.ini directive. The directive name is specified as part of the environment variable itself, while dots (full stop) are replaced with underscores.

The directives specified in this way are compared with the "master list" - the list of available directives obtained from ini_get_all(). If there is a need to add some some special directives to the master list, this can be done with the help of __$ZADD_INI_KEYS__ - a comma-separated (or, less preferably, space-separated) list of directives. The values and directives specified in this way will be added to the file '<scan directory>/zz_bottom.ini', thus overriding any previous values in most cases.

### Examples:
```bash
# will set memory_limit to 555 megabytes
ZSET_INI_memory_limit=555M

# will set session.name=MYAPPSESSID
ZSET_INI_session_name=MYAPPSESSID

# will be ignored, as it's not in master
ZSET_INI_undefined_key="oops"


# these will "register" two special directives,
#   setting the first to 0 and the other one to
#   a line of text enclosed in double quotes
ZADD_INI_KEYS=special.directive,special.directive_two
ZSET_INI_special_directive=0
ZSET_INI_special_directive_two='"This cou|d need c()mpl!cated escaping :("'
```

### __$ZSET_INI_KEYS__

Comma-separated (or, less preferably, space-separated) list of key-value pairs - directive=value. No filtering or sanitation is being done on these. Every key-value pair is put on a separate line in the file `<scan directory>/zz_bottom.ini`.

In most cases this is the most convenient, quick and readable way to
modify php.ini directives. Again: virtually __no__ safeguards! You're responsible for escaping etc.

### Example:
```bash
ZSET_INI_KEYS="memory_limit=60M,post_max_size=50M,upload_max_filesize=40M"
```

# Configuration Locations

The original configuration files in zendPHP are located differently in different operating systems, in Ubuntu there is also a distinction between CLI and FPM.

In these images I moved the relevant configurations to `/etc/zendphp` and symlinked this location to the original layout. I have also removed the distinction between FPM and CLI for Ubuntu - no point in it, besides a couple of directives which I made part of the CLI entrypoint script.

```
/etc/zendphp/php.ini         - php.ini
/etc/zendphp/conf.d/         - PHP scan directory (additional .ini files)
/etc/zendphp/php-fpm.conf    - PHP-FPM configuration file
/etc/zendphp/pool.d/         - PHP-FPM includes directory
```

Needless to say, all or some of these can be mounted from the host system or from a shared volume. The section [Environment Variables](#environment-variables) shows how configuration changes can be done for a relatively small number of configuration parameters (and only PHP configuration). Direct mounting of ready configuration files and directories is a better way for massive configuration changes. It is also more convenient in a versioned configurations scenario.

### Examples:
```
docker run --rm -P -v "$PWD/php.ini.optimized":/etc/zendphp/php.ini rbasayev/zendphp
docker run --rm -P -v fpm-pools-volume:/etc/zendphp/pool.d rbasayev/zendphp
docker run --rm -P -v /mnt/DFS_a/shared-web-config:/etc/zendphp rbasayev/zendphp
```

# Docker-Compose

It's a small one now, so I don't see a point in dedicating more than three lines to it - just read [docker-compose.yml](https://github.com/RBasayev/docker-zendphp/blob/main/docker-compose.yml).

To run: `docker-compose up`

To see: http://127.0.0.1:8080

To end: `docker-compose down`

# K8s / Helm

Creative block - can't think of a nice set of services to add. So far - only basic bricks.

More coming...
