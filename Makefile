# Palpable OS Alpine Builder
#
# Build a minimal Alpine-based OS image for Raspberry Pi Zero 2 W
#

VERSION ?= $(shell date +%Y.%m.%d)
OUTPUT_DIR ?= ./output
IMAGE_NAME ?= palpable-os
ALPINE_VERSION ?= 3.21

.PHONY: all build clean agent docker-build help

all: build

# Build the OS image (requires root/sudo)
build: agent
	@echo "Building Palpable OS $(VERSION)..."
	sudo VERSION=$(VERSION) OUTPUT_DIR=$(OUTPUT_DIR) IMAGE_NAME=$(IMAGE_NAME) \
		ALPINE_VERSION=$(ALPINE_VERSION) ./build.sh

# Build the agent binary for ARM64
agent:
	@echo "Building palpable-agent for ARM64..."
	cd ../../palpable-agent-go && $(MAKE) build-arm64
	mkdir -p ./cache
	cp ../../palpable-agent-go/bin/palpable-agent-linux-arm64 ./cache/palpable-agent

# Build using Docker (for macOS/non-Linux hosts)
docker-build: agent
	@echo "Building in Docker container..."
	docker build -t palpable-os-builder -f Dockerfile.builder .
	docker run --rm --privileged \
		-v $(PWD)/output:/output \
		-v $(PWD)/../palpable-agent-go/palpable-agent:/agent:ro \
		-e VERSION=$(VERSION) \
		-e OUTPUT_DIR=/output \
		palpable-os-builder

# Clean build artifacts
clean:
	rm -rf $(OUTPUT_DIR)
	rm -rf ../palpable-agent-go/palpable-agent

# Show help
help:
	@echo "Palpable OS Builder"
	@echo ""
	@echo "Targets:"
	@echo "  build        - Build the OS image (requires root on Linux)"
	@echo "  docker-build - Build using Docker (for macOS)"
	@echo "  agent        - Build the Go agent for ARM64"
	@echo "  clean        - Remove build artifacts"
	@echo ""
	@echo "Variables:"
	@echo "  VERSION      - Image version (default: date)"
	@echo "  OUTPUT_DIR   - Output directory (default: ./output)"
	@echo "  IMAGE_NAME   - Image name (default: palpable-os)"
