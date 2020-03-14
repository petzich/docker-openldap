COMPOSE=sudo docker-compose
DOCKER=sudo docker
TEST=test/docker-compose.yml

.PHONY: default
default: build test

.PHONY: build
build:
	$(COMPOSE) build

.PHONY: clean
clean:
	$(COMPOSE) down -v
	$(COMPOSE) -f $(TEST) down -v

.PHONY: test
test:
	$(COMPOSE) -f $(TEST) down -v
	$(COMPOSE) -f $(TEST) run test slaptest
	$(COMPOSE) -f $(TEST) down -v

.PHONY: run
run:
	$(COMPOSE) -f $(TEST) down -v
	$(COMPOSE) -f $(TEST) up
	$(COMPOSE) -f $(TEST) down -v

.PHONY: shell
shell:
	$(COMPOSE) -f $(TEST) down -v
	$(COMPOSE) -f $(TEST) up -d
	$(COMPOSE) -f $(TEST) exec test /bin/sh
	$(COMPOSE) -f $(TEST) down -v

.PHONY: ci-checks
ci-checks:
	make shellcheck
	make shfmt-check

.PHONY: shellcheck
shellcheck:
	find bin/ -name "*.sh" -exec $(DOCKER) run --rm -v "${PWD}:/mnt:ro" koalaman/shellcheck:stable {} +

.PHONY: shfmt-check
shfmt-check:
	$(DOCKER) run --rm -v "${PWD}:/mnt:ro" -w /mnt jamesmstone/shfmt -d bin/

.PHONY: shfmt-format
shfmt-format:
	$(DOCKER) run --rm -v "${PWD}:/mnt" -w /mnt jamesmstone/shfmt -w bin/
