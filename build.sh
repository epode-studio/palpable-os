#!/bin/bash
#
# Alpine Linux Image Builder for Raspberry Pi Zero 2 W
#
# Creates a minimal Alpine-based OS image with:
# - A/B root partition layout for atomic updates
# - Palpable agent pre-installed
# - Read-only root filesystem
# - WiFi provisioning support
#
# Usage: ./build.sh [--version VERSION] [--output OUTPUT_DIR]
#

set -e

# Configuration
ALPINE_VERSION="${ALPINE_VERSION:-3.21}"
ALPINE_MIRROR="https://dl-cdn.alpinelinux.org/alpine"
PI_ARCH="aarch64"  # Pi Zero 2 W is 64-bit ARM
OUTPUT_DIR="${OUTPUT_DIR:-./output}"
IMAGE_NAME="${IMAGE_NAME:-palpable-os}"
VERSION="${VERSION:-$(date +%Y.%m.%d)}"

# Partition sizes (MB)
BOOT_SIZE=256
ROOT_SIZE=512  # Per slot
DATA_SIZE=512
TOTAL_SIZE=$((BOOT_SIZE + ROOT_SIZE * 2 + DATA_SIZE + 16))  # +16 for alignment

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[BUILD]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version) VERSION="$2"; shift 2 ;;
        --output) OUTPUT_DIR="$2"; shift 2 ;;
        --help) echo "Usage: $0 [--version VERSION] [--output OUTPUT_DIR]"; exit 0 ;;
        *) error "Unknown option: $1" ;;
    esac
done

# Check dependencies
check_deps() {
    local deps=("wget" "dd" "losetup" "mkfs.ext4" "mkfs.vfat" "rsync")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || error "Missing dependency: $dep"
    done

    # Check for root
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root"
    fi
}

# Download Alpine rootfs
download_alpine() {
    local rootfs_url="${ALPINE_MIRROR}/v${ALPINE_VERSION}/releases/${PI_ARCH}/alpine-rpi-${ALPINE_VERSION}.0-${PI_ARCH}.tar.gz"
    local rootfs_file="alpine-rootfs.tar.gz"

    log "Downloading Alpine Linux ${ALPINE_VERSION} for ${PI_ARCH}..."

    mkdir -p "${OUTPUT_DIR}/cache"

    if [ ! -f "${OUTPUT_DIR}/cache/${rootfs_file}" ]; then
        wget -q --show-progress -O "${OUTPUT_DIR}/cache/${rootfs_file}" "${rootfs_url}" || {
            # Try minirootfs as fallback
            local mini_url="${ALPINE_MIRROR}/v${ALPINE_VERSION}/releases/${PI_ARCH}/alpine-minirootfs-${ALPINE_VERSION}.0-${PI_ARCH}.tar.gz"
            wget -q --show-progress -O "${OUTPUT_DIR}/cache/${rootfs_file}" "${mini_url}"
        }
    else
        log "Using cached Alpine rootfs"
    fi

    echo "${OUTPUT_DIR}/cache/${rootfs_file}"
}

# Create disk image with A/B partitions
create_image() {
    local image_file="${OUTPUT_DIR}/${IMAGE_NAME}-${VERSION}.img"

    log "Creating ${TOTAL_SIZE}MB disk image..."

    # Create empty image
    dd if=/dev/zero of="${image_file}" bs=1M count="${TOTAL_SIZE}" status=progress

    # Create partition table
    # Partition layout:
    #   1: Boot (FAT32, 256MB)
    #   2: Root A (ext4, 512MB)
    #   3: Root B (ext4, 512MB)
    #   4: Data (ext4, remaining)

    log "Creating partitions..."
    parted -s "${image_file}" mklabel msdos
    parted -s "${image_file}" mkpart primary fat32 1MiB $((BOOT_SIZE + 1))MiB
    parted -s "${image_file}" mkpart primary ext4 $((BOOT_SIZE + 1))MiB $((BOOT_SIZE + ROOT_SIZE + 1))MiB
    parted -s "${image_file}" mkpart primary ext4 $((BOOT_SIZE + ROOT_SIZE + 1))MiB $((BOOT_SIZE + ROOT_SIZE * 2 + 1))MiB
    parted -s "${image_file}" mkpart primary ext4 $((BOOT_SIZE + ROOT_SIZE * 2 + 1))MiB 100%
    parted -s "${image_file}" set 1 boot on

    echo "${image_file}"
}

