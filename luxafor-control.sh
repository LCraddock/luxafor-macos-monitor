#!/usr/bin/env bash
#
# luxafor-control.sh
# Control script to easily start/stop/restart luxafor notifications
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NOTIFY_SCRIPT="$SCRIPT_DIR/luxafor-notify.sh"
PID_FILE="$SCRIPT_DIR/.luxafor-notify.pid"
# No logging - runs silently

start() {
    # Use launch agent if available
    PLIST_PATH="$HOME/Library/LaunchAgents/com.luxafor.notify.plist"
    if [ -f "$PLIST_PATH" ]; then
        echo "Starting Luxafor notify via launch agent..."
        # Kill any manually started processes first
        pkill -f "luxafor-notify.sh" 2>/dev/null || true
        sleep 1
        
        # Load launch agent
        launchctl load "$PLIST_PATH" 2>/dev/null || echo "Already loaded"
        
        # Get PID from launch agent
        sleep 1
        PID=$(launchctl list | grep "com.luxafor.notify" | awk '{print $1}')
        if [ "$PID" != "-" ]; then
            echo "Started with PID: $PID"
            echo $PID > "$PID_FILE"
        fi
    else
        # Fallback to manual start
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if ps -p "$PID" > /dev/null 2>&1; then
                echo "Luxafor notify is already running (PID: $PID)"
                return 1
            fi
        fi
        
        echo "Starting Luxafor notify..."
        nohup "$NOTIFY_SCRIPT" > /dev/null 2>&1 &
        echo $! > "$PID_FILE"
        echo "Started with PID: $(cat "$PID_FILE")"
    fi
}

stop() {
    # Unload launch agent if available
    PLIST_PATH="$HOME/Library/LaunchAgents/com.luxafor.notify.plist"
    if [ -f "$PLIST_PATH" ]; then
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
    fi
    
    # Kill any running instances
    pkill -f "luxafor-notify.sh" 2>/dev/null || true
    
    # Clean up PID file
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
    fi
    
    # Turn off the light
    "$SCRIPT_DIR/../luxafor-cli/build/luxafor" off 2>/dev/null || true
    
    echo "Luxafor notify stopped"
}

status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "Luxafor notify is running (PID: $PID)"
        else
            echo "Luxafor notify is not running (stale PID file)"
        fi
    else
        echo "Luxafor notify is not running"
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