
SHELL = /bin/bash
.SHELLFLAGS = -o pipefail -c

# https://github.com/golang/go/wiki/LoopvarExperiment
export GOEXPERIMENT := loopvar

.PHONY: help
help: ## Print info about all commands
	@echo "Commands:"
	@echo
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[01;32m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## Build all executables
	go build ./cmd/bigsky

.PHONY: all
all: build

.PHONY: test
test: ## Run tests
	go test ./...

.PHONY: test-short
test-short: ## Run tests, skipping slower integration tests
	go test -test.short ./...

.PHONY: coverage-html
coverage-html: ## Generate test coverage report and open in browser
	go test ./... -coverpkg=./... -coverprofile=test-coverage.out
	go tool cover -html=test-coverage.out

.PHONY: lint
lint: ## Verify code style and run static checks
	go vet ./...
	test -z $(gofmt -l ./...)

.PHONY: fmt
fmt: ## Run syntax re-formatting (modify in place)
	go fmt ./...

.PHONY: check
check: ## Compile everything, checking syntax (does not output binaries)
	go build ./...

.env:
	if [ ! -f ".env" ]; then cp example.dev.env .env; fi

.PHONY: run-postgres
run-postgres: .env ## Runs a local postgres instance
	docker compose -f cmd/bigsky/docker-compose.yml up -d

.PHONY: build-bigsky-admin-ui
build-bigsky-admin-ui: ## Build relay admin web UI
	cd  ts; yarn install --frozen-lockfile; yarn build
	mkdir -p public
	cp -r ts/dist/* public/

.PHONY: sc-reload
sc-reload: # Reloads supercollider
	go run cmd/supercollider/main.go \
		reload \
		--port 6125 --total-events 2000000 \
		--hostname alpha.supercollider.jazco.io \
		--key-file out/alpha.pem \
		--output-file out/alpha_in.cbor

.PHONY: sc-fire
sc-fire: # Fires supercollider
	go run cmd/supercollider/main.go \
		fire \
		--port 6125 --events-per-second 10000 \
		--hostname alpha.supercollider.jazco.io \
		--key-file out/alpha.pem \
		--input-file out/alpha_in.cbor
