#!make
########################## Variables #####################
HERE		:= $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
##########################################################

##### Makefile related #####
.PHONY: all clean build

default: help

##@ Help

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[0-9a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-40s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Image Building

edge: ## Build Generic ZendPHP image :edge (:centos8-php80)
	@cd "$(HERE)"
	@echo
	@echo "\033[92mBuilding ZendPHP image for CentOS 8...\033[0m"
	docker build --build-arg ZENDPHP_VERSION=8.0 -t rbasayev/zendphp:edge -t rbasayev/zendphp:centos8-php80 -f centos/Dockerfile .
	@echo "\033[92mZendPHP image building done!\033[0m"
	@echo

latest: ## Build Generic ZendPHP image :latest (:ubuntu20-php74)
	@cd "$(HERE)"
	@echo
	@echo "\033[92mBuilding ZendPHP image for Ubuntu...\033[0m"
	docker build -t rbasayev/zendphp:latest -t rbasayev/zendphp:ubuntu20-php74 -f ubuntu/Dockerfile .
	@echo "\033[92mZendPHP image building done!\033[0m"
	@echo

centos8: ## Build Generic ZendPHP image :centos8-php74
	@cd "$(HERE)"
	@echo
	@echo "\033[92mBuilding ZendPHP image for CentOS 8...\033[0m"
	docker build -t rbasayev/zendphp:centos8-php74 -f centos/Dockerfile .
	@echo "\033[92mZendPHP image building done!\033[0m"
	@echo

centos7: ## Build Generic ZendPHP image :centos7-php74
	@cd "$(HERE)"
	@echo
	@echo "\033[92mBuilding ZendPHP image for CentOS 7...\033[0m"
	docker build --build-arg OS_VERSION=7 -t rbasayev/zendphp:centos7-php74 -f centos/Dockerfile .
	@echo "\033[92mZendPHP image building done!\033[0m"
	@echo

php72: ## Build ZendPHP 7.2 on CentOS7 (behind auth) :centos7-php72
	@cd "$(HERE)"
	@echo
	@echo "\033[92mBuilding ZendPHP image for CentOS 7...\033[0m"
	env DOCKER_BUILDKIT=1 docker build --secret id=crypt,src=credentials.centos --build-arg OS_VERSION=7 -t rbasayev/zendphp:centos7-php72 -f centos/Dockerfile.restricted .
	@echo "\033[92mZendPHP image building done!\033[0m"
	@echo

php56: ## Build ZendPHP 5.6 on Ubuntu 20.04 (behind auth) :ubuntu20-php56
	@cd "$(HERE)"
	@echo
	@echo "\033[92mBuilding ZendPHP image for Ubuntu 20.04...\033[0m"
	env DOCKER_BUILDKIT=1 docker build --secret id=crypt,src=credentials.apt --build-arg OS_VERSION=20.04 --build-arg ZENDPHP_VERSION=5.6 -t rbasayev/zendphp:ubuntu20-php56 -f ubuntu/Dockerfile.restricted .
	@echo "\033[92mZendPHP image building done!\033[0m"
	@echo

##@ Running the Image

run: ## Running :latest
	@cd "$(HERE)"
	@echo
	docker run --rm -Pti -v "$(HERE)":/_host rbasayev/zendphp:latest bash
	@echo

run-centos8: ## Running :centos8-php74
	@cd "$(HERE)"
	@echo
	docker run --rm -Pti -v "$(HERE)":/_host rbasayev/zendphp:centos8-php74 bash
	@echo

run-centos7: ## Running :centos7-php74
	@cd "$(HERE)"
	@echo
	docker run --rm -Pti -v "$(HERE)":/_host rbasayev/zendphp:centos7-php74 bash
	@echo

run-php72: ## Running :centos7-php72
	@cd "$(HERE)"
	@echo
	docker run --rm -Pti -v "$(HERE)":/_host rbasayev/zendphp:centos7-php72 bash
	@echo

run-php56: ## Running :ubuntu20-php56
	@cd "$(HERE)"
	@echo
	docker run --rm -Pti -v "$(HERE)":/_host rbasayev/zendphp:ubuntu20-php56 bash
	@echo




