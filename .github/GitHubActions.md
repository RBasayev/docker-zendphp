# GitHub Actions

While the 'edge' tag is being built by Docker Hub (see the [hooks](https://github.com/RBasayev/docker-zendphp/tree/main/centos/hooks) directory), the rest of the images is being built by GitHub Actions.

To trigger the build, one needs to push into the 'release' branch with a commit message containing the word `release` and the zendPHP version(s) to be built and pushed to Docker Hub. 

Commit message examples:
```
Fixed a typo in phpinfo().
Release zendPHP versions:
- 7.4
```
```
An update in zendPHP repos, need to release versions 7.3 and 7.4.
```
TODO: At least one more workflow to monitor repos.zend.com for changes and trigger builds on update.