.DEFAULT_GOAL := help
SHELL := /bin/bash

DOCKER_SERVICE := stryderx
ROOT_DIR       := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DOCKER_DIR     := $(ROOT_DIR)/stryderx_docker
LOG_DIR        := $(ROOT_DIR)/log
REPORT_FILE    := test_report.log
REPORT_PATH    := $(LOG_DIR)/$(REPORT_FILE)

# ROS2 Packages; using = instead of := to execute only when variable is used.
ROS_PKGS       = $(shell colcon list -n 2>/dev/null)
ROS_PKG_PATHS  = $(shell colcon list -p 2>/dev/null)

# Add any directories you want to skip for linting/cleaning here
LINT_EXCLUDES  = third_party

# Filters out paths containing any words from LINT_EXCLUDES
PKG_PATHS_TO_LINT = $(foreach path,$(ROS_PKG_PATHS),$(if $(findstring $(LINT_EXCLUDES),$(path)),,$(path)))

INSIDE_CONTAINER = $(shell [ -f /opt/ros/humble/setup.bash ] && echo "true" || echo "false")

ifeq ($(INSIDE_CONTAINER), true)
    RUN = /bin/bash -c
else
    RUN = cd $(DOCKER_DIR) && docker compose exec $(DOCKER_SERVICE) /bin/bash -c
endif

define HOST_ONLY
	@if [ "$(INSIDE_CONTAINER)" = "true" ]; then \
		echo -e "\033[31m[Error]\033[0m Target '$@' is Host-Only. Cannot run inside container."; \
	else \
		$(1); \
	fi
endef

.PHONY: help env up down shell build test lint check purge purge-all clean \
        docker-up docker-down docker-shell ros-build ros-test ros-lint ros-report

help:
	@echo -e "\033[33mShortcuts (Quick Commands):\033[0m"
	@grep -E '^(up|down|build|test|lint|check):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo -e "\n\033[33mDocker Management (Host Only):\033[0m"
	@grep -E '^docker-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo -e "\n\033[33mROS 2 Development (Works Everywhere):\033[0m"
	@grep -E '^ros-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo -e "\n\033[33mMaintenance & Cleanup:\033[0m"
	@grep -E '^(env|purge|purge-all|clean):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: docker-up       ## Build and start the robot container
down: docker-down   ## Stop and remove the container
build: ros-build    ## Build the ROS 2 workspace
test: ros-report    ## Run tests and generate a report
lint: ros-lint      ## Auto-fix code formatting (skipping excludes)
check: lint build test ## Full Pipeline: Lint -> Build -> Test -> Report

env: ## [Host] Generate the .env file
	$(call HOST_ONLY, bash $(DOCKER_DIR)/scripts/generate_env.sh)

docker-up: env ## [Host] Start the container
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose up -d --build)

docker-down: ## [Host] Stop the container
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose down)

docker-shell: ## [Host] Open interactive shell in container
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose exec $(DOCKER_SERVICE) /bin/bash)

ros-build: ## Build ROS 2 workspace
	@$(RUN) "source /opt/ros/humble/setup.bash && colcon build --symlink-install"

ros-test: ## Run ROS 2 tests (Internal command)
	-@$(RUN) "source /opt/ros/humble/setup.bash && [ -f install/setup.bash ] && source install/setup.bash; colcon test --event-handlers console_cohesion+"

ros-report: ros-build ros-test ## Generate text file with all test failures
	@mkdir -p $(LOG_DIR)
	@$(RUN) "source /opt/ros/humble/setup.bash && [ -f install/setup.bash ] && source install/setup.bash; colcon test-result --all --verbose" > $(REPORT_PATH) 2>&1
	@echo -e "\n\033[32m[Complete]\033[0m Results saved to: $(REPORT_PATH)"

ros-lint: ## Auto-fix C++ and CMake formatting using package paths
	@echo "Detected Packages: $(ROS_PKGS)"
	@for path in $(PKG_PATHS_TO_LINT); do \
		relative_path=$${path#$(ROOT_DIR)/}; \
		echo "Processing $$relative_path..."; \
		$(RUN) "find $$relative_path -maxdepth 2 \( -name '*.hpp' -o -name '*.cpp' -o -name '*.h' -o -name '*.c' \) -print | xargs -r ament_uncrustify --reformat || true"; \
		$(RUN) "find $$relative_path -maxdepth 2 -name 'CMakeLists.txt' -print | xargs -r sed -i 's/[[:space:]]*$$//' || true"; \
	done

clean: ## [Host] Stop container and clean up docker cache
	$(call HOST_ONLY, $(MAKE) docker-down && docker system prune -af --volumes)

purge: ## [Safe] Remove build/install/log folders
	@echo "Purging ROS 2 artifacts..."
	@rm -rf $(ROOT_DIR)/build/ $(ROOT_DIR)/install/ $(ROOT_DIR)/log/ $(ROOT_DIR)/test_results/

purge-all: ## [Nuclear] Recursively remove ALL build/install/log folders
	@echo "Purging ALL build/install folders recursively..."
	@find $(ROOT_DIR) -mindepth 2 -type d \( -name "build" -o -name "install" -o -name "log" \) -prune -exec rm -rf {} +
	@rm -rf $(ROOT_DIR)/build/ $(ROOT_DIR)/install/ $(ROOT_DIR)/log/