.DEFAULT_GOAL := help
CONTAINER_NAME := stryderx-robot
DOCKER_SERVICE := stryderx
DOCKER_DIR := stryderx_docker


.PHONY: all up down env help clean

help: ## Show this help message
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

all: up

env: ## Generate the .env file.
	@bash $(DOCKER_DIR)/scripts/generate_env.sh

up: env ## Generate env variables, build, and start the container
	@cd $(DOCKER_DIR) && docker compose up -d --build

down: ## Stop and remove the container
	@cd $(DOCKER_DIR) && docker compose down

shell: ## Open an interactive bash shell inside the container
	cd $(DOCKER_DIR) && docker compose exec $(DOCKER_SERVICE) /bin/bash

clean: down ## Stop containers and clean up docker system cache
	@docker system prune -af --volumes