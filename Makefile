.DEFAULT_GOAL := help
SHELL := /bin/bash

DOCKER_SERVICE := stryderx
ROOT_DIR       := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DOCKER_DIR     := $(ROOT_DIR)/stryderx_docker
LOG_DIR        := $(ROOT_DIR)/log
REPORT_FILE    := test_report.log
REPORT_PATH    := $(LOG_DIR)/$(REPORT_FILE)

# ROS2 Package Discovery (Lazy evaluation for speed)
ROS_PKG_PATHS   = $(shell colcon list -p 2>/dev/null)
LINT_EXCLUDES   = third_party
PKG_PATHS_TO_LINT = $(foreach path,$(ROS_PKG_PATHS),$(if $(findstring $(LINT_EXCLUDES),$(path)),,$(path)))

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

.PHONY: help up down shell build test lint report check view purge clean

help: ## Show this help message
	@echo -e "Context: $(CONTEXT)"
	@echo -e "------------------------------------------------"
	@grep -E '^(help):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo -e "\n\033[33m(Host Only):\033[0m"
	@grep -E '^(up|down|shell|clean):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo -e "\n\033[33m(Dispatched to Packages):\033[0m"
	@grep -E '^(build|test|lint|report|check|view|docs|purge):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## [Host] Start the robot container
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose up -d --build)

down: ## [Host] Stop the container
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose down)

shell: ## [Host] Open interactive shell in container
	$(call HOST_ONLY, cd $(DOCKER_DIR) && docker compose exec $(DOCKER_SERVICE) /bin/bash)

clean: ## [Host] Nuclear clean: stop container and prune volumes
	$(call HOST_ONLY, $(MAKE) down && docker system prune -af --volumes)

build: ## Build ROS 2 workspace
	@$(EXEC) "source /opt/ros/humble/setup.bash && colcon build --symlink-install"

lint: ## Tell every package to lint itself using its own rules
	@for path in $(PKG_PATHS_TO_LINT); do \
		if [ -f $$path/Makefile ]; then \
			relative_path=$${path#$(ROOT_DIR)/}; \
			echo -e "\033[32m--> Executing internal lint for: $$relative_path\033[0m"; \
			$(EXEC) "make -C $$relative_path lint"; \
		else \
			relative_path=$${path#$(ROOT_DIR)/}; \
			echo -e "\033[33m[Skip]\033[0m No Makefile found in $$relative_path."; \
		fi; \
	done

test: ## Run ROS 2 tests (Console output)
	-@$(EXEC) "source /opt/ros/humble/setup.bash && [ -f install/setup.bash ] && source install/setup.bash; \
	colcon test --event-handlers console_cohesion+ --ctest-args -E 'lint_cmake|uncrustify|cppcheck|copyright'"

report: ## Save colcon test-result to log/
	@mkdir -p $(LOG_DIR)
	@$(EXEC) "source /opt/ros/humble/setup.bash && [ -f install/setup.bash ] && source install/setup.bash; \
	colcon test-result --all --verbose" > $(REPORT_PATH) 2>&1
	@echo -e "\n\033[32m[Complete]\033[0m Results saved to: $(REPORT_PATH)"

view: ## View the latest test report
	@cat $(REPORT_PATH) || echo "No report found. Run 'make report' first."

check: lint build test report ## Full Pipeline: Lint -> Build -> Test -> Report

docs: ## Generate documentation for all packages
	@for path in $(PKG_PATHS_TO_LINT); do \
		if [ -f $$path/Makefile ]; then \
			relative_path=$${path#$(ROOT_DIR)/}; \
			echo -e "\033[32m--> Generating Docs for: $$relative_path\033[0m"; \
			$(EXEC) "make -C $$relative_path docs"; \
		fi; \
	done

purge: ## Remove build/install/log folders
	@echo "Purging ROS 2 artifacts..."
	@rm -rf $(ROOT_DIR)/build/ $(ROOT_DIR)/install/ $(ROOT_DIR)/log/