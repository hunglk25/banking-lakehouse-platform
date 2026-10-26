COMPOSE := docker compose --env-file .env -f docker/docker-compose.yml

.PHONY: up down ps logs clean

up:
	$(COMPOSE) --profile core up -d

down:
	$(COMPOSE) --profile core down

ps:
	$(COMPOSE) --profile core ps

logs:
	$(COMPOSE) --profile core logs -f

clean:
	$(COMPOSE) --profile core down -v
