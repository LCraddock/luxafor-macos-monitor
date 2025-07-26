#!/usr/bin/env bash
#
# luxafor-menu-daemon.sh
# Background daemon that generates SwiftBar menu cache
# This reduces CPU usage by doing all heavy work in one process
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_FILE="/tmp/luxafor-menu-cache"
PID_FILE="/tmp/luxafor-menu-daemon.pid"
LOG_FILE="/tmp/luxafor-menu-daemon.log"

# Write PID
echo $$ > "$PID_FILE"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Cleanup on exit
cleanup() {
    log "Daemon stopping..."
    rm -f "$PID_FILE"
    rm -f "$CACHE_FILE"
    exit 0
}

trap cleanup EXIT INT TERM

log "Daemon starting (PID: $$)"

# Function to generate menu (extracted from luxafor-toggle.1s.sh)
generate_menu() {
    # Use the existing luxafor-toggle.1s.sh script but capture output
    # This way we don't duplicate all the logic
    local menu_output
    menu_output=$("$SCRIPT_DIR/luxafor-toggle.1s.sh.backup" 2>/dev/null)
    
    # Add metadata to help detect stale cache
    {
        echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# PID: $$"
        echo "$menu_output"
    } > "$CACHE_FILE.tmp"
    
    # Atomic move to prevent partial reads
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"
}

# Main loop
while true; do
    generate_menu
    
    # Check every second (matches original refresh rate)
    sleep 1
done