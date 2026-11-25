.PHONY: lint syntax dry-run lab-up lab-down provision test

lint:
	./scripts/lint.sh

syntax:
	./scripts/syntax-check.sh

dry-run:
	./scripts/dry-run.sh --inventory inventories/dev

lab-up:
	./scripts/lab-up.sh

lab-down:
	./scripts/lab-down.sh

provision:
	./scripts/provision.sh --inventory inventories/dev

test:
	./tests/run.sh
