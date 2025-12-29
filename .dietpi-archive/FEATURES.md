# Palpable OS Features

**Version**: 1.0+
**Based on**: DietPi (Debian Bookworm)
**Target Hardware**: Raspberry Pi 2/3/4/5, Zero 2 W

## Overview

Palpable OS is a specialized Linux distribution optimized for IoT sensor applications. Built on DietPi's minimal footprint, it provides everything needed to run Palpable smart home sensors while maintaining excellent performance and security.

## Core Features

### Lightweight & Optimized
- **Minimal Footprint**: ~600MB compressed image, ~2GB installed
- **Low RAM Usage**: Runs comfortably on 512MB RAM devices
- **Fast Boot**: Optimized boot sequence for quick startup
- **Efficient Storage**: Automatic filesystem resizing on first boot

### Auto-Configuration
- **Zero-Touch Setup**: Automatically configures from boot partition files
- **WiFi Auto-Connect**: Reads wifi configuration and connects on boot
- **Cloud Registration**: Auto-registers with Palpable cloud
- **Service Auto-Start**: Palpable service starts automatically after configuration

### I2C & Sensor Support
- **I2C Pre-Enabled**: I2C interface enabled by default
- **Qwiic Compatible**: Works with SparkFun Qwiic ecosystem
- **i2c-tools Included**: Command-line tools for sensor debugging
- **Multiple Sensors**: Supports multiple I2C sensors simultaneously

### Network & Connectivity
- **WiFi Priority**: Automatic WiFi configuration and connection
- **mDNS/Avahi**: Device discovery via `palpable-XXXXX.local`
- **SSH Access**: Secure remote access enabled by default
- **Auto-Updates**: Automatic security and software updates

### Security
- **Minimal Attack Surface**: Only essential services enabled
- **Firewall Ready**: iptables pre-installed
- **Secure Defaults**: Strong default configurations
- **Regular Updates**: Security patches via DietPi update system

### Developer Friendly
- **Node.js**: Latest LTS version pre-installed
- **npm/yarn**: Package managers included
- **Git**: Version control tools available
- **systemd**: Modern service management

## Hardware Support

### Raspberry Pi Models
- **Pi Zero 2 W** ✅ (Recommended for sensors)
- **Pi 3 Model B/B+** ✅
- **Pi 4 Model B** ✅
- **Pi 5** ✅
- **Pi 2 Model B** ✅ (ARMv7 variant)

### Connectivity
- WiFi (2.4GHz)
- Ethernet (on supported models)
- Bluetooth (available but not required)

### Interfaces
- I2C (primary sensor interface)
- SPI (available)
- GPIO (available)
- UART/Serial (available)

## Pre-Installed Software

### System
- Debian Bookworm base
- Linux kernel 6.6+ (Raspberry Pi optimized)
- systemd init system
- Bash shell

### Networking
- NetworkManager (WiFi management)
- Avahi (mDNS/Bonjour)
- curl, wget (HTTP clients)
- OpenSSH server

### Development
- Node.js 20 LTS
- npm & yarn
- Git
- Python 3 (available via DietPi-Software)

### Hardware Tools
- i2c-tools (I2C bus utilities)
- Raspberry Pi utilities (raspi-gpio, etc.)
- Device Tree tools

### Palpable Specific
- Palpable sensor service
- Auto-configuration scripts
- Cloud sync daemon
- Custom boot banner

## Configuration System

### Boot Partition Config
Palpable OS reads configuration from the boot partition (`/boot/` or mounted as FAT partition on SD card):

```
/boot/
├── wifi.conf              # WiFi credentials
├── palpable-device.json   # Device configuration
└── dietpi.txt             # System configuration (optional)
```

### WiFi Configuration
Simple WiFi setup via `wifi.conf`:
```ini
SSID=YourNetworkName
PASSWORD=YourPassword
COUNTRY=US
```

### Device Configuration
Palpable settings in `palpable-device.json`:
```json
{
  "deviceId": "auto-generated",
  "deviceName": "Kitchen Sensor",
  "userId": "your-user-id",
  "apiKey": "your-api-key"
}
```

## First Boot Process

1. **Hardware Detection** (5-10 seconds)
   - Detect Raspberry Pi model
   - Initialize I2C interface
   - Configure GPIO

2. **Network Connection** (10-30 seconds)
   - Read WiFi credentials
   - Connect to wireless network
   - Obtain IP address via DHCP

3. **Software Installation** (2-5 minutes)
   - Install Node.js and dependencies
   - Download Palpable sensor software
   - Configure systemd services

4. **Cloud Registration** (10-20 seconds)
   - Register device with Palpable cloud
   - Download sensor configuration
   - Start data collection

5. **Ready** (Total: 3-6 minutes)
   - Palpable service running
   - Collecting sensor data
   - Visible in dashboard

## Performance Characteristics

### Resource Usage (Idle)
- **RAM**: ~150MB
- **CPU**: <5%
- **Storage**: ~2GB
- **Network**: Minimal (heartbeat only)

### Resource Usage (Active Sensing)
- **RAM**: ~200-300MB
- **CPU**: 5-15% (depending on sensors)
- **Storage**: Grows slowly with logs
- **Network**: 1-10 KB/s (data uploads)

### Power Consumption
- **Pi Zero 2 W**: ~150-200mA @ 5V
- **Pi 3/4**: ~300-500mA @ 5V
- **Pi 5**: ~600-800mA @ 5V

## Update & Maintenance

### Automatic Updates
- **Security patches**: Applied automatically
- **Palpable software**: Auto-updated from cloud
- **System updates**: Via `dietpi-update` (manual)

### Manual Updates
```bash
# Update system packages
dietpi-update

# Update Palpable software
systemctl restart palpable

# Check for new OS version
# (Reflash SD card with new release)
```

### Backup & Recovery
- **Configuration**: Backup `/boot/` partition files
- **Full backup**: Image entire SD card
- **Factory reset**: Reflash SD card

## Customization

### Installing Additional Software
```bash
# Use DietPi-Software
dietpi-software

# Or use apt directly
apt update
apt install package-name
```

### Adding Custom Services
```bash
# Create systemd service file
nano /etc/systemd/system/myservice.service

# Enable and start
systemctl enable myservice
systemctl start myservice
```

### Modifying Palpable Behavior
Configuration in `/opt/palpable/config/`:
- `device.json` - Device settings
- `sensors.json` - Sensor configuration
- `network.json` - Network settings

## Troubleshooting

### Common Issues

**WiFi Not Connecting**
- Check wifi.conf format
- Verify SSID and password
- Ensure 2.4GHz network (5GHz not supported on Pi Zero W)

**Palpable Service Not Starting**
```bash
systemctl status palpable
journalctl -u palpable -f
```

**Sensors Not Detected**
```bash
# Scan I2C bus
i2cdetect -y 1

# Check I2C is enabled
raspi-config
```

**Out of Space**
```bash
# Clean package cache
apt clean

# Remove old logs
journalctl --vacuum-time=7d
```

## Differences from Standard DietPi

Palpable OS includes these modifications to DietPi:

1. **Pre-installed Software**
   - Node.js LTS
   - i2c-tools
   - Palpable service

2. **Configuration**
   - I2C enabled by default
   - Custom boot banner
   - Palpable auto-start scripts

3. **Services**
   - Palpable cloud sync daemon
   - Auto-configuration on first boot
   - Custom WiFi setup

4. **Branding**
   - Palpable logos and banners
   - Custom /etc/issue and /etc/motd
   - Palpable documentation links

## License & Credits

### License
Palpable OS is licensed under **GNU General Public License v2.0**, inherited from DietPi.

### Based On
- **DietPi** - Minimal Debian-based OS ([dietpi.com](https://dietpi.com))
- **Debian** - Universal operating system ([debian.org](https://www.debian.org))
- **Raspberry Pi OS** - Kernel and drivers

### Credits
- DietPi team for the lightweight base system
- Raspberry Pi Foundation for hardware and drivers
- Debian project for the solid foundation
- SparkFun for Qwiic sensor ecosystem

## Support & Documentation

- **Palpable Docs**: https://palpable.technology/docs
- **Dashboard**: https://palpable.technology/dashboard
- **Support**: https://palpable.technology/support
- **GitHub**: https://github.com/epode-studio/palpable-os
- **DietPi Docs**: https://dietpi.com/docs/

## Version History

### v1.0.x (Current)
- Initial Palpable OS release
- Based on DietPi 9.x (Debian Bookworm)
- Raspberry Pi 2/3/4/5 support
- Auto-configuration system
- Cloud integration

Future releases will be documented in [CHANGELOG.txt](CHANGELOG.txt).
