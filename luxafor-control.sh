#!/usr/bin/env bash
#
# luxafor-control.sh
# Control script to easily start/stop/restart luxafor notifications
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NOTIFY_SCRIPT="$SCRIPT_DIR/luxafor-notify.sh"
PID_FILE="$SCRIPT_DIR/.luxafor-notify.pid"
DAEMON_SCRIPT="$SCRIPT_DIR/luxafor-menu-daemon.sh"
DAEMON_PID_FILE="/tmp/luxafor-menu-daemon.pid"
# No logging - runs silently

start() {
    echo "Starting Luxafor services..."
    
    # Start notification monitor
    NOTIFY_PLIST="$HOME/Library/LaunchAgents/com.luxafor.notify.plist"
    if [ -f "$NOTIFY_PLIST" ]; then
        # Kill any manually started processes first
        pkill -f "luxafor-notify.sh" 2>/dev/null || true
        
        # Load launch agent
        launchctl unload "$NOTIFY_PLIST" 2>/dev/null
        launchctl load "$NOTIFY_PLIST"
        
        # Get PID from launch agent
        sleep 1
        PID=$(launchctl list | grep "com.luxafor.notify" | awk '{print $1}')
        if [ "$PID" != "-" ]; then
            echo "✓ Notification monitor started (PID: $PID)"
            echo $PID > "$PID_FILE"
        fi
    else
        # Fallback to manual start
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if ps -p "$PID" > /dev/null 2>&1; then
                echo "Notification monitor already running (PID: $PID)"
            fi
        else
            echo "Starting notification monitor manually..."
            nohup "$NOTIFY_SCRIPT" > /dev/null 2>&1 &
            echo $! > "$PID_FILE"
            echo "✓ Started manually (PID: $(cat "$PID_FILE"))"
        fi
    fi
    
    # Start menu daemon
    start_daemon
}

start_daemon() {
    DAEMON_PLIST="$HOME/Library/LaunchAgents/com.luxafor.menu-daemon.plist"
    
    if [ -f "$DAEMON_PLIST" ]; then
        # Use launch agent
        pkill -f "luxafor-menu-daemon.sh" 2>/dev/null || true
        
        launchctl unload "$DAEMON_PLIST" 2>/dev/null
        launchctl load "$DAEMON_PLIST"
        
        sleep 1
        local daemon_pid=$(launchctl list | grep "com.luxafor.menu-daemon" | awk '{print $1}')
        if [ "$daemon_pid" != "-" ]; then
            echo "✓ Menu daemon started (PID: $daemon_pid)"
        fi
    else
        # Fallback to manual start
        if [ -f "$DAEMON_PID_FILE" ]; then
            local daemon_pid=$(cat "$DAEMON_PID_FILE")
            if ps -p "$daemon_pid" > /dev/null 2>&1; then
                echo "Menu daemon already running (PID: $daemon_pid)"
                return
            fi
        fi
        
        echo "Starting menu daemon manually..."
        nohup "$DAEMON_SCRIPT" > /dev/null 2>&1 &
        sleep 1
        if [ -f "$DAEMON_PID_FILE" ]; then
            echo "✓ Started manually (PID: $(cat "$DAEMON_PID_FILE"))"
        fi
    fi
}

stop() {
    echo "Stopping Luxafor services..."
    
    # Unload notification monitor
    NOTIFY_PLIST="$HOME/Library/LaunchAgents/com.luxafor.notify.plist"
    if [ -f "$NOTIFY_PLIST" ]; then
        launchctl unload "$NOTIFY_PLIST" 2>/dev/null || true
        echo "✓ Notification monitor stopped"
    fi
    
    # Kill any running instances
    pkill -f "luxafor-notify.sh" 2>/dev/null || true
    
    # Clean up PID file
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
    fi
    
    # Turn off the light
    "$SCRIPT_DIR/../luxafor-cli/build/luxafor" off 2>/dev/null || true
    
    # Stop the menu daemon
    stop_daemon
    
    echo "✓ All services stopped"
}

stop_daemon() {
    # Unload daemon launch agent
    DAEMON_PLIST="$HOME/Library/LaunchAgents/com.luxafor.menu-daemon.plist"
    if [ -f "$DAEMON_PLIST" ]; then
        launchctl unload "$DAEMON_PLIST" 2>/dev/null || true
        echo "✓ Menu daemon stopped"
    fi
    
    # Kill any manual instances
    pkill -f "luxafor-menu-daemon.sh" 2>/dev/null || true
    
    # Clean up
    rm -f "$DAEMON_PID_FILE"
    rm -f "/tmp/luxafor-menu-cache"
}

status() {
    echo "=== Luxafor Service Status ==="
    
    # Check notify service
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "Notification monitor: Running (PID: $PID)"
        else
            echo "Notification monitor: Not running (stale PID file)"
        fi
    else
        echo "Notification monitor: Not running"
    fi
    
    # Check menu daemon
    if [ -f "$DAEMON_PID_FILE" ]; then
        local daemon_pid=$(cat "$DAEMON_PID_FILE")
        if ps -p "$daemon_pid" > /dev/null 2>&1; then
            echo "Menu daemon: Running (PID: $daemon_pid)"
            
            # Check cache freshness
            if [ -f "/tmp/luxafor-menu-cache" ]; then
                local cache_age=$(($(date +%s) - $(stat -f %m "/tmp/luxafor-menu-cache" 2>/dev/null || echo 0)))
                echo "Cache age: ${cache_age}s"
            fi
        else
            echo "Menu daemon: Not running (stale PID file)"
        fi
    else
        echo "Menu daemon: Not running"
    fi
}

restart() {
    stop
    sleep 2  # Give more time for processes to fully terminate
    start
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        echo ""
        echo "Commands:"
        echo "  start   - Start monitoring notifications"
        echo "  stop    - Stop monitoring and turn off light"
        echo "  restart - Restart the monitoring"
        echo "  status  - Show current status and recent activity"
        exit 1
        ;;
esac