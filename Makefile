-include .env

COMPOSE ?= docker compose
THEME_SLUG ?= starter
THEME_DIR := wordpress/wp-content/themes/$(THEME_SLUG)
WP_UID ?= $(shell id -u)
WP_GID ?= $(shell id -g)

.PHONY: up down clean logs install wait composer npm wp dev build sage-theme

up:
	$(COMPOSE) up -d --build wordpress db mailpit phpmyadmin

down:
	$(COMPOSE) down

# Остановить и удалить контейнеры вместе с базой данных
clean:
	$(COMPOSE) --profile dev --profile tools down -v

logs:
	$(COMPOSE) logs -f wordpress db mailpit phpmyadmin

wait: up
	@echo "Waiting for WordPress HTTP..."
	@until $(COMPOSE) exec -T wordpress bash -lc 'curl -sf -o /dev/null http://127.0.0.1/wp-admin/install.php'; do \
		sleep 2; \
	done
	@echo "WordPress is up."

sage-theme: wait
	@bash scripts/bootstrap-theme.sh

install: sage-theme
	@mkdir -p wordpress/wp-content/uploads wordpress/wp-content/cache
	@chown -R 33:33 wordpress/wp-content/uploads wordpress/wp-content/cache 2>/dev/null || chmod -R a+rwX wordpress/wp-content/uploads wordpress/wp-content/cache
	@bash scripts/install.sh

composer:
	$(COMPOSE) run --rm --no-deps --user $(WP_UID):$(WP_GID) -w /var/www/html/wp-content/themes/$(THEME_SLUG) wordpress composer $(cmd)

npm:
	$(COMPOSE) --profile dev run --rm --no-deps node npm $(cmd)

wp:
	$(COMPOSE) --profile tools run --rm --no-deps wpcli $(cmd)

dev:
	$(COMPOSE) --profile dev up node

build:
	$(COMPOSE) --profile dev run --rm --no-deps node npm run build
