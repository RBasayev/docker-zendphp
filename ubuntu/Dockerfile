ARG OS_VERSION=20.04
ARG ZENDPHP_VERSION=7.4
FROM ubuntu:$OS_VERSION AS zphp-base

ARG OS_VERSION
ARG ZENDPHP_VERSION

RUN set -e; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get -y install curl gnupg; \

    # adding zend.key
    export GNUPGHOME="$(mktemp -d)"; \
    key='799058698E65316A2E7A4FF42EAE1437F7D2C623'; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
    gpg --batch --armor --export "$key" > /etc/apt/trusted.gpg.d/zend-infra.gpg.asc; \
    rm -rf "$GNUPGHOME"; \

    # configuring the repository
    export REPO_VERSION=$(echo ${OS_VERSION} | sed -e 's/\.//g'); \
    echo "deb https://repos.zend.com/zendphp/deb_ubuntu${REPO_VERSION}/ zendphp non-free" > /etc/apt/sources.list.d/zendphp.list; \
    apt-get update; \

    # creating the list of installable extensions (for zextctl.sh)
    mkdir -p /etc/php/${ZENDPHP_VERSION}-zend; \
    apt-cache search --names-only "^php${ZENDPHP_VERSION}-zend-"| \
        cut -d' ' -f1 | \
        grep -vE "^php${ZENDPHP_VERSION}-zend-(dev|fpm|cgi|cli|common)\$" | \
        sort > /etc/php/${ZENDPHP_VERSION}-zend/mods-installable; \

    # installing ZendPHP
    apt-get -y install php${ZENDPHP_VERSION}-zend-fpm; \

    # final touch ups
    update-alternatives --install /usr/sbin/php-fpm php-fpm /usr/sbin/php-fpm${ZENDPHP_VERSION}-zend 100; \
    update-alternatives --set php-fpm /usr/sbin/php-fpm${ZENDPHP_VERSION}-zend; \
    ln -s /etc/php/${ZENDPHP_VERSION}-zend /etc/php/${ZENDPHP_VERSION}; \
    rm -rf /var/lib/apt/lists/*


FROM zphp-base AS zphp-more
ARG OS_VERSION
ARG ZENDPHP_VERSION

COPY ubuntu/*.ini /
RUN set -e; \
    # Not compiling swoole and inotify for old PHP
    if [ $(echo ${ZENDPHP_VERSION} | cut -c1) -lt 7 ]; then touch /inotify.so /swoole.so; exit 0; fi; \

    # Installing build tools
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y php${ZENDPHP_VERSION}-zend-dev php${ZENDPHP_VERSION}-zend-xml libssl-dev; \

    # Compiling swoole and inotify (yes command answers 'yes' to pecl prompts)
    yes | pecl install -a swoole inotify; \

    # Moving files to a short path (where then final stage will pick them up) and stripping symbols for smaller size
    mv /usr/lib/php/${ZENDPHP_VERSION}-zend/inotify.so /inotify.so ;\
    mv /usr/lib/php/${ZENDPHP_VERSION}-zend/swoole.so /swoole.so ;\
    strip /*.so


# This final stage basically pulls a few files from different locations and seals the image
FROM zphp-base
ARG OS_VERSION
ARG ZENDPHP_VERSION
COPY scripts/* /usr/local/bin/
COPY --from=zphp-more /swoole.* /inotify.* /tmp/

# Putting the newly built binaries in place
RUN set -e; \
    if [ $(stat -c %s /tmp/swoole.so) -eq 0 -o $(stat -c %s /tmp/inotify.so) -eq 0 ]; then rm -f /tmp/swoole.* /tmp/inotify.*; exit 0; fi; \
    mv /tmp/inotify.so /usr/lib/php/${ZENDPHP_VERSION}-zend/inotify.so ;\
    mv /tmp/swoole.so /usr/lib/php/${ZENDPHP_VERSION}-zend/swoole.so ; \
    mv /tmp/inotify.ini /etc/php/${ZENDPHP_VERSION}-zend/mods-available/inotify.ini ;\
    mv /tmp/swoole.ini /etc/php/${ZENDPHP_VERSION}-zend/mods-available/swoole.ini ; \
    touch /var/lib/php/modules/${ZENDPHP_VERSION}-zend/registry/inotify /var/lib/php/modules/${ZENDPHP_VERSION}-zend/registry/swoole;

# Unification of config files locations - same on all image flavors
RUN set -e; \
    mkdir /etc/zendphp; \
    # moving things to /etc/zendphp:
        mv /etc/php/${ZENDPHP_VERSION}-zend/fpm/php-fpm.conf /etc/zendphp/; \
        mv /etc/php/${ZENDPHP_VERSION}-zend/fpm/pool.d /etc/zendphp/; \
        mv /etc/php/${ZENDPHP_VERSION}-zend/fpm/php.ini /etc/zendphp/; \
        mv /etc/php/${ZENDPHP_VERSION}-zend/fpm/conf.d /etc/zendphp/; \
    # removing things to clear the place for symlinks:
        rm /etc/php/${ZENDPHP_VERSION}-zend/cli/php.ini; \
         rm -rf /etc/php/${ZENDPHP_VERSION}-zend/cli/conf.d; \
    # creating symlinks in the original locations:
        ln -s /etc/zendphp/php-fpm.conf /etc/php/${ZENDPHP_VERSION}-zend/fpm/php-fpm.conf; \
        ln -s /etc/zendphp/pool.d /etc/php/${ZENDPHP_VERSION}-zend/fpm/pool.d; \
        ln -s /etc/zendphp/php.ini /etc/php/${ZENDPHP_VERSION}-zend/fpm/php.ini; \
        ln -s /etc/zendphp/php.ini /etc/php/${ZENDPHP_VERSION}-zend/cli/php.ini; \
        ln -s /etc/zendphp/conf.d /etc/php/${ZENDPHP_VERSION}-zend/fpm/conf.d; \
        ln -s /etc/zendphp/conf.d /etc/php/${ZENDPHP_VERSION}-zend/cli/conf.d; \
    # nasty, I know:
        rm /etc/zendphp/pool.d/www.conf; \
        mv /usr/local/bin/site.conf /etc/zendphp/pool.d/

# "Activating" /usr/local/bin and preparing for non-privileged user
RUN set -e; \
    curl -Lo /usr/local/bin/gosu https://github.com/tianon/gosu/releases/latest/download/gosu-amd64; \
    chmod a+x /usr/local/bin/*; \
    # quick test that gosu was downloaded ok, if not, set -e will bail here
    gosu root echo; \
    mkdir -p /var/www/site; \
    addgroup --system site; \
	adduser --system --no-create-home --home /var/www/site --ingroup site --shell /bin/false web

ENTRYPOINT ["entry_cli.sh"]
