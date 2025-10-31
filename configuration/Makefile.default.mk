SHELL                         = /bin/bash
MAKEFILE_LOCATION             = $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
BUILD_TAG                     = $(CONTAINER_BUILD_TAG)
REGISTRY                      = $(CONTAINER_PUBLISH_REGISTRY)
REPOSITORY_BASE               = $(CONTAINER_BASE_REPOSITORY)
IMAGE_TAG_SUFFIX              ?= $(if $(CONTAINER_IMAGE_SUFFIX),$(CONTAINER_IMAGE_SUFFIX),slim)
SCRIPT_FILE                   ?= $(if $(SCRIPT_FILE_EXEC),$(SCRIPT_FILE_EXEC),./build-astra-image.sh)
SCRIPT_ARGS                   = $(SCRIPT_ADDITIONAL_ARGS)
IMAGE_ARGS                    = $(CONTAINER_ADDITIONAL_ARGS)
DOCKER_BIN                    ?= $(if $(CONTAINER_BIN),$(CONTAINER_BIN),docker)
IMAGE_NAME                    ?= $(if $(CONTAINER_IMAGE_NAME),$(CONTAINER_IMAGE_NAME),astra)
IMAGE_BUILDER_FILE            ?= $(if $(CONTAINER_IMAGE_BUILDER_FILE),$(CONTAINER_IMAGE_BUILDER_FILE),Dockerfile-astra-slim)
SUPPORTED_TAGS                := 1.7.5 1.7.6 1.7.7 1.7.8 1.8.1 1.8.2 1.8.3

## Define arch
ifneq ($(filter $(BUILD_TAG),$(SUPPORTED_TAGS)),)
	MAJOR_MINOR                 := $(word 1,$(subst ., ,$(BUILD_TAG))).$(word 2,$(subst ., ,$(BUILD_TAG)))
	ARCHITECTURE                := $(MAJOR_MINOR)_x86-64
	REPOSITORY                  := $(REPOSITORY_BASE)/astra-cache-$(BUILD_TAG)
else
$(error ERROR: Unsupported BUILD_TAG: $(BUILD_TAG). Supported: $(SUPPORTED_TAGS))
endif

## To see all colors, run:
#+ bash -c 'for c in {0..255}; do tput setaf "${c}"; tput setaf "${c}" | cat -v; echo ="${c}"; done'
## The first 15 entries are the 8-bit colors
## For work needed set TERM to xterm: 'export TERM=xterm-256color'
## Define standard colors
ifneq (,$(findstring xterm,${TERM}))
	BLACK                       := $(shell tput -Txterm setaf 0)
	RED                         := $(shell tput -Txterm setaf 1)
	GREEN                       := $(shell tput -Txterm setaf 2)
	YELLOW                      := $(shell tput -Txterm setaf 3)
	LIGHTPURPLE                 := $(shell tput -Txterm setaf 4)
	PURPLE                      := $(shell tput -Txterm setaf 5)
	BLUE                        := $(shell tput -Txterm setaf 6)
	WHITE                       := $(shell tput -Txterm setaf 7)
	RESET                       := $(shell tput -Txterm sgr0)
else
	BLACK                       := ""
	RED                         := ""
	GREEN                       := ""
	YELLOW                      := ""
	LIGHTPURPLE                 := ""
	PURPLE                      := ""
	BLUE                        := ""
	WHITE                       := ""
	RESET                       := ""
endif

## Set target color
TARGET_COLOR                  := $(BLUE)
POUND                         = \#

## Target special targets are called phony and you can explicitly tell Make they're not associated with files
.PHONY: no_targets__ help help-colors variables-list build push slim clean
	no_targets__:

.DEFAULT_GOAL := default

default:
	@echo "Usage:"
	@echo -e "\tmake\t${TARGET_COLOR}<target>${RESET}"
	@echo
	@echo "Targets:"
	@$(MAKE) -f $(MAKEFILE_LOCATION) --no-print-directory help

help-colors: ## Show all the colors
	@echo "${BLACK}BLACK${RESET}"
	@echo "${RED}RED${RESET}"
	@echo "${GREEN}GREEN${RESET}"
	@echo "${YELLOW}YELLOW${RESET}"
	@echo "${LIGHTPURPLE}LIGHTPURPLE${RESET}"
	@echo "${PURPLE}PURPLE${RESET}"
	@echo "${BLUE}BLUE${RESET}"
	@echo "${WHITE}WHITE${RESET}"

