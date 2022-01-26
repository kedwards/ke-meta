mkfile_path:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

DOCKER_COMPOSE_DIR:=$(mkfile_path)/tools
DOCKER_COMPOSE_PATH:=docker-compose.yml

SCRIPT_DIR:=$(mkfile_path)/tools/scripts

ifdef COMPOSE
  DOCKER_COMPOSE_PATH=docker-compose.$(COMPOSE).yml
endif

DOCKER_COMPOSE_FILE:=$(DOCKER_COMPOSE_DIR)/$(DOCKER_COMPOSE_PATH)
DOCKER_COMPOSE:=docker-compose -f $(DOCKER_COMPOSE_FILE) --project-directory $(DOCKER_COMPOSE_DIR)

DEFAULT_GOAL := help

##@ [Targets]
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: cmd
cmd: # Run command in container. SVC=<service_name>, CMD="<cmd>"
	@docker-compose -f $(DOCKER_COMPOSE_DIR)/docker-compose.build.yml --project-directory $(DOCKER_COMPOSE_DIR) run --rm $(SVC) $(CMD)

.PHONY: down
down: ## Stop all running services
	@$(DOCKER_COMPOSE) down $(DEBUG)

.PHONY: up
up: ## Start RTLS service, [SVC=<service_name>]
	@$(DOCKER_COMPOSE) up -d --force-recreate --remove-orphans $(SVC)