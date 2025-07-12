#!/usr/bin/env bash
#
# toggle-app.sh
# Enable/disable individual apps for Luxafor monitoring
#

APP_NAME="$1"
ACTION="$2"
ENABLED_FILE="/Users/larry.craddock/Projects/luxafor/luxafor-enabled-apps.conf"

# Create file if it doesn't exist
if [ ! -f "$ENABLED_FILE" ]; then
    cat > "$ENABLED_FILE" << EOF
# Luxafor Enabled Apps
# This file tracks which apps are currently enabled for monitoring
# Format: AppName|enabled/disabled

Teams|enabled
Outlook|enabled
Slack|enabled
Zoom|enabled
EOF
fi

# Remove any existing entry for this app
grep -v "^${APP_NAME}|" "$ENABLED_FILE" > "${ENABLED_FILE}.tmp"

# Add new state
if [ "$ACTION" = "disable" ]; then
    echo "${APP_NAME}|disabled" >> "${ENABLED_FILE}.tmp"
else
    echo "${APP_NAME}|enabled" >> "${ENABLED_FILE}.tmp"
fi

# Replace file
mv "${ENABLED_FILE}.tmp" "$ENABLED_FILE"

# Restart the monitor to apply changes
/Users/larry.craddock/Projects/luxafor/luxafor-control.sh restart >/dev/null 2>&1 &