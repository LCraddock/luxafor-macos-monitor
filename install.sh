#!/usr/bin/env bash
#
# Luxafor Notification Monitor - Installer
#

set -e  # Exit on error

INSTALL_DIR="$HOME/.luxafor-monitor"
SWIFTBAR_PLUGIN_DIR="$HOME/Documents/SwiftBarPlugins"

echo "==================================="
echo "Luxafor Notification Monitor Setup"
echo "==================================="
echo

# Check dependencies
echo "Checking dependencies..."

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install from https://brew.sh"
    exit 1
fi

# Check for SwiftBar
if ! brew list swiftbar &> /dev/null; then
    echo "📦 Installing SwiftBar..."
    brew install --cask swiftbar
else
    echo "✅ SwiftBar already installed"
fi

# Check for luxafor-cli dependencies
if ! brew list hidapi &> /dev/null; then
    echo "📦 Installing hidapi..."
    brew install hidapi
else
    echo "✅ hidapi already installed"
fi

if ! brew list cmake &> /dev/null; then
    echo "📦 Installing cmake..."
    brew install cmake
else
    echo "✅ cmake already installed"
fi

# Create installation directory
echo
echo "Creating installation directory..."
mkdir -p "$INSTALL_DIR"

# Copy scripts
echo "Installing scripts..."
cp luxafor-notify.sh "$INSTALL_DIR/"
cp luxafor-control.sh "$INSTALL_DIR/"
cp luxafor-test.sh "$INSTALL_DIR/"
cp luxafor-quick-test.sh "$INSTALL_DIR/"
cp com.luxafor.notify.plist "$INSTALL_DIR/"
cp setup-launch-agent.sh "$INSTALL_DIR/"

# Make scripts executable
chmod +x "$INSTALL_DIR"/*.sh

# Copy config file (don't overwrite if exists)
if [ ! -f "$INSTALL_DIR/luxafor-config.conf" ]; then
    echo "Installing default configuration..."
    cp luxafor-config.conf "$INSTALL_DIR/"
else
    echo "⚠️  Keeping existing configuration file"
fi

# Build luxafor-cli (enhanced version)
echo
echo "Building luxafor-cli (enhanced version)..."
if [ ! -d "$INSTALL_DIR/luxafor-cli" ]; then
    git clone --recurse-submodules https://github.com/LCraddock/luxafor-cli.git "$INSTALL_DIR/luxafor-cli"
fi

cd "$INSTALL_DIR/luxafor-cli"
mkdir -p build
cd build
cmake ..
cmake --build .
cd "$INSTALL_DIR"

# Update paths in scripts
echo "Updating script paths..."
sed -i '' "s|/Users/larry.craddock/Projects/luxafor-cli/build/luxafor|$INSTALL_DIR/luxafor-cli/build/luxafor|g" "$INSTALL_DIR"/*.sh
sed -i '' "s|/Users/larry.craddock/Projects/luxafor|$INSTALL_DIR|g" "$INSTALL_DIR"/*.sh "$INSTALL_DIR"/*.plist

# Install SwiftBar plugin
echo "Installing SwiftBar plugin..."
mkdir -p "$SWIFTBAR_PLUGIN_DIR"
cp luxafor-toggle.1s.sh "$SWIFTBAR_PLUGIN_DIR/"
chmod +x "$SWIFTBAR_PLUGIN_DIR/luxafor-toggle.1s.sh"

# Update SwiftBar plugin paths
sed -i '' "s|/Users/larry.craddock/Projects/luxafor|$INSTALL_DIR|g" "$SWIFTBAR_PLUGIN_DIR/luxafor-toggle.1s.sh"

# Install launch agent
echo
echo "Installing launch agent..."
cd "$INSTALL_DIR"
./setup-launch-agent.sh install

echo
echo "==================================="
echo "✅ Installation Complete!"
echo "==================================="
echo
echo "The Luxafor monitor is now running and will start automatically on login."
echo
echo "SwiftBar menu bar icon:"
echo "- 🟢 = Running, 🔴 = Stopped"
echo "- Click to see notification counts and controls"
echo
echo "Configuration file: $INSTALL_DIR/luxafor-config.conf"
echo "To modify app monitoring, edit the config and restart via the menu bar."
echo
echo "Enjoy your Luxafor notification system!"