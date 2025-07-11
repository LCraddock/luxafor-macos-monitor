#!/usr/bin/env bash
#
# setup-launch-agent.sh
# Install/uninstall the Luxafor notify launch agent
#

PLIST_NAME="com.luxafor.notify"
PLIST_FILE="$PWD/$PLIST_NAME.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
INSTALLED_PLIST="$LAUNCH_AGENTS_DIR/$PLIST_NAME.plist"

install() {
    echo "Installing Luxafor notify launch agent..."
    
    # Create LaunchAgents directory if it doesn't exist
    mkdir -p "$LAUNCH_AGENTS_DIR"
    
    # Copy plist file
    cp "$PLIST_FILE" "$INSTALLED_PLIST"
    
    # Load the agent
    launchctl load "$INSTALLED_PLIST"
    
    echo "Installed and started!"
    echo ""
    echo "The service will now:"
    echo "• Start automatically when you log in"
    echo "• Restart if it crashes"
    echo "• Log output to: $PWD/luxafor-notify.log"
}

uninstall() {
    echo "Uninstalling Luxafor notify launch agent..."
    
    if [ -f "$INSTALLED_PLIST" ]; then
        # Unload the agent
        launchctl unload "$INSTALLED_PLIST" 2>/dev/null
        
        # Remove the plist
        rm "$INSTALLED_PLIST"
        
        echo "Uninstalled!"
    else
        echo "Launch agent not installed"
    fi
}

case "$1" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        echo ""
        echo "Commands:"
        echo "  install   - Install as a launch agent (auto-start on login)"
        echo "  uninstall - Remove the launch agent"
        exit 1
        ;;
esac