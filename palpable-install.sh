#!/bin/bash
#--------------------------------------
# Palpable OS Installation Script
# Runs automatically on first boot after DietPi setup
#--------------------------------------

set -e

PALPABLE_VERSION="1.0.0"
PALPABLE_DIR="/opt/palpable"
PALPABLE_REPO="https://github.com/paultnylund/palpable"
LOG_FILE="/var/log/palpable-install.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Banner
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║              PALPABLE OS INSTALLER v${PALPABLE_VERSION}               ║"
echo "║           Smart Home Sensor Platform                       ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log "Starting Palpable OS installation..."

#--------------------------------------
# Step 1: Enable I2C Interface
#--------------------------------------
log "[1/6] Enabling I2C interface..."

# Use DietPi's hardware config if available
if [ -f /boot/dietpi/func/dietpi-set_hardware ]; then
    /boot/dietpi/func/dietpi-set_hardware i2c enable
else
    # Fallback: manual I2C enable
    if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
        echo "dtparam=i2c_arm=on" >> /boot/config.txt
    fi
    if ! grep -q "^i2c-dev" /etc/modules; then
        echo "i2c-dev" >> /etc/modules
    fi
    modprobe i2c-dev 2>/dev/null || true
fi

log "I2C enabled"

#--------------------------------------
# Step 2: Install I2C Tools
#--------------------------------------
log "[2/6] Installing I2C tools..."

apt-get update -qq
apt-get install -y -qq i2c-tools

log "I2C tools installed"

#--------------------------------------
# Step 3: Create Palpable Directories
#--------------------------------------
log "[3/6] Creating Palpable directories..."

mkdir -p "$PALPABLE_DIR"
mkdir -p "$PALPABLE_DIR/config"
mkdir -p "$PALPABLE_DIR/data"
mkdir -p "$PALPABLE_DIR/logs"
mkdir -p "$PALPABLE_DIR/drivers"

log "Directories created at $PALPABLE_DIR"

#--------------------------------------
# Step 4: Download Palpable OS Software
#--------------------------------------
log "[4/6] Downloading Palpable OS software..."

cd "$PALPABLE_DIR"

# Download from GitHub release or main branch
if curl -fsSL "${PALPABLE_REPO}/releases/latest/download/palpable-os.tar.gz" -o palpable-os.tar.gz 2>/dev/null; then
    tar xzf palpable-os.tar.gz --strip-components=1
    rm palpable-os.tar.gz
else
    # Fallback: clone from main branch
    log "No release found, downloading from main branch..."
    curl -fsSL "${PALPABLE_REPO}/archive/refs/heads/main.tar.gz" | tar xz --strip-components=2 palpable-main/palpable-os
fi

# Install dependencies
log "Installing Node.js dependencies..."
npm install --production --silent

log "Palpable software installed"

#--------------------------------------
# Step 5: Copy Device Configuration
#--------------------------------------
log "[5/6] Configuring device..."

# Copy device config from boot partition if present
if [ -f /boot/palpable-device.json ]; then
    cp /boot/palpable-device.json "$PALPABLE_DIR/config/device.json"
    log "Device configuration copied from boot partition"

    # Extract device info for logging
    DEVICE_ID=$(grep -o '"deviceId"[[:space:]]*:[[:space:]]*"[^"]*"' "$PALPABLE_DIR/config/device.json" | cut -d'"' -f4)
    DEVICE_NAME=$(grep -o '"deviceName"[[:space:]]*:[[:space:]]*"[^"]*"' "$PALPABLE_DIR/config/device.json" | cut -d'"' -f4)
    log "Device ID: $DEVICE_ID"
    log "Device Name: $DEVICE_NAME"
else
    log "WARNING: No device configuration found at /boot/palpable-device.json"
    log "Device will need to be configured manually"
fi

#--------------------------------------
# Step 6: Create and Enable Systemd Service
#--------------------------------------
log "[6/6] Creating systemd service..."

cat > /etc/systemd/system/palpable.service << 'SERVICEEOF'
[Unit]
Description=Palpable OS - Smart Home Sensor Platform
Documentation=https://palpable.technology/docs
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/palpable
ExecStart=/usr/bin/node main.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PALPABLE_PARTITION=A

# Logging
StandardOutput=append:/opt/palpable/logs/palpable.log
StandardError=append:/opt/palpable/logs/palpable.log

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/palpable

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable palpable
systemctl start palpable

log "Palpable service created and started"

#--------------------------------------
# Install Palpable Banner
#--------------------------------------
if [ -f /boot/palpable-banner.sh ]; then
    cp /boot/palpable-banner.sh /opt/palpable/banner.sh
    chmod +x /opt/palpable/banner.sh

    # Add to profile for login display
    if ! grep -q "palpable/banner.sh" /etc/profile; then
        echo "/opt/palpable/banner.sh" >> /etc/profile
    fi
fi

#--------------------------------------
# Cleanup
#--------------------------------------
log "Cleaning up installation files..."

# Remove install script from boot (one-time run)
rm -f /boot/palpable-install.sh

# Clear apt cache
apt-get clean -qq

#--------------------------------------
# Complete!
#--------------------------------------
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║         PALPABLE OS INSTALLATION COMPLETE!                 ║"
echo "║                                                            ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║                                                            ║"
if [ -n "$DEVICE_ID" ]; then
echo "║  Device ID: $DEVICE_ID                    ║"
echo "║  Device Name: $DEVICE_NAME                                 ║"
fi
echo "║                                                            ║"
echo "║  Service Status: $(systemctl is-active palpable)                              ║"
echo "║  Logs: /opt/palpable/logs/palpable.log                     ║"
echo "║                                                            ║"
echo "║  Your device should now appear in the Palpable app!        ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log "Installation complete!"
