.DEFAULT_GOAL := help
SHELL := /bin/bash

DOCKER_SERVICE := stryderx-core
DOCKER_HARDWARE_SERVICE := stryderx-robot
ROOT_DIR       := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DOCKER_DIR     := $(ROOT_DIR)/stryderx_docker
LOG_DIR        := $(ROOT_DIR)/log
REPORT_FILE    := test_report.log
REPORT_PATH    := $(LOG_DIR)/$(REPORT_FILE)

INSIDE_CONTAINER := $(shell [ -f /.dockerenv ] && echo "true" || echo "false")
ALLOW_HOST_CMDS ?= false

# List of packages that support Doxygen 'docs' target
DOC_PACKAGES := stryderx_hardware

ifeq ($(filter true,$(INSIDE_CONTAINER)),true)
    ifeq ($(filter-out true,$(ALLOW_HOST_CMDS)),)
        ifeq ($(filter hardware,$(MAKECMDGOALS)),hardware)
            EXEC := cd $(DOCKER_DIR) && docker compose --profile hardware exec $(DOCKER_HARDWARE_SERVICE) /bin/bash -c
        else
            EXEC := cd $(DOCKER_DIR) && docker compose exec $(DOCKER_SERVICE) /bin/bash -c
        endif
        HOST_ONLY = $(1)
        CONTEXT := \033[34mHost System\033[0m
    else
        EXEC := /bin/bash -c
        HOST_ONLY = @echo -e "\033[31m[Error]\033[0m Target '$@' is Host-Only." && exit 1
        CONTEXT := \033[32mInside Container\033[0m
    endif
else
    ifeq ($(filter hardware,$(MAKECMDGOALS)),hardware)
        EXEC := cd $(DOCKER_DIR) && docker compose --profile hardware exec $(DOCKER_HARDWARE_SERVICE) /bin/bash -c
    else
        EXEC := cd $(DOCKER_DIR) && docker compose exec $(DOCKER_SERVICE) /bin/bash -c
    endif
    HOST_ONLY = $(1)
    CONTEXT := \033[34mHost System\033[0m
endif

.PHONY: help up hardware down shell build test lint report gate view docs setup purge clean

help: ## Show this help message
	@echo -e "Context: $(CONTEXT)"
	@echo -e "------------------------------------------------"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

env: ## [Host] Generate .env file
	$(call HOST_ONLY, $(DOCKER_DIR)/scripts/generate_env.sh)

up: env ## [Host] Start core container; use `make up hardware` for robot hardware
ifeq ($(filter hardware,$(MAKECMDGOALS)),hardware)
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose --profile hardware up -d --build $(DOCKER_HARDWARE_SERVICE))
else
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose up -d --build $(DOCKER_SERVICE))
endif

hardware:
	@:

down: ## [Host] Stop containers
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose --profile hardware down --remove-orphans)

shell: ## [Host] Open core shell; use `make shell hardware` for robot hardware
ifeq ($(filter hardware,$(MAKECMDGOALS)),hardware)
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose exec $(DOCKER_HARDWARE_SERVICE) /bin/bash)
else
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose exec $(DOCKER_SERVICE) /bin/bash)
endif

clean: ## [Host] Remove only StryderX containers and Compose-managed volumes
	$(call HOST_ONLY, cd $(DOCKER_DIR) && containers=$$(docker compose --profile hardware ps -aq); \
		if [ -n "$$containers" ]; then docker rm -f $$containers; fi; \
		docker compose --profile hardware down --remove-orphans --volumes)

setup: ## Initialize git hooks in root and submodules
	@$(EXEC) "$(DOCKER_DIR)/scripts/setup_pre_commit.sh"

build: ## Build ROS 2 workspace
	@$(EXEC) "source /opt/ros/humble/setup.bash && colcon build --symlink-install"

lint: ## Run pre-commit on root and submodules
	@find . -maxdepth 4 -name ".pre-commit-config.yaml" \
		-not -path "*/build/*" -not -path "*/install/*" | while read -r config; do \
		dir=$$(dirname $$config); \
		echo -e "\033[34m--> Linting: $$dir\033[0m"; \
		$(EXEC) "source /opt/ros/humble/setup.bash && cd $$dir && pre-commit run --all-files"; \
	done

test: ## Run ROS 2 tests (excludes linters)
	@$(EXEC) "source /opt/ros/humble/setup.bash && [ -f install/setup.bash ] && source install/setup.bash; \
	colcon test --event-handlers console_cohesion+ --ctest-args -E 'lint_cmake|uncrustify|cppcheck|copyright'"

report: ## Save test results to log/
	@mkdir -p $(LOG_DIR)
	@$(EXEC) "source /opt/ros/humble/setup.bash && [ -f install/setup.bash ] && source install/setup.bash; \
	colcon test-result --all --verbose" > $(REPORT_PATH) 2>&1
	@echo -e "\033[32m[Complete]\033[0m Results: $(REPORT_PATH)"

view: ## View latest test report
	@cat $(REPORT_PATH) || echo "No report found."

docs: ## Generate Doxygen for selected packages
	@$(EXEC) "source /opt/ros/humble/setup.bash && colcon build --packages-select $(DOC_PACKAGES) --cmake-target docs"

gate: setup lint build test report ## Full pipeline: Setup -> Lint -> Build -> Test -> Report

purge: ## Remove build/install/log artifacts
	@rm -rf $(ROOT_DIR)/build/ $(ROOT_DIR)/install/ $(ROOT_DIR)/log/
	@find $(ROOT_DIR)/src -type d \( -name "build" -o -name "install" -o -name "log" \) -exec rm -rf {} +
