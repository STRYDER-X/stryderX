.DEFAULT_GOAL := help
SHELL := /bin/bash

DOCKER_SERVICE := stryderx
ROOT_DIR       := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DOCKER_DIR     := $(ROOT_DIR)/stryderx_docker
LOG_DIR        := $(ROOT_DIR)/log
REPORT_FILE    := test_report.log
REPORT_PATH    := $(LOG_DIR)/$(REPORT_FILE)

INSIDE_CONTAINER := $(shell [ -f /.dockerenv ] && echo "true" || echo "false")

ifeq ($(INSIDE_CONTAINER), true)
    EXEC := /bin/bash -c
    HOST_ONLY = @echo -e "\033[31m[Error]\033[0m Target '$@' is Host-Only." && exit 1
    CONTEXT := \033[32mInside Container\033[0m
else
    EXEC := cd $(DOCKER_DIR) && docker compose exec $(DOCKER_SERVICE) /bin/bash -c
    HOST_ONLY = $(1)
    CONTEXT := \033[34mHost System\033[0m
endif

.PHONY: help up down shell build test lint report gate view docs setup purge clean

help: ## Show this help message
	@echo -e "Context: $(CONTEXT)"
	@echo -e "------------------------------------------------"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

env: ## [Host] Generate .env file
	$(call HOST_ONLY, $(DOCKER_DIR)/scripts/generate_env.sh)

up: env ## [Host] Start the robot container
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose up -d --build)

down: ## [Host] Stop the container
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose down)

shell: ## [Host] Open interactive shell
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose exec $(DOCKER_SERVICE) /bin/bash)

clean: ## [Host] Stop container and prune volumes
	$(call HOST_ONLY, $(MAKE) down && docker system prune -af --volumes)

setup: ## Initialize git hooks in root and submodules
	@chmod +x $(DOCKER_DIR)/setup_workspace.sh
	@$(EXEC) "$(DOCKER_DIR)/setup_workspace.sh"

build: ## Build ROS 2 workspace
	@$(EXEC) "source /opt/ros/humble/setup.bash && colcon build --symlink-install"

lint: ## Run pre-commit on root and submodules
	@find . -maxdepth 4 -name ".pre-commit-config.yaml" \
		-not -path "*/build/*" -not -path "*/install/*" | while read -r config; do \
		dir=$$(dirname $$config); \
		echo -e "\033[34m--> Linting: $$dir\033[0m"; \
		$(EXEC) "cd $$dir && pre-commit run --all-files"; \
	done

test: ## Run ROS 2 tests (excludes linters)
	-@$(EXEC) "source /opt/ros/humble/setup.bash && [ -f install/setup.bash ] && source install/setup.bash; \
	colcon test --event-handlers console_cohesion+ --ctest-args -E 'lint_cmake|uncrustify|cppcheck|copyright'"

report: ## Save test results to log/
	@mkdir -p $(LOG_DIR)
	@$(EXEC) "source /opt/ros/humble/setup.bash && [ -f install/setup.bash ] && source install/setup.bash; \
	colcon test-result --all --verbose" > $(REPORT_PATH) 2>&1
	@echo -e "\033[32m[Complete]\033[0m Results: $(REPORT_PATH)"

view: ## View latest test report
	@cat $(REPORT_PATH) || echo "No report found."

docs: ## Generate Doxygen for all packages
	@$(EXEC) "source /opt/ros/humble/setup.bash && colcon build --cmake-target docs"

gate: setup lint build test report ## Full pipeline: Setup -> Lint -> Build -> Test -> Report

purge: ## Remove build/install/log artifacts
	@rm -rf $(ROOT_DIR)/build/ $(ROOT_DIR)/install/ $(ROOT_DIR)/log/
	@find $(ROOT_DIR)/src -type d \( -name "build" -o -name "install" -o -name "log" \) -exec rm -rf {} +
