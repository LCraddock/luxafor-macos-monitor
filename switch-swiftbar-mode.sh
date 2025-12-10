#!/usr/bin/env bash
#
# switch-swiftbar-mode.sh
# Switch between high-CPU (direct) and low-CPU (daemon) SwiftBar modes
#

SWIFTBAR_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$1" in
    daemon|low-cpu)
        echo "Switching to low-CPU daemon mode..."
        
        # Disable the old 1s script
        if [ -f "$SWIFTBAR_DIR/luxafor-toggle.1s.sh" ]; then
            mv "$SWIFTBAR_DIR/luxafor-toggle.1s.sh" "$SWIFTBAR_DIR/luxafor-toggle.1s.sh.disabled"
            echo "Disabled: luxafor-toggle.1s.sh"
        fi
        
        # Enable the new 5s script
        if [ ! -L "$SWIFTBAR_DIR/luxafor-toggle.5s.sh" ]; then
            ln -sf "$SCRIPT_DIR/luxafor-toggle.5s.sh" "$SWIFTBAR_DIR/luxafor-toggle.5s.sh"
            echo "Enabled: luxafor-toggle.5s.sh (daemon mode)"
        fi
        
        # Make sure daemon is running
        "$SCRIPT_DIR/luxafor-control.sh" start
        
        echo ""
        echo "✅ Switched to low-CPU daemon mode"
        echo "   - Menu updates every 5 seconds"
        echo "   - Notifications checked every 1 second"
        echo "   - CPU usage: <1%"
        ;;
        
    direct|high-cpu)
        echo "Switching to direct mode (original)..."
        
        # Disable the new 5s script
        if [ -L "$SWIFTBAR_DIR/luxafor-toggle.5s.sh" ]; then
            rm "$SWIFTBAR_DIR/luxafor-toggle.5s.sh"
            echo "Disabled: luxafor-toggle.5s.sh"
        fi
        
        # Enable the old 1s script
        if [ -f "$SWIFTBAR_DIR/luxafor-toggle.1s.sh.disabled" ]; then
            mv "$SWIFTBAR_DIR/luxafor-toggle.1s.sh.disabled" "$SWIFTBAR_DIR/luxafor-toggle.1s.sh"
            echo "Enabled: luxafor-toggle.1s.sh (direct mode)"
        fi
        
        # Stop the daemon
        "$SCRIPT_DIR/luxafor-control.sh" stop
        sleep 1
        "$SCRIPT_DIR/luxafor-control.sh" start
        
        echo ""
        echo "✅ Switched to direct mode"
        echo "   - Menu updates every 1 second"
        echo "   - CPU usage: ~70%"
        ;;
        
    status)
        echo "=== SwiftBar Mode Status ==="
        
        if [ -f "$SWIFTBAR_DIR/luxafor-toggle.1s.sh" ]; then
            echo "Mode: Direct (high-CPU)"
            echo "Active script: luxafor-toggle.1s.sh"
        elif [ -L "$SWIFTBAR_DIR/luxafor-toggle.5s.sh" ]; then
            echo "Mode: Daemon (low-CPU)"
            echo "Active script: luxafor-toggle.5s.sh"
        else
            echo "Mode: Not configured"
        fi
        
        echo ""
        "$SCRIPT_DIR/luxafor-control.sh" status
        ;;
        
    *)
        echo "Usage: $0 {daemon|direct|status}"
        echo ""
        echo "Modes:"
        echo "  daemon  - Low-CPU mode using background daemon (~1% CPU)"
        echo "  direct  - Original direct mode (~70% CPU)"
        echo "  status  - Show current mode and service status"
        echo ""
        echo "Aliases:"
        echo "  low-cpu  = daemon"
        echo "  high-cpu = direct"
        exit 1
        ;;
esac