# GitHub Actions

The images are being built by GitHub Actions.

To trigger the build, one needs to push into the 'main' branch with a commit message containing the word `release` and the zendPHP version(s) to be built and pushed to Docker Hub. 

Commit message examples:
```
Fixed a typo in phpinfo().
Release zendPHP versions:
- 7.4
```
```
An update in zendPHP repos, need to release versions 8.0 and 8.1.
```
TODO: At least one more workflow to monitor cr.zend.com for changes and trigger builds on update.
