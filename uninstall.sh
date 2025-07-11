#!/usr/bin/env bash
#
# Luxafor Notification Monitor - Uninstaller
#

INSTALL_DIR="$HOME/.luxafor-monitor"
SWIFTBAR_PLUGIN_DIR="$HOME/Documents/SwiftBarPlugins"

echo "==================================="
echo "Luxafor Monitor Uninstaller"
echo "==================================="
echo

# Stop and unload launch agent
echo "Stopping monitor service..."
if [ -f "$INSTALL_DIR/setup-launch-agent.sh" ]; then
    cd "$INSTALL_DIR"
    ./setup-launch-agent.sh uninstall
fi

# Turn off LED
echo "Turning off Luxafor..."
if [ -f "$INSTALL_DIR/luxafor-cli/build/luxafor" ]; then
    "$INSTALL_DIR/luxafor-cli/build/luxafor" off 2>/dev/null || true
fi

# Remove SwiftBar plugin
echo "Removing SwiftBar plugin..."
rm -f "$SWIFTBAR_PLUGIN_DIR/luxafor-toggle.1s.sh"

# Ask about config
echo
read -p "Remove configuration file? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$INSTALL_DIR"
    echo "✅ All files removed"
else
    # Remove everything except config
    find "$INSTALL_DIR" -type f ! -name "luxafor-config.conf" -delete
    find "$INSTALL_DIR" -type d -empty -delete
    echo "✅ Removed all files except configuration"
    echo "   Config saved at: $INSTALL_DIR/luxafor-config.conf"
fi

echo
echo "Uninstall complete!"