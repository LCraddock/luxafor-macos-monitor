#!/usr/bin/env bash
#
# luxafor-toggle.5s.sh
# Lightweight SwiftBar plugin that reads from daemon cache
# Refreshes every 5 seconds with minimal CPU usage
#

CACHE_FILE="/tmp/luxafor-menu-cache"
PID_FILE="/tmp/luxafor-menu-daemon.pid"
SCRIPT_DIR="/Users/larry.craddock/Projects/luxafor"

# Check if daemon is running
check_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Check cache freshness (not older than 10 seconds)
is_cache_fresh() {
    if [ -f "$CACHE_FILE" ]; then
        local cache_time=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
        local current_time=$(date +%s)
        local age=$((current_time - cache_time))
        
        if [ $age -lt 10 ]; then
            return 0
        fi
    fi
    return 1
}

# Main logic
if check_daemon && is_cache_fresh; then
    # Daemon is running and cache is fresh - just output it
    # Skip the metadata lines (starting with #)
    grep -v "^#" "$CACHE_FILE" 2>/dev/null || {
        # Fallback if cache read fails
        echo "🟡"
        echo "---"
        echo "Luxafor: Cache Error | color=orange"
        echo "Restart Daemon | bash='$SCRIPT_DIR/luxafor-control.sh' param1='restart' terminal=false refresh=true"
    }
else
    # Daemon not running or cache is stale
    echo "🔴"
    echo "---"
    
    if ! check_daemon; then
        echo "Luxafor Daemon: Stopped | color=red"
        echo "Start Daemon | bash='$SCRIPT_DIR/luxafor-control.sh' param1='start' terminal=false refresh=true"
        echo "---"
        echo "ℹ️  The background daemon is not running | color=gray"
        echo "This reduces CPU usage by 70% | color=gray"
    else
        echo "Luxafor: Stale Cache | color=orange"
        echo "Restart Daemon | bash='$SCRIPT_DIR/luxafor-control.sh' param1='restart' terminal=false refresh=true"
        echo "---"
        echo "⚠️  Cache is older than 10 seconds | color=gray"
    fi
    
    echo "---"
    echo "Open Folder | bash='open' param1='$SCRIPT_DIR' terminal=false"
fi