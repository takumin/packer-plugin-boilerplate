OWNER_NAME := Takumi Takahashi
OWNER_MAIL := takumiiinn@gmail.com

APPNAME  := $(shell basename $(CURDIR))
PKGNAME  := $(shell go mod edit -json | jq -r '.Module.Path')
VERSION  := $(shell git describe --abbrev=0 --tags 2>/dev/null)
REVISION := $(shell git rev-parse HEAD 2>/dev/null)
SOURCES  := $(shell find . -type f -name '*.go')

ifeq ($(VERSION),)
VERSION := 0.0.1
endif

ifeq ($(REVISION),)
REVISION := unknown
endif

LDFLAGS_VERSION  := -X "$(PKGNAME)/version.Version=$(VERSION)"
LDFLAGS_REVISION := -X "$(PKGNAME)/version.Revision=$(REVISION)"
LDFLAGS          := -s -w -buildid= $(LDFLAGS_VERSION) $(LDFLAGS_REVISION) -extldflags -static
BUILDFLAGS       := -trimpath -ldflags '$(LDFLAGS)'

API_VERSION := x5.0
PLUGIN_REPO := $(shell echo "$(PKGNAME)" | sed -E 's/packer-plugin-//')
PLUGIN_NAME := $(APPNAME)_$(VERSION)_$(API_VERSION)_$(shell go env GOOS)_$(shell go env GOARCH)
PLUGIN_PATH := $(HOME)/.packer.d/plugins/$(PLUGIN_REPO)

.PHONY: all
all: clean tools generate fmt vet sec vuln lint test build

.PHONY: tools
tools:
	aqua install --all

.PHONY: generate
generate:
	go generate ./...

.PHONY: fmt
fmt:
	gofmt -e -d .

.PHONY: vet
vet:
	go vet ./...

.PHONY: sec
sec:
	gosec -quiet -fmt golint ./...

.PHONY: vuln
vuln:
	trivy fs -q -s HIGH,CRITICAL --scanners vuln,config,secret,license .

.PHONY: lint
lint:
	staticcheck ./...

.PHONY: test
test:
	go test -race ./...

.PHONY: build
build: bin/$(APPNAME)
bin/$(APPNAME): $(SOURCES)
	CGO_ENABLED=0 go build $(BUILDFLAGS) -o $@

.PHONY: describe
describe: build
	bin/$(APPNAME) describe

.PHONY: install
install: $(PLUGIN_PATH)/$(PLUGIN_NAME)
$(PLUGIN_PATH)/$(PLUGIN_NAME): bin/$(APPNAME)
	packer plugins install --path bin/$(APPNAME) $(PLUGIN_REPO)

.PHONY: check
check: install
	cd bin && packer-sdc plugin-check $(APPNAME)

.PHONY: run
run: check
	packer build example

.PHONY: gpg
gpg: secret/gpghome
secret/gpghome:
	@mkdir -p -m 0700 secret/gpghome
	@gpg \
		--homedir secret/gpghome \
		--pinentry-mode loopback \
		--passphrase '' \
		--no-tty \
		--quick-generate-key \
		"$(OWNER_NAME) <$(OWNER_MAIL)>" \
		future-default default 0

.PHONY: snapshot
snapshot: build gpg
	API_VERSION="$(shell ./bin/$(APPNAME) describe | jq -r '.api_version')" goreleaser release --clean --snapshot

.PHONY: release
release: build gpg
ifneq ($(GITHUB_TOKEN),)
	API_VERSION="$(shell ./bin/$(APPNAME) describe | jq -r '.api_version')" goreleaser release --clean
endif

.PHONY: clean
clean:
	rm -rf bin
	rm -rf dist
	rm -rf secret
	rm -rf $(PLUGIN_PATH)
