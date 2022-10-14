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
	trivy fs -q -s HIGH,CRITICAL --security-checks vuln,config,secret,license .

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
	mkdir -p $(PLUGIN_PATH)
	cp bin/$(APPNAME) $(PLUGIN_PATH)/$(PLUGIN_NAME)
	cd bin && sha256sum $(APPNAME) > $(PLUGIN_PATH)/$(PLUGIN_NAME)_SHA256SUM

.PHONY: check
check: install
	cd bin && packer-sdc plugin-check $(APPNAME)

.PHONY: run
run: check
	packer init example
	packer build example

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
	rm -rf $(PLUGIN_PATH)
