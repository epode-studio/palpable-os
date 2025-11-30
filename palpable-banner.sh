#!/bin/bash
# Palpable OS Boot Banner
# Replaces DietPi banner with Palpable branding

cat << 'EOF'

  ██████╗  █████╗ ██╗     ██████╗  █████╗ ██████╗ ██╗     ███████╗
  ██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██╔══██╗██║     ██╔════╝
  ██████╔╝███████║██║     ██████╔╝███████║██████╔╝██║     █████╗
  ██╔═══╝ ██╔══██║██║     ██╔═══╝ ██╔══██║██╔══██╗██║     ██╔══╝
  ██║     ██║  ██║███████╗██║     ██║  ██║██████╔╝███████╗███████╗
  ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝
                                                            OS

  Smart Home Sensor Platform | palpable.technology
  Based on DietPi (GPLv2) | dietpi.com

EOF

# Show device info if available
if [ -f /opt/palpable/config/device.json ]; then
    DEVICE_ID=$(grep -o '"deviceId"[[:space:]]*:[[:space:]]*"[^"]*"' /opt/palpable/config/device.json | cut -d'"' -f4)
    DEVICE_NAME=$(grep -o '"deviceName"[[:space:]]*:[[:space:]]*"[^"]*"' /opt/palpable/config/device.json | cut -d'"' -f4)
    echo "  Device: $DEVICE_NAME"
    echo "  ID: $DEVICE_ID"
    echo ""
fi

# Show network info
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -n "$IP" ]; then
    echo "  IP Address: $IP"
fi

# Show service status
if systemctl is-active --quiet palpable 2>/dev/null; then
    echo "  Palpable Service: Running"
else
    echo "  Palpable Service: Not running"
fi

echo ""
