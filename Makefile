COMPOSE=sudo docker-compose
DOCKER=sudo docker
TEST=test/docker-compose.yml

.PHONY: build clean default run shell test

default: build test

build: Dockerfile conf.dist/*.ldif ldif.dist/*.ldif
	$(COMPOSE) build

clean:
	$(COMPOSE) down -v
	$(COMPOSE) -f $(TEST) down -v
	$(DOCKER) rmi test_test

test:
	$(COMPOSE) -f $(TEST) down -v
	$(COMPOSE) -f $(TEST) run test slapd -t
	$(COMPOSE) -f $(TEST) down -v

run:
	$(COMPOSE) -f $(TEST) down -v
	$(COMPOSE) -f $(TEST) up
	$(COMPOSE) -f $(TEST) down -v

shell:
	$(COMPOSE) -f $(TEST) down -v
	$(COMPOSE) -f $(TEST) up -d
	$(COMPOSE) -f $(TEST) exec test /bin/sh
	$(COMPOSE) -f $(TEST) down -v
