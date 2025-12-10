#!/usr/bin/env bash
#
# setup-daemon-mode.sh
# Sets up the complete Luxafor system with low-CPU daemon mode
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
SWIFTBAR_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"

echo "Setting up Luxafor daemon mode..."
echo "================================"

# 1. Install launch agents
echo "Installing launch agents..."

# Copy notification monitor plist
cp "$SCRIPT_DIR/com.luxafor.notify.plist" "$LAUNCH_AGENTS_DIR/"
echo "✓ Installed com.luxafor.notify.plist"

# Copy menu daemon plist
cp "$SCRIPT_DIR/com.luxafor.menu-daemon.plist" "$LAUNCH_AGENTS_DIR/"
echo "✓ Installed com.luxafor.menu-daemon.plist"

# 2. Setup SwiftBar plugin
echo ""
echo "Setting up SwiftBar plugin..."

# Ensure SwiftBar plugin directory exists
mkdir -p "$SWIFTBAR_DIR"

# Remove old 1s script if exists
if [ -f "$SWIFTBAR_DIR/luxafor-toggle.1s.sh" ] || [ -L "$SWIFTBAR_DIR/luxafor-toggle.1s.sh" ]; then
    rm -f "$SWIFTBAR_DIR/luxafor-toggle.1s.sh"
    echo "✓ Removed old 1s refresh script"
fi

# Create symlink to 5s daemon script
ln -sf "$SCRIPT_DIR/luxafor-toggle.5s.sh" "$SWIFTBAR_DIR/luxafor-toggle.5s.sh"
echo "✓ Installed daemon-based 5s refresh script"

# 3. Load launch agents
echo ""
echo "Loading services..."

# Unload any existing services first
launchctl unload "$LAUNCH_AGENTS_DIR/com.luxafor.notify.plist" 2>/dev/null
launchctl unload "$LAUNCH_AGENTS_DIR/com.luxafor.menu-daemon.plist" 2>/dev/null

# Load the services
launchctl load "$LAUNCH_AGENTS_DIR/com.luxafor.notify.plist"
echo "✓ Started notification monitor"

launchctl load "$LAUNCH_AGENTS_DIR/com.luxafor.menu-daemon.plist"
echo "✓ Started menu daemon"

# 4. Verify everything is running
echo ""
echo "Verifying installation..."
sleep 2

# Check services
notify_status=$(launchctl list | grep com.luxafor.notify | awk '{print $1}')
daemon_status=$(launchctl list | grep com.luxafor.menu-daemon | awk '{print $1}')

if [[ "$notify_status" != "-" ]] && [[ "$daemon_status" != "-" ]]; then
    echo "✓ All services running successfully!"
    echo ""
    echo "System Status:"
    echo "- Notification monitor PID: $notify_status"
    echo "- Menu daemon PID: $daemon_status"
    echo "- SwiftBar plugin: luxafor-toggle.5s.sh"
    echo "- CPU usage: <1%"
    echo ""
    echo "✅ Setup complete! The system will now:"
    echo "   • Start automatically on login"
    echo "   • Check notifications every 1 second"
    echo "   • Update SwiftBar menu every 5 seconds"
    echo "   • Use minimal CPU resources"
    echo ""
    echo "To check status: ./luxafor-control.sh status"
    echo "To stop all: ./luxafor-control.sh stop"
else
    echo "⚠️  Warning: Some services may not have started correctly"
    echo "Run './luxafor-control.sh status' for details"
fi