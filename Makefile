# Set Bash as the shell so that Bash-specific syntax works
SHELL := /bin/bash

# Load environment variables in order of precedence (later files override earlier ones)
# The -include directive will silently ignore missing files
# this is useful when accessing envs from this Makefile or from docker-compose.yml files.
-include .env
-include .env.local
-include .env.dev
-include .env.dev.local

# Export all variables
export

# Docker config
COMPOSE_PROJECT_NAME = TODO_RENAME
DOCKER_COMPOSE_FILE = ./docker/dev/docker-compose.dev.yml
COMPOSE = docker compose --file $(DOCKER_COMPOSE_FILE) --project-name $(COMPOSE_PROJECT_NAME)
COMPOSE_INIT = DOCKERFILE=./docker/dev/Dockerfile.devInit $(COMPOSE)

# Smart container execution - runs in existing container or starts new one
define run_in_container_smart
	@if [ $$( $(COMPOSE) ps --status running --services | grep -c app) -gt 0 ]; then \
		echo "attaching to running container..."; \
		$(COMPOSE) exec $(1) $(2); \
	else \
		echo "starting container and running command..."; \
		$(COMPOSE) run --rm --service-ports $(1) $(2) && \
		$(MAKE) stop; \
	fi
endef

init: ## to run only once before git/pnpm/devs are setup
	$(MAKE) create-env-files
	$(COMPOSE_INIT) build
	$(COMPOSE_INIT) run --rm --service-ports app bash

# REQUIRED COMMANDS (must be implemented in every project)
install: ## Install everything needed for development
	$(MAKE) docker-build
	$(MAKE) pnpm-install

dev: ## Start development server
	$(MAKE) pnpm-dev

bash: ## Access container shell
	$(call run_in_container_smart,app,bash)

run: ## Run arbitrary command in container (for LLM agents)
	$(call run_in_container_smart,app,$(cmd))

clean-soft: ## keep volumes
	$(MAKE) pnpm-clean
	$(MAKE) docker-clean-soft

clean-hard: ## Clean everything (containers, volumes, dependencies)
	$(MAKE) pnpm-clean
	$(MAKE) docker-clean-hard

clean-install: ## Clean everything (containers, volumes, dependencies)
	$(MAKE) pnpm-clean
	$(MAKE) docker-clean-hard
	$(MAKE) docker-build-force
	$(MAKE) pnpm-install

opencode:
	$(call run_in_container_smart,app,bash -c "pnpm exec opencode upgrade && pnpm exec opencode")

stop: ## Stop all containers
	$(COMPOSE) down --remove-orphans

# UTILITY COMMANDS
docker-build: ## Build development image
	$(COMPOSE) build

docker-build-force: ## Force rebuild image
	$(COMPOSE) build --no-cache

docker-clean: ## Clean all docker containers
	$(COMPOSE) down --rmi all --remove-orphans

docker-clean-hard: ## Clean all docker containers with volumes
	$(COMPOSE) down --rmi all --volumes --remove-orphans

create-env-files: ## Create required environment files
	@if [ ! -f .env.local ]; then \
		echo "# GLOBAL SECRETS - NEVER COMMIT" > .env.local; \
	fi
	@if [ ! -f .env.dev.local ]; then \
		echo "# DEV SECRETS - NEVER COMMIT" > .env.dev.local; \
	fi
	@if [ ! -f .env.prod.local ]; then \
		echo "# PROD SECRETS - NEVER COMMIT" > .env.prod.local; \
	fi
	@if [ ! -f .env ]; then \
		echo "# GLOBAL NON SECRETS - SAFE TO COMMIT" > .env; \
	fi
	@if [ ! -f .env.dev ]; then \
		echo "# DEV NON SECRETS - SAFE TO COMMIT" > .env.dev; \
	fi
	@if [ ! -f .env.prod ]; then \
		echo "# PROD NON SECRETS - SAFE TO COMMIT" > .env.prod; \
	fi
	@if [ ! -f .env.llms.local ]; then \
    		mv .env.llms.example .env.llms.local || \
            echo "# llms SECRETS - NEVER COMMIT" > .env.llms.local; \
	fi

pnpm-install: ## Install pnpm dependencies
	$(call run_in_container_smart,app,pnpm install)

pnpm-dev: ## Install pnpm dependencies
	$(call run_in_container_smart,app,bash -c "pnpm run dev")

pnpm-clean: ## Clean pnpm dependencies
	$(call run_in_container_smart,app,pnpm run clean)

pnpm-build: ## Build production image
	$(call run_in_container_smart,app,pnpm run build)

pnpm-start: ## Start production image
		$(call run_in_container_smart,app,bash -c "pnpm dlx convex dev & pnpm start")


# CONVEX COMMANDS
convex-login: ## Login to Convex cloud
	$(call run_in_container_smart,app,pnpm dlx convex login)

convex-logout: ## Logout from Convex cloud
	$(call run_in_container_smart,app,pnpm dlx convex logout)

convex-dev: ## Start Convex development server
	$(call run_in_container_smart,app,pnpm dlx convex dev)

convex-dev-once: ## Deploy to convex dev server once (non watch mode)
	$(call run_in_container_smart,app,pnpm dlx convex dev --until-success)

convex-deploy: ## Deploy Convex functions to production
	$(call run_in_container_smart,app,pnpm dlx convex deploy --prod)


corepack-update:
	$(call run_in_container_smart,app,bash -c "corepack prepare pnpm@latest --activate && corepack use pnpm@latest")
	$(MAKE) install

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
