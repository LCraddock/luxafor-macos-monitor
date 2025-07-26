#!/usr/bin/env bash
#
# no-timeout-control.sh
# Control script for screen timeout prevention
#

PID_FILE="/tmp/no-timeout.pid"
LOG_FILE="/tmp/no-timeout.log"

start() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "No-timeout is already running (PID: $PID)"
            return 1
        fi
    fi
    
    echo "Starting no-timeout..."
    
    # Start the timeout prevention in background
    (
        while true; do
            osascript -e 'tell application "System Events" to key code 63' > /dev/null 2>&1
            sleep 600  # Run every 10 minutes
        done
    ) > "$LOG_FILE" 2>&1 &
    
    echo $! > "$PID_FILE"
    echo "No-timeout started (PID: $(cat "$PID_FILE"))"
}

stop() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "Stopping no-timeout..."
            kill "$PID"
            rm -f "$PID_FILE"
            echo "No-timeout stopped"
        else
            echo "No-timeout is not running (stale PID file)"
            rm -f "$PID_FILE"
        fi
    else
        echo "No-timeout is not running"
    fi
}

status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "active"
        else
            echo "inactive"
        fi
    else
        echo "inactive"
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac