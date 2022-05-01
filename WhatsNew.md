# What's New and Different in Gen_2

## General Changes

- Switched to [Zend's images](https://cr.zend.com) instead of installing from repositories
- Replaced the entrypoint with the simpler one from Gen_1

## Removed Features

- Removed the Swoole extension compilation
- Removed credential-based repository access
- Removed the special "web:site" user (using "zendphp:zendphp" instead)

## Added Features

- Added the Mailparse extension (for [UVDesk](https://www.uvdesk.com/en/opensource/))
- New and refactored functions in `zendphpctl`
- All installable extensions are pre-installed (most are disabled by default)

## Fixed Zend Image Problems

- In some images `/etc/zendphp/installable_extensions` was empty
- Software installation was broken in CentOS 8 - bad repository URLs
- Replaced PECL with PICKLE (see next item)
- Worked around broken dependencies in the package php[VER]-zend-dev (or maybe php[VER]-zend-xml) on Ubuntu
- Getting the `php-fpm-healthcheck` script directly from GitHUB
- Removed the VIM swap files from `/usr/local/bin`
