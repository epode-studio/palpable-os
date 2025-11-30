# Palpable OS

**Smart Home Sensor Platform for Raspberry Pi**

Palpable OS is a lightweight operating system for Raspberry Pi devices, designed to power the [Palpable](https://palpable.technology) smart home sensor platform. It's based on [DietPi](https://dietpi.com), optimized for headless sensor operation.

## Features

- **Lightweight**: ~600MB image, minimal resource usage
- **Auto-Setup**: Connects to WiFi and cloud automatically on first boot
- **I2C Ready**: Pre-configured for Qwiic/I2C sensor modules
- **Cloud Connected**: Automatically syncs with your Palpable dashboard
- **Secure**: Minimal attack surface, automatic updates

## Supported Hardware

- Raspberry Pi Zero 2 W (recommended)
- Raspberry Pi 3/4/5
- Any Raspberry Pi with WiFi

## Quick Start

### Option 1: Download Pre-built Image

1. Download the latest release from [Releases](https://github.com/paultnylund/palpable-os/releases)
2. Flash to SD card using [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
3. Configure WiFi and device settings at [palpable.technology/devices/flash](https://palpable.technology/devices/flash)
4. Copy config files to the boot partition
5. Insert SD card and power on

### Option 2: Use the Web Configurator

1. Go to [palpable.technology/devices/flash](https://palpable.technology/devices/flash)
2. Enter your device name and WiFi credentials
3. Download and follow the setup instructions

## First Boot

On first boot, Palpable OS will:

1. Connect to your WiFi network
2. Install Node.js and dependencies
3. Download the Palpable sensor software
4. Start the Palpable service
5. Connect to the Palpable cloud

Your device will appear in your [Palpable Dashboard](https://palpable.technology/dashboard) within 5-10 minutes.

## Default Credentials

- **Username**: `root`
- **Password**: `palpable`

Please change the password after first login for security.

## Documentation

- [Palpable Documentation](https://palpable.technology/docs)
- [DietPi Documentation](https://dietpi.com/docs/)
- [Hardware Setup Guide](https://palpable.technology/docs/hardware)

## Building from Source

This repository is a fork of [DietPi](https://github.com/MichaIng/DietPi). To build your own image:

```bash
# Clone the repository
git clone https://github.com/paultnylund/palpable-os.git
cd palpable-os

# Build using GitHub Actions (push a tag)
git tag v1.0.0
git push origin v1.0.0
```

Or manually:

```bash
# Download DietPi base image
wget https://dietpi.com/downloads/images/DietPi_RPi-ARMv8-Bookworm.img.xz
xz -d DietPi_RPi-ARMv8-Bookworm.img.xz

# Mount, customize, and compress
# (See .github/workflows/build-image.yml for details)
```

## License

Palpable OS is based on DietPi and is licensed under the [GNU General Public License v2.0](LICENSE).

## Credits

- [DietPi](https://dietpi.com) - The base operating system
- [Raspberry Pi Foundation](https://www.raspberrypi.org) - Hardware platform
- [SparkFun](https://www.sparkfun.com) - Qwiic sensor ecosystem

## Support

- [Palpable Support](https://palpable.technology/support)
- [GitHub Issues](https://github.com/paultnylund/palpable-os/issues)
