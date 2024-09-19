-include dockerfile-commons/recipes/clean-docker.mk
-include dockerfile-commons/recipes/lint-dockerfiles.mk
-include dockerfile-commons/recipes/test-dockerfiles.mk
-include dockerfile-commons/docker-funcs.mk

SHELL := /bin/bash

IMAGE_NAME = semenovp/tiny-lean4-toolchain
ELAN_VER?=$(shell $(call get_latest_version,"https://github.com/leanprover/elan.git"))

VCS_REF=$(shell git rev-parse --short HEAD)


.PHONY: help
help:  ## Prints the help.
	@echo 'Commands:'
	@grep --no-filename -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) |\
	 awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'


.DEFAULT_GOAL := all
.PHONY: all
all: build clean test;


.PHONY: build
build: export BUILD_ARGS='vcsref="$(VCS_REF)"'
build:  ## Builds the image for Lean4 toolchain.
	@$(call build_docker_image,"$(IMAGE_NAME):latest","$(BUILD_ARGS)",".")


.PHONY: clean
clean: clean-docker;


.PHONY: test
test:  ## Tests the the already built docker image.
	@$(call goss_docker_image,"$(IMAGE_NAME):latest","tests/elan.yaml","elan_version=$(ELAN_VER)",)