help:
	@grep --no-filename -E '^[a-zA-Z_0-9%-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN { FS = ":.*? ## " }; { printf "\t${TARGET_COLOR}%-50s${RESET} %-60s\n", $$1, $$2 }'

target-list: ## Show Makefile available target
	@bash -c "$(MAKE) -f $(MAKEFILE_LOCATION) -p no_targets__ \
		| awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' \
		| grep -v '__\$$' | grep -vE '*[1]' | grep -vE 'Makefile*' \
		| sort"

## Check if 'CONTAINER_SKIP_SLIM' is 'TRUE' then run targets without create slim
ifeq ($(CONTAINER_SKIP_SLIM), TRUE)
all: variables-list build push clean
else
all: variables-list build push slim clean
endif

# Put this at the point where you want to see the variable values
variables-list: ## Show variables defined on this Makefile build
	$(foreach v, $(.VARIABLES), $(if $(filter file,$(origin $(v))), $(info $(v)=$($(v)))))
	@echo "${GREEN}---VARIABLES PREVIEW IS OVER---${RESET}"
	@echo

build: ## Building release build
	@echo
	@echo "${YELLOW}---BUILD ASTRA IMAGE---${RESET}"
	$(SCRIPT_FILE) -t $(BUILD_TAG) -c $(ARCHITECTURE) -r $(REPOSITORY) $(SCRIPT_ARGS)
	@echo "${GREEN}---END BUILD ASTRA IMAGE---${RESET}"

push: build ## Tag and push image to registry
	@echo
	@echo "${YELLOW}---PUSH ASTRA IMAGE---${RESET}"
	$(DOCKER_BIN) tag $(IMAGE_NAME):$(BUILD_TAG) $(REGISTRY)/astra:$(BUILD_TAG)
	$(DOCKER_BIN) push $(REGISTRY)/$(IMAGE_NAME):$(BUILD_TAG)
	@echo "${GREEN}---END PUSH ASTRA IMAGE---${RESET}"
	@echo
	@echo "${YELLOW}---CALCULATE ASTRA IMAGE SIZE---${RESET}"
	@echo "Size of $(REGISTRY)/$(IMAGE_NAME):$(BUILD_TAG):"
	@$(DOCKER_BIN) image inspect --format '{{.Size}}' $(REGISTRY)/$(IMAGE_NAME):$(BUILD_TAG) | numfmt --to=si
	@echo "${GREEN}---END CALCULATE ASTRA IMAGE SIZE---${RESET}"
	@echo

slim: build ## Build and push slim image
	@echo
	@echo "${YELLOW}---BUILD $(IMAGE_TAG_SUFFIX)---${RESET}"
	$(DOCKER_BIN) build --progress=plain -f $(IMAGE_BUILDER_FILE) --build-arg image_registry=$(REGISTRY)/ --build-arg image_version=$(BUILD_TAG) -t $(REGISTRY)/$(IMAGE_NAME):$(BUILD_TAG)-$(IMAGE_TAG_SUFFIX) $(IMAGE_ARGS) .
	$(DOCKER_BIN) push $(REGISTRY)/$(IMAGE_NAME):$(BUILD_TAG)-$(IMAGE_TAG_SUFFIX)
	@echo "${GREEN}---END BUILD $(IMAGE_TAG_SUFFIX)---${RESET}"
	@echo
	@echo "${YELLOW}---CALCULATE ASTRA IMAGE SIZE---${RESET}"
	@echo "Size of $(REGISTRY)/$(IMAGE_NAME):$(BUILD_TAG)-$(IMAGE_TAG_SUFFIX):"
	@$(DOCKER_BIN) image inspect --format '{{.Size}}' $(REGISTRY)/$(IMAGE_NAME):$(BUILD_TAG)-$(IMAGE_TAG_SUFFIX) | numfmt --to=si
	@echo "${GREEN}---END CALCULATE ASTRA IMAGE SIZE---${RESET}"
	@echo

clean: ## Cleanup images
	@$(DOCKER_BIN) image prune -f
	@$(DOCKER_BIN) rmi $(REGISTRY)/$(IMAGE_NAME):$(BUILD_TAG)-$(IMAGE_TAG_SUFFIX) $(REGISTRY)/$(IMAGE_NAME):$(BUILD_TAG) $(IMAGE_NAME):$(BUILD_TAG) || true
