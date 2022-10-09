APPNAME  := $(shell basename $(CURDIR))
VERSION  := $(shell git describe --abbrev=0 --tags 2>/dev/null)
REVISION := $(shell git rev-parse HEAD 2>/dev/null)

ifeq ($(VERSION),)
VERSION := dev
endif

ifeq ($(REVISION),)
REVISION := unknown
endif

LDFLAGS_APPNAME  := -X "main.AppName=$(APPNAME)"
LDFLAGS_VERSION  := -X "main.Version=$(VERSION)"
LDFLAGS_REVISION := -X "main.Revision=$(REVISION)"
LDFLAGS          := -s -w -buildid= $(LDFLAGS_APPNAME) $(LDFLAGS_VERSION) $(LDFLAGS_REVISION) -extldflags -static
BUILDFLAGS       := -trimpath -ldflags '$(LDFLAGS)'

PKGNAME := $(shell go mod edit -json | jq -r '.Module.Path' | sed -E 's/packer-plugin-//')
BINNAME := $(APPNAME)_$(VERSION)_$(shell go env GOOS)_$(shell go env GOARCH)

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
	mkdir -p $(HOME)/.packer.d/plugins/$(PKGNAME)
	cp bin/$(APPNAME) $(HOME)/.packer.d/plugins/$(PKGNAME)/$(BINNAME)

.PHONY: snapshot
snapshot:
	goreleaser release --rm-dist --snapshot

.PHONY: release
release:
ifneq ($(GITHUB_TOKEN),)
	goreleaser release --rm-dist
endif

.PHONY: clean
clean:
	rm -rf bin
	rm -rf dist
	rm -rf $(HOME)/.packer.d/plugins/$(PKGNAME)
