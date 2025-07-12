#!/usr/bin/env bash
#
# luxafor-toggle.1s.sh
# SwiftBar/BitBar plugin for Luxafor notification control
# The "1s" in the filename means it refreshes every 1 second
#

PLIST_NAME="com.luxafor.notify"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"
SCRIPT_DIR="/Users/larry.craddock/Projects/luxafor"

# Get badge count using lsappinfo
get_badge_lsappinfo() {
  local bundle_id="$1"
  local status_info=$(lsappinfo info -only StatusLabel "$bundle_id" 2>/dev/null)
  
  # Check for numeric badge
  local badge_count=$(echo "$status_info" | grep -o '"label"="[0-9]*"' | cut -d'"' -f4)
  
  # Check for bullet point (Slack uses this for notifications)
  if [[ "$status_info" == *'"label"="•"'* ]]; then
    echo "1"  # Return 1 if bullet is present
  elif [[ -z "$badge_count" ]] || [[ "$status_info" == *"kCFNULL"* ]]; then
    echo "0"
  else
    echo "$badge_count"
  fi
}

# Get Outlook unread count from ALL folders
get_outlook_unread_total() {
  local count=$(osascript <<'APPLESCRIPT' 2>/dev/null
tell application "Microsoft Outlook"
    try
        set totalUnread to 0
        set defaultAcct to default account
        
        repeat with eachFolder in (get mail folders of defaultAcct)
            set totalUnread to totalUnread + (unread count of eachFolder)
        end repeat
        
        return totalUnread as integer
        
    on error
        return 0
    end try
end tell
APPLESCRIPT
)
  
  if [[ "$count" =~ ^[0-9]+$ ]]; then
    echo "$count"
  else
    echo "0"
  fi
}

# Check if Luxafor device is connected
check_luxafor_device() {
    # Check for Luxafor device in USB system profile without affecting LED state
    if system_profiler SPUSBDataType 2>/dev/null | grep -qi "luxafor"; then
        return 0  # Device connected
    else
        return 1  # Device not connected
    fi
}

# Check if the service is running
if launchctl list | grep -q "$PLIST_NAME"; then
    STATUS="running"
    # Check if device is connected
    if check_luxafor_device; then
        ICON="🟢"  # Green circle when running and device connected
        DEVICE_STATUS="connected"
    else
        ICON="🟠"  # Amber/orange circle when running but device not connected
        DEVICE_STATUS="disconnected"
    fi
else
    STATUS="stopped"
    ICON="🔴"  # Red circle when stopped
    DEVICE_STATUS="unknown"
fi

# Menu bar display
echo "$ICON"
echo "---"

# Menu items
if [ "$STATUS" = "running" ]; then
    if [ "$DEVICE_STATUS" = "connected" ]; then
        echo "Luxafor Monitor: Running | color=green"
    else
        echo "Luxafor Monitor: Running (No Device) | color=orange"
    fi
    echo "Stop Monitoring | bash='$SCRIPT_DIR/luxafor-control.sh' param1='stop' terminal=false refresh=true"
    
    # Show current notification counts
    echo "---"
    echo "Current Notifications:"
    
    # Read config and get badge counts
    CONFIG_FILE="$SCRIPT_DIR/luxafor-config.conf"
    
    # Arrays to store config
    declare -a APP_NAMES
    declare -a BUNDLE_IDS  
    declare -a COLORS
    declare -a PRIORITIES
    
    # Read config file
    local index=0
    while IFS='|' read -r name bundle color priority || [ -n "$name" ]; do
        # Skip comments and empty lines
        [[ "$name" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$name" ]] && continue
        
        # Trim whitespace
        name=$(echo "$name" | xargs)
        bundle=$(echo "$bundle" | xargs)
        color=$(echo "$color" | xargs)
        priority=$(echo "$priority" | xargs)
        
        # Store in arrays
        APP_NAMES[$index]="$name"
        BUNDLE_IDS[$index]="$bundle"
        COLORS[$index]="$color"
        PRIORITIES[$index]="$priority"
        
        ((index++))
    done < "$CONFIG_FILE"
    
    # Check each app and display if it has notifications
    has_notifications=false
    for i in "${!APP_NAMES[@]}"; do
        app_name="${APP_NAMES[$i]}"
        bundle_id="${BUNDLE_IDS[$i]}"
        color="${COLORS[$i]}"
        
        # Get badge count
        badge_count=$(get_badge_lsappinfo "$bundle_id")
        
        # Special handling for Outlook
        if [[ "$app_name" == "Outlook" ]]; then
            outlook_total=$(get_outlook_unread_total)
            if [[ "$outlook_total" -gt "$badge_count" ]]; then
                badge_count=$outlook_total
                note=" (all folders)"
            else
                note=""
            fi
        else
            note=""
        fi
        
        # Display if has notifications
        if [[ "$badge_count" -gt 0 ]]; then
            echo "$app_name: $badge_count$note | color=$color size=12"
            has_notifications=true
        fi
    done
    
    # If no notifications
    if [[ "$has_notifications" == "false" ]]; then
        echo "No notifications | color=gray size=12"
    fi
    
    # Show enable/disable toggles
    echo "---"
    echo "Enabled Apps:"
    
    # Read enabled state for each app from main config
    while IFS='|' read -r name bundle color priority || [ -n "$name" ]; do
        # Skip comments and empty lines
        [[ "$name" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$name" ]] && continue
        
        # Trim whitespace
        name=$(echo "$name" | xargs)
        color=$(echo "$color" | xargs)
        
        # Check if enabled
        if grep -q "^${name}|disabled" "$SCRIPT_DIR/luxafor-enabled-apps.conf" 2>/dev/null; then
            echo "☐ $name | bash='$SCRIPT_DIR/toggle-app.sh' param1='$name' param2='enable' terminal=false refresh=true color=$color"
        else
            echo "☑ $name | bash='$SCRIPT_DIR/toggle-app.sh' param1='$name' param2='disable' terminal=false refresh=true color=$color"
        fi
    done < "$CONFIG_FILE"
    
else
    echo "Luxafor Monitor: Stopped | color=red"
    echo "Start Monitoring | bash='launchctl' param1=load param2='$PLIST_PATH' terminal=false refresh=true"
fi

echo "---"
echo "Edit Config | bash='code' param1='$SCRIPT_DIR/luxafor-config.conf' terminal=false"
echo "Edit Burp Flash | bash='code' param1='$SCRIPT_DIR/luxafor-burp-flash.sh' terminal=false"
echo "Restart Monitor | bash='$SCRIPT_DIR/luxafor-control.sh' param1='restart' terminal=true"
echo "---"
echo "Quick LED Test (6s) | bash='$SCRIPT_DIR/luxafor-quick-test.sh' terminal=false"
echo "Full LED Test (30s) | bash='$SCRIPT_DIR/luxafor-test.sh' terminal=true"
echo "---"
echo "Manual Colors: (⌥-click to keep menu open)"
echo "  Red | bash='$SCRIPT_DIR/../luxafor-cli/build/luxafor' param1='red' terminal=false"
echo "  Green | bash='$SCRIPT_DIR/../luxafor-cli/build/luxafor' param1='green' terminal=false"
echo "  Blue | bash='$SCRIPT_DIR/../luxafor-cli/build/luxafor' param1='blue' terminal=false"
echo "  Off | bash='$SCRIPT_DIR/../luxafor-cli/build/luxafor' param1='off' terminal=false"
echo "---"
echo "Open Folder | bash='open' param1='$SCRIPT_DIR' terminal=false"