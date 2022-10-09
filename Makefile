APPNAME  := $(shell basename $(CURDIR))
PKGNAME  := $(shell go mod edit -json | jq -r '.Module.Path')
VERSION  := $(shell git describe --abbrev=0 --tags 2>/dev/null)
REVISION := $(shell git rev-parse HEAD 2>/dev/null)

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
PLUGIN_PATH := $(shell echo "$(PKGNAME)" | sed -E 's/packer-plugin-//')
PLUGIN_NAME := $(APPNAME)_$(VERSION)_$(API_VERSION)_$(shell go env GOOS)_$(shell go env GOARCH)

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
	trivy fs -q -s HIGH,CRITICAL --security-checks vuln,config,secret,license .

.PHONY: lint
lint:
	staticcheck ./...

.PHONY: test
test:
	CGO_ENABLED=0 go test ./...

.PHONY: build
build: bin/$(APPNAME)
bin/$(APPNAME): $(SRCS)
	CGO_ENABLED=0 go build $(BUILDFLAGS) -o $@

.PHONY: describe
describe: build
	bin/$(APPNAME) describe

.PHONY: install
install: build
	mkdir -p $(HOME)/.packer.d/plugins/$(PLUGIN_PATH)
	cp bin/$(APPNAME) $(HOME)/.packer.d/plugins/$(PLUGIN_PATH)/$(PLUGIN_NAME)
	cd bin && sha256sum $(APPNAME) > $(HOME)/.packer.d/plugins/$(PLUGIN_PATH)/$(PLUGIN_NAME)_SHA256SUM

.PHONY: check
check: install
	cd bin && packer-sdc plugin-check $(APPNAME)

.PHONY: init
init: install
	packer init example

.PHONY: snapshot
snapshot: build
	API_VERSION="$(shell ./bin/$(APPNAME) describe | jq -r '.api_version')" goreleaser release --rm-dist --snapshot

.PHONY: release
release: build
ifneq ($(GITHUB_TOKEN),)
	API_VERSION="$(shell ./bin/$(APPNAME) describe | jq -r '.api_version')" goreleaser release --rm-dist
endif

.PHONY: clean
clean:
	rm -rf bin
	rm -rf dist
	rm -rf $(HOME)/.packer.d/plugins/$(PLUGIN_PATH)