# Setup loop device and mount
setup_loop() {
    local image_file="$1"

    log "Setting up loop device..."

    LOOP_DEV=$(losetup -f --show -P "${image_file}")
    log "Loop device: ${LOOP_DEV}"

    # Format partitions
    log "Formatting partitions..."
    mkfs.vfat -F 32 -n BOOT "${LOOP_DEV}p1"
    mkfs.ext4 -L palpable-root-A "${LOOP_DEV}p2"
    mkfs.ext4 -L palpable-root-B "${LOOP_DEV}p3"
    mkfs.ext4 -L palpable-data "${LOOP_DEV}p4"

    # Mount
    mkdir -p "${OUTPUT_DIR}/mnt"/{boot,rootA,rootB,data}
    mount "${LOOP_DEV}p1" "${OUTPUT_DIR}/mnt/boot"
    mount "${LOOP_DEV}p2" "${OUTPUT_DIR}/mnt/rootA"
    mount "${LOOP_DEV}p3" "${OUTPUT_DIR}/mnt/rootB"
    mount "${LOOP_DEV}p4" "${OUTPUT_DIR}/mnt/data"
}

# Install Alpine to root partition
install_alpine() {
    local rootfs_tar="$1"
    local root_mount="$2"

    log "Installing Alpine to ${root_mount}..."

    tar -xzf "${rootfs_tar}" -C "${root_mount}"

    # Apply overlay
    if [ -d "./rootfs-overlay" ]; then
        log "Applying rootfs overlay..."
        rsync -av ./rootfs-overlay/ "${root_mount}/"
    fi
}

# Configure Alpine system
configure_system() {
    local root_mount="$1"
    local boot_mount="$2"

    log "Configuring system..."

    # Create /etc/fstab
    cat > "${root_mount}/etc/fstab" << 'EOF'
# Palpable OS Filesystem Table
# <device>     <mount>   <type>  <options>                           <dump> <pass>
/dev/mmcblk0p1 /boot     vfat    defaults,ro                         0      2
/dev/mmcblk0p4 /data     ext4    defaults,noatime                    0      2
tmpfs          /tmp      tmpfs   defaults,nosuid,nodev,size=64m      0      0
tmpfs          /var/log  tmpfs   defaults,nosuid,nodev,size=32m      0      0
EOF

    # Create /etc/hostname
    echo "palpable" > "${root_mount}/etc/hostname"

    # Create /etc/hosts
    cat > "${root_mount}/etc/hosts" << 'EOF'
127.0.0.1   localhost
127.0.1.1   palpable
::1         localhost
EOF

    # Setup APK repositories
    cat > "${root_mount}/etc/apk/repositories" << EOF
${ALPINE_MIRROR}/v${ALPINE_VERSION}/main
${ALPINE_MIRROR}/v${ALPINE_VERSION}/community
EOF

    # Create palpable service
    cat > "${root_mount}/etc/init.d/palpable" << 'EOF'
#!/sbin/openrc-run

name="palpable"
description="Palpable IoT Agent"
command="/usr/bin/palpable-agent"
command_args=""
command_user="palpable"
pidfile="/run/palpable.pid"
output_log="/var/log/palpable.log"
error_log="/var/log/palpable.log"

depend() {
    need net
    after firewall
}

start_pre() {
    # Confirm boot success after 60 seconds of uptime
    (sleep 60 && /usr/bin/ab-partition confirm) &
}
EOF
    chmod +x "${root_mount}/etc/init.d/palpable"

    # Create user for palpable agent
    cat >> "${root_mount}/etc/passwd" << 'EOF'
palpable:x:1000:1000:Palpable Agent:/data/palpable:/bin/false
EOF
    cat >> "${root_mount}/etc/group" << 'EOF'
palpable:x:1000:
i2c:x:997:palpable
gpio:x:998:palpable
spi:x:999:palpable
EOF

    # Create data directory structure
    mkdir -p "${root_mount}/data/palpable"/{config,cache,logs}

    # Setup boot partition
    log "Configuring boot partition..."

    # config.txt for Pi
    cat > "${boot_mount}/config.txt" << 'EOF'
# Palpable OS Configuration for Raspberry Pi Zero 2 W

# 64-bit mode
arm_64bit=1

# GPU memory (minimal for headless)
gpu_mem=16

# Enable I2C and SPI
dtparam=i2c_arm=on
dtparam=spi=on

# Enable hardware watchdog
dtparam=watchdog=on

# Disable HDMI (save power)
hdmi_blanking=2

# Disable audio (save power)
dtparam=audio=off

# WiFi region
dtoverlay=disable-wifi
# Uncomment for WiFi:
# dtparam=wifiregion=US

# Enable USB for debugging
enable_uart=1

# Boot from partition 2 (Root A) by default
[all]
# Will be overwritten by update system
EOF

    # cmdline.txt
    cat > "${boot_mount}/cmdline.txt" << 'EOF'
console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet init=/sbin/init
EOF

    # autoboot.txt for A/B switching
    cat > "${boot_mount}/autoboot.txt" << 'EOF'
[all]
boot_partition=2
EOF

    # Initial partition state
    cat > "${boot_mount}/palpable-partition-state.json" << 'EOF'
{
  "activeSlot": "A",
  "pendingSlot": null,
  "bootAttempts": 0,
  "maxBootAttempts": 3,
  "slots": {
    "A": {
      "version": "initial",
      "bootCount": 0,
      "lastBootSuccess": false,
      "updatedAt": null
    },
    "B": {
      "version": "",
      "bootCount": 0,
      "lastBootSuccess": false,
      "updatedAt": null
    }
  }
}
EOF
}

# Install packages via chroot
install_packages() {
    local root_mount="$1"

    log "Installing packages..."

    # Copy resolv.conf for network access in chroot
    cp /etc/resolv.conf "${root_mount}/etc/resolv.conf"

    # Mount proc/sys/dev for chroot
    mount -t proc /proc "${root_mount}/proc"
    mount -t sysfs /sys "${root_mount}/sys"
    mount --bind /dev "${root_mount}/dev"

    # Install packages in chroot
    chroot "${root_mount}" /bin/sh << 'CHROOT_EOF'
# Update APK
apk update

# Install essential packages
apk add --no-cache \
    openrc \
    alpine-base \
    busybox-initscripts \
    wpa_supplicant \
    dhcpcd \
    openssh \
    jq \
    ca-certificates \
    curl \
    i2c-tools \
    raspberrypi-bootloader \
    linux-rpi

# Enable services
rc-update add networking boot
rc-update add hostname boot
rc-update add dhcpcd default
rc-update add wpa_supplicant default
rc-update add sshd default
rc-update add palpable default

# Set root password (will be changed on first boot)
echo "root:palpable" | chpasswd
CHROOT_EOF

    # Cleanup chroot mounts
    umount "${root_mount}/dev" || true
    umount "${root_mount}/sys" || true
    umount "${root_mount}/proc" || true
}

# Copy palpable agent binary
install_agent() {
    local root_mount="$1"
    local agent_binary=""

    # Look for agent binary in multiple locations
    for path in \
        "./cache/palpable-agent" \
        "../../palpable-agent-go/bin/palpable-agent-linux-arm64" \
        "/agent" \
    ; do
        if [ -f "${path}" ]; then
            agent_binary="${path}"
            break
        fi
    done

    if [ -n "${agent_binary}" ]; then
        log "Installing palpable-agent binary from ${agent_binary}..."
        cp "${agent_binary}" "${root_mount}/usr/bin/palpable-agent"
        chmod +x "${root_mount}/usr/bin/palpable-agent"
    else
        warn "Agent binary not found!"
        warn "Build with: make agent"
    fi

    # Copy A/B partition script
    local ab_script="../../palpable-runtime/update-client/ab-partition.sh"
    if [ -f "${ab_script}" ]; then
        cp "${ab_script}" "${root_mount}/usr/bin/ab-partition"
        chmod +x "${root_mount}/usr/bin/ab-partition"
    fi
}

# Cleanup and finalize
cleanup() {
    log "Cleaning up..."

    sync

    # Unmount in reverse order
    umount "${OUTPUT_DIR}/mnt/data" 2>/dev/null || true
    umount "${OUTPUT_DIR}/mnt/rootB" 2>/dev/null || true
    umount "${OUTPUT_DIR}/mnt/rootA" 2>/dev/null || true
    umount "${OUTPUT_DIR}/mnt/boot" 2>/dev/null || true

    # Detach loop device
    if [ -n "${LOOP_DEV}" ]; then
        losetup -d "${LOOP_DEV}" 2>/dev/null || true
    fi

    # Remove mount directories
    rm -rf "${OUTPUT_DIR}/mnt"
}

# Compress image
compress_image() {
    local image_file="$1"

    log "Compressing image..."
    xz -9 -T0 -k "${image_file}"

    log "Created: ${image_file}.xz"
}

# Main build process
main() {
    log "Building Palpable OS ${VERSION}"
    log "Alpine Linux ${ALPINE_VERSION} for ${PI_ARCH}"

    mkdir -p "${OUTPUT_DIR}"

    check_deps

    # Download Alpine
    ROOTFS_TAR=$(download_alpine)

    # Create image
    IMAGE_FILE=$(create_image)

    # Setup mounts
    trap cleanup EXIT
    setup_loop "${IMAGE_FILE}"

    # Install Alpine to both root partitions
    install_alpine "${ROOTFS_TAR}" "${OUTPUT_DIR}/mnt/rootA"
    install_alpine "${ROOTFS_TAR}" "${OUTPUT_DIR}/mnt/rootB"

    # Configure (primary slot A)
    configure_system "${OUTPUT_DIR}/mnt/rootA" "${OUTPUT_DIR}/mnt/boot"

    # Copy config to slot B as well
    cp "${OUTPUT_DIR}/mnt/rootA/etc/fstab" "${OUTPUT_DIR}/mnt/rootB/etc/fstab"
    # Adjust fstab for slot B
    sed -i 's|/dev/mmcblk0p2|/dev/mmcblk0p3|' "${OUTPUT_DIR}/mnt/rootB/etc/fstab"

    # Install packages
    install_packages "${OUTPUT_DIR}/mnt/rootA"

    # Install agent
    install_agent "${OUTPUT_DIR}/mnt/rootA"
    install_agent "${OUTPUT_DIR}/mnt/rootB"

    # Create version file
    echo "${VERSION}" > "${OUTPUT_DIR}/mnt/rootA/etc/palpable-release"
    echo "${VERSION}" > "${OUTPUT_DIR}/mnt/rootB/etc/palpable-release"

    # Cleanup
    cleanup
    trap - EXIT

    # Compress
    compress_image "${IMAGE_FILE}"

    # Generate checksums
    log "Generating checksums..."
    cd "${OUTPUT_DIR}"
    sha256sum "${IMAGE_NAME}-${VERSION}.img" > "${IMAGE_NAME}-${VERSION}.img.sha256"
    sha256sum "${IMAGE_NAME}-${VERSION}.img.xz" > "${IMAGE_NAME}-${VERSION}.img.xz.sha256"

    log "Build complete!"
    log "Image: ${OUTPUT_DIR}/${IMAGE_NAME}-${VERSION}.img.xz"
    log "Flash with: xzcat ${IMAGE_NAME}-${VERSION}.img.xz | sudo dd of=/dev/sdX bs=4M status=progress"
}

main "$@"
