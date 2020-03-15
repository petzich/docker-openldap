COMPOSE=sudo docker-compose
DOCKER=sudo docker
TEST=test/docker-compose.yml

.PHONY: test
test: build
	$(COMPOSE) -f $(TEST) down -v
	$(COMPOSE) -f $(TEST) build test
	$(COMPOSE) -f $(TEST) up -d
	$(COMPOSE) -f $(TEST) exec test /test.sh
	$(COMPOSE) -f $(TEST) restart test
	$(COMPOSE) -f $(TEST) exec test /test.sh
	$(COMPOSE) -f $(TEST) down -v

.PHONY: build
build:
	$(COMPOSE) build

.PHONY: clean
clean:
	$(COMPOSE) down -v
	$(COMPOSE) -f $(TEST) down -v
	- $(DOCKER) rmi `$(DOCKER) images | grep -E "petzi/openldap.*(latest|<none>)" | awk -F" " '{print $$3}'`

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
	find dist/ test/ -name "*.sh" -exec $(DOCKER) run --rm -v "${PWD}:/mnt:ro" koalaman/shellcheck:stable {} +

.PHONY: shfmt-check
shfmt-check:
	$(DOCKER) run --rm -v "${PWD}:/mnt" -w /mnt jamesmstone/shfmt -d dist/ test/

.PHONY: shfmt-format
shfmt-format:
	$(DOCKER) run --rm -v "${PWD}:/mnt" -w /mnt jamesmstone/shfmt -w dist/ test/
