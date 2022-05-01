# __Dockerized zendPHP__

### My Docker images for projects based on [zendPHP Enterprise](https://www.zend.com/products/zendphp-enterprise)
### Docker Hub https://hub.docker.com/r/rbasayev/zendphp
### GitHub https://github.com/RBasayev/docker-zendphp


>## __N.B.__ for Zend's official images, check https://cr.zend.com
<br><br>

# What is this repo and why zendPHP?

On rare occasions when I develop something, I want to use predictable tools of high quality. And Docker.

Also see [What's New](WhatsNew.md).

# Tags

`:latest` = `:8-ubuntu` = `:8.1-ubuntu-20.04-fpm` - Ubuntu 20.04 with PHP 8.1

`:8-centos` = `:8.1-centos-8-fpm` - CentOS 8 with PHP 8.1

`:8.0-ubuntu-20.04-fpm` - Ubuntu 20.04 with PHP 8.0

`:8.0-centos-8-fpm` - CentOS 8 with PHP 8.0

`:7-ubuntu` = `:7.4-ubuntu-20.04-fpm` - Ubuntu 20.04 with PHP 7.4

`:7-centos` = `:7.4-centos-8-fpm` - CentOS 8 with PHP 7.4

A little more information about how tags are built, read in [GitHubActions.md](https://github.com/RBasayev/docker-zendphp/blob/main/.github/GitHubActions.md).

# General Description

To simply run a zendPHP container:

`docker run -ti --rm rbasayev/zendphp`


There is an option of running it with a non-root user __zendphp__ using the __--drop2web__ parameter:

`docker run -ti --rm --entrypoint entry_cli.sh rbasayev/zendphp:8-centos --drop2web -r "system('ps faux');"`
```
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
zendphp      1 25.0  0.4 467400 32972 pts/0    Ss+  18:53   0:00 php -r system('ps faux');
zendphp     31  0.0  0.0  44668  3364 pts/0    R+   18:53   0:00 ps faux
```

# Extending this Image

This image has two flavors: FPM and CLI. The default is FPM. To switch to CLI mode:

```dockerfile
FROM rbasayev/zendphp
ENTRYPOINT ["entry_cli.sh"]
```

For modifications related to PHP, especially for installing/enabling/disabling PHP extensions, use the `zendphpctl` script. For example:

```dockerfile
FROM rbasayev/zendphp
RUN set -e; \
    zendphpctl PICKLE build 30-xhprof; \
    zendphpctl EXT enable inotify
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

The configuration files in zendPHP are located differently in different operating systems, in Ubuntu there is also a distinction between CLI and FPM. Anyway, they are all in `/etc/zendphp`.

Needless to say, all or some of the configuration locations can be mounted from the host system or from a shared volume. The section [Environment Variables](#environment-variables) shows how configuration changes can be done for a relatively small number of configuration parameters (and only PHP configuration). Direct mounting of ready configuration files and directories is a better way for massive configuration changes. It is also more convenient in a versioned configurations scenario.

### Examples:
```
docker run --rm -P -v "$PWD/php.ini.optimized":/etc/zendphp/php.ini rbasayev/zendphp:8-centos
docker run --rm -P -v fpm-pools-volume:/etc/zendphp/fpm/pool.d rbasayev/zendphp:8-ubuntu
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
