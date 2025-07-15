#!/usr/bin/env bash
#
# toggle-channel.sh
# Toggle individual channel/folder monitoring on/off
#

APP_NAME="$1"      # e.g., "Outlook"
TYPE="$2"          # e.g., "folder"
ITEM_NAME="$3"     # e.g., "Phishing"
NEW_STATE="$4"     # "true" or "false"

CHANNELS_CONFIG="/Users/larry.craddock/Projects/luxafor/luxafor-channels.conf"
TEMP_FILE="/tmp/luxafor-channels-temp.conf"

if [ -z "$APP_NAME" ] || [ -z "$TYPE" ] || [ -z "$ITEM_NAME" ] || [ -z "$NEW_STATE" ]; then
    echo "Usage: $0 <app_name> <type> <item_name> <true|false>"
    exit 1
fi

# Create temp file with updated state
while IFS= read -r line; do
    # Check if it's a comment or empty line
    if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
        echo "$line"
    else
        # Parse the line
        IFS='|' read -r app type name color action priority sound enabled <<< "$line"
        
        # Trim whitespace
        app=$(echo "$app" | xargs)
        type=$(echo "$type" | xargs)
        name=$(echo "$name" | xargs)
        
        if [[ "$app" == "$APP_NAME" ]] && [[ "$type" == "$TYPE" ]] && [[ "$name" == "$ITEM_NAME" ]]; then
            # Update this line with new state
            echo "$app|$type|$name|$color|$action|$priority|$sound|$NEW_STATE"
        else
            # Keep line as-is
            echo "$line"
        fi
    fi
done < "$CHANNELS_CONFIG" > "$TEMP_FILE"

# Replace original file
mv "$TEMP_FILE" "$CHANNELS_CONFIG"

# Restart the monitor to apply changes
/Users/larry.craddock/Projects/luxafor/luxafor-control.sh restart >/dev/null 2>&1 &