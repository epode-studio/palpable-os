# Palpable OS

Minimal Alpine Linux-based operating system for Raspberry Pi Zero 2 W.

## Features

- **Minimal Footprint** - ~50MB compressed image
- **A/B Partitions** - Atomic updates with automatic rollback
- **Read-only Root** - Reliable operation, survives power loss
- **WiFi Provisioning** - Captive portal for initial setup
- **Go Agent** - Single binary, no runtime dependencies

## Quick Start

### Download

Get the latest image from [Releases](https://github.com/epode-studio/palpable-os/releases).

### Flash

```bash
# Decompress and flash to SD card
xzcat palpable-os-*.img.xz | sudo dd of=/dev/sdX bs=4M status=progress
sync
```

### First Boot

1. Insert SD card in Raspberry Pi Zero 2 W
2. Power on and wait ~30 seconds
3. Connect to `Palpable-XXXX` WiFi network
4. Visit http://192.168.4.1 to configure

## Building

### On Linux

```bash
# Build Go agent + OS image
make build
```

### On macOS (via Docker)

```bash
make docker-build
```

## Partition Layout

| Partition | Mount | Size | Purpose |
|-----------|-------|------|---------|
| mmcblk0p1 | /boot | 256MB | Boot (FAT32, shared) |
| mmcblk0p2 | / | 512MB | Root A (ext4) |
| mmcblk0p3 | - | 512MB | Root B (ext4) |
| mmcblk0p4 | /data | remaining | Persistent data |

## OTA Updates

The agent receives updates via WebSocket from the cloud:

1. Download to inactive root partition (A or B)
2. Verify ECDSA signature
3. Set boot flag for new partition
4. Reboot
5. If boot fails 3x → automatic rollback

## Related Repositories

- [palpable](https://github.com/epode-studio/palpable) - Main monorepo (web app, runtime, agent)
- [palpable-bootstrap](https://github.com/epode-studio/palpable-bootstrap) - Initramfs bootstrapper

## License

GPLv2 - Same as Alpine Linux and Linux kernel.
