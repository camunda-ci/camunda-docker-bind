# image settings for the docker image name, tags and container name while running
IMAGE_NAME?=registry.camunda.com/camunda-bind
TAGS?=latest
NAME=bind

VERSIONS=latest
BUILD_VERSIONS=$(addprefix build-,$(VERSIONS))
PUSH_VERSIONS=$(addprefix push-,$(VERSIONS))
# parent image name
FROM=$(shell head -n1 Dockerfile | cut -d " " -f 2)
# the first tag and the remaining tags split up
FIRST_TAG=$(firstword $(TAGS))
ADDITIONAL_TAGS=$(wordlist 2, $(words $(TAGS)), $(TAGS))
# the image name which will be build
IMAGE=$(IMAGE_NAME):$(FIRST_TAG)
# options to use for running the image, can be extended by FLAGS variable
OPTS=--name $(NAME) -p 1053:53 -p 1053:53/udp -p 18053:8053 -t $(FLAGS)
# the docker command which can be configured by the DOCKER_OPTS variable
DOCKER=docker $(DOCKER_OPTS)

# default build settings
REMOVE=true
FORCE_RM=true
NO_CACHE=false

.PHONY: build
build: pull-from pull build-image test ## build the image for the first tag and tag it for additional tags, (includes dirty hack to create db2 database with privileged mode)

.PHONY: build-image
build-image: ## build the image
	$(DOCKER) build --rm=$(REMOVE) --force-rm=$(FORCE_RM) --no-cache=$(NO_CACHE) --build-arg TAG_NAME=$(TAGS) -t $(IMAGE) .
	@for tag in $(ADDITIONAL_TAGS); do \
		$(DOCKER) tag $(IMAGE) $(IMAGE_NAME):$$tag; \
	done

.PHONY: pull
pull: ## pull image from registry
	-$(DOCKER) pull $(IMAGE)

.PHONY: pull-from
pull-from: ## pull parent image
	$(DOCKER) pull $(FROM)

.PHONY: push
push: ## push container to registry
	@for tag in $(TAGS); do \
		$(DOCKER) push $(IMAGE_NAME):$$tag; \
	done

.PHONY: build-all
build-all: $(BUILD_VERSIONS) ## build Docker image for every Oracle version

.PHONY: build-%s
build-%:
	make build TAGS=$*v$(FIRST_TAG)

.PHONY: push-all
push-all: $(PUSH_VERSIONS) ## push Docker image for every Oracle version

.PHONY: push-%s
push-%:
	make push TAGS=$*v$(FIRST_TAG)

.PHONY: tag-all
tag-all:
	@for version in $(VERSIONS); do \
		echo "Tagging: $${version}$(FIRST_TAG)"; \
		git tag -a -f -m "$${version}$(FIRST_TAG)" $${version}$(FIRST_TAG); \
	done

.PHONY: run
run: ## run container
	$(DOCKER) run --rm $(OPTS) $(IMAGE)

.PHONY: daemon
daemon: rmf ## run container in daemon mode
	$(DOCKER) run -d $(OPTS) $(IMAGE)

.PHONY: shell
shell: ## start interactive container with bash
	$(DOCKER) run --rm -i --entrypoint=/bin/bash $(OPTS) $(IMAGE) --

.PHONY: test
test: daemon ## test if image starts and database becomes ready afterwards
	$(DOCKER) exec -t $(NAME) bash -c 'dig kyocera-5th-floor.camunda.loc. @localhost -p 53 +notcp' | grep --quiet 'kyocera-5th-floor.camunda.loc. 86400 IN	A	192.168'
	$(DOCKER) exec -t $(NAME) bash -c 'dig kyocera-5th-floor.camunda.loc. @localhost -p 53 +tcp' | grep --quiet 'kyocera-5th-floor.camunda.loc. 86400 IN	A	192.168'
	$(DOCKER) exec -t $(NAME) bash -c 'curl localhost:8053' | grep --quiet 'statistics'
	-$(DOCKER) rm -f $(NAME)

.PHONY: rmf
rmf: ## remove container by name
	-$(DOCKER) rm -f $(NAME)

.PHONY: rmi
rmi: ## remove image with all tags
	@for tag in $(TAGS); do \
		$(DOCKER) rmi $(IMAGE_NAME):$$tag; \
	done

.PHONY: help
help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

