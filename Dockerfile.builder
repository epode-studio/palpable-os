# Palpable OS Builder Docker Image
#
# Use this to build the OS image on non-Linux systems (macOS, Windows)
#
# Usage:
#   docker build -t palpable-os-builder -f Dockerfile.builder .
#   docker run --rm --privileged -v $(pwd)/output:/output palpable-os-builder
#

FROM alpine:3.21

# Install build dependencies
RUN apk add --no-cache \
    bash \
    coreutils \
    dosfstools \
    e2fsprogs \
    e2fsprogs-extra \
    gawk \
    grep \
    jq \
    losetup \
    parted \
    rsync \
    util-linux \
    wget \
    xz

# Copy build scripts
WORKDIR /builder
COPY build.sh .
COPY rootfs-overlay/ rootfs-overlay/
COPY scripts/ scripts/
COPY configs/ configs/

# Make scripts executable
RUN chmod +x build.sh

# Default environment
ENV VERSION=dev
ENV OUTPUT_DIR=/output
ENV IMAGE_NAME=palpable-os
ENV ALPINE_VERSION=3.21

# Entry point
ENTRYPOINT ["/builder/build.sh"]
