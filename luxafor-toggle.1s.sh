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
    index=0
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
            # Only show notification count if from configured folders
            if [ -f "/tmp/luxafor-state" ]; then
                state_app=$(grep "^app=" /tmp/luxafor-state 2>/dev/null | cut -d'=' -f2)
                state_folder=$(grep "^folder=" /tmp/luxafor-state 2>/dev/null | cut -d'=' -f2)
                if [[ "$state_app" == "Outlook" ]] && [[ -n "$state_folder" ]]; then
                    note=" ($state_folder folder)"
                    # Only show if currently active
                    state_color=$(grep "^color=" /tmp/luxafor-state 2>/dev/null | cut -d'=' -f2)
                    if [[ "$state_color" == "off" ]]; then
                        badge_count=0  # Don't show count if LED is off
                    fi
                else
                    badge_count=0  # No configured folders active
                fi
            else
                badge_count=0
            fi
        elif [[ "$app_name" == "Teams" ]]; then
            # Show Teams channel/chat info if active
            if [ -f "/tmp/luxafor-state" ]; then
                state_app=$(grep "^app=" /tmp/luxafor-state 2>/dev/null | cut -d'=' -f2)
                state_channel=$(grep "^channel=" /tmp/luxafor-state 2>/dev/null | cut -d'=' -f2)
                if [[ "$state_app" == "Teams" ]] && [[ -n "$state_channel" ]]; then
                    note=" ($state_channel)"
                    # Only show if currently active
                    state_color=$(grep "^color=" /tmp/luxafor-state 2>/dev/null | cut -d'=' -f2)
                    if [[ "$state_color" == "off" ]]; then
                        badge_count=0  # Don't show count if LED is off
                    fi
                else
                    badge_count=0  # No active Teams notifications
                fi
            else
                badge_count=0
            fi
        elif [[ "$app_name" == "Slack" ]]; then
            # Show Slack channel/DM info if active
            if [ -f "/tmp/luxafor-state" ]; then
                state_app=$(grep "^app=" /tmp/luxafor-state 2>/dev/null | cut -d'=' -f2)
                state_channel=$(grep "^channel=" /tmp/luxafor-state 2>/dev/null | cut -d'=' -f2)
                if [[ "$state_app" == "Slack" ]] && [[ -n "$state_channel" ]]; then
                    note=" ($state_channel)"
                    # Only show if currently active
                    state_color=$(grep "^color=" /tmp/luxafor-state 2>/dev/null | cut -d'=' -f2)
                    if [[ "$state_color" == "off" ]]; then
                        badge_count=0  # Don't show count if LED is off
                    fi
                else
                    badge_count=0  # No active Slack notifications
                fi
            else
                badge_count=0
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
        
        # Use the original Luxafor colors
        swiftbar_color="$color"
        
        # Check if enabled
        if grep -q "^${name}|disabled" "$SCRIPT_DIR/luxafor-enabled-apps.conf" 2>/dev/null; then
            checkbox="☐"
            action="enable"
        else
            checkbox="☑"
            action="disable"
        fi
        
        # Check if this app has channels/folders configured
        has_channels=false
        if [ -f "$SCRIPT_DIR/luxafor-channels.conf" ]; then
            if grep -q "^${name}|" "$SCRIPT_DIR/luxafor-channels.conf" 2>/dev/null; then
                has_channels=true
            fi
        fi
        
        # Display with submenu if has channels
        if [[ "$has_channels" == "true" ]]; then
            echo "$checkbox $name ▸ | color=$swiftbar_color"
            
            # Special handling for Teams and Slack - show chats/DMs and channels separately
            if [[ "$name" == "Teams" ]] || [[ "$name" == "Slack" ]]; then
                echo "--$name: | color=gray"
                echo "-----"
                
                # Show chats first
                while IFS='|' read -r app_name type item_name item_color item_action priority sound enabled || [ -n "$app_name" ]; do
                    # Skip comments and empty lines
                    [[ "$app_name" =~ ^[[:space:]]*# ]] && continue
                    [[ -z "$app_name" ]] && continue
                    
                    # Trim whitespace
                    app_name=$(echo "$app_name" | xargs)
                    type=$(echo "$type" | xargs)
                    item_name=$(echo "$item_name" | xargs)
                    enabled=$(echo "$enabled" | xargs)
                    
                    if [[ "$app_name" == "$name" ]] && ([[ "$type" == "chat" ]] || [[ "$type" == "dm" ]]); then
                        if [[ "$item_name" == "_all_chats" ]]; then
                            display_name="All Chats"
                        elif [[ "$item_name" == "_all_dms" ]]; then
                            display_name="All DMs"
                        else
                            display_name="$item_name"
                        fi
                        
                        if [[ "$enabled" == "true" ]]; then
                            echo "--☑ $display_name | bash='$SCRIPT_DIR/toggle-channel.sh' param1='$name' param2='$type' param3='$item_name' param4='false' terminal=false refresh=true"
                        else
                            echo "--☐ $display_name | bash='$SCRIPT_DIR/toggle-channel.sh' param1='$name' param2='$type' param3='$item_name' param4='true' terminal=false refresh=true"
                        fi
                    fi
                done < "$SCRIPT_DIR/luxafor-channels.conf"
                
                echo "-----"
                
                # Show channels
                while IFS='|' read -r app_name type item_name item_color item_action priority sound enabled || [ -n "$app_name" ]; do
                    # Skip comments and empty lines
                    [[ "$app_name" =~ ^[[:space:]]*# ]] && continue
                    [[ -z "$app_name" ]] && continue
                    
                    # Trim whitespace
                    app_name=$(echo "$app_name" | xargs)
                    type=$(echo "$type" | xargs)
                    item_name=$(echo "$item_name" | xargs)
                    enabled=$(echo "$enabled" | xargs)
                    
                    if [[ "$app_name" == "$name" ]] && [[ "$type" == "channel" ]]; then
                        if [[ "$enabled" == "true" ]]; then
                            echo "--☑ $item_name | bash='$SCRIPT_DIR/toggle-channel.sh' param1='$name' param2='$type' param3='$item_name' param4='false' terminal=false refresh=true"
                        else
                            echo "--☐ $item_name | bash='$SCRIPT_DIR/toggle-channel.sh' param1='$name' param2='$type' param3='$item_name' param4='true' terminal=false refresh=true"
                        fi
                    fi
                done < "$SCRIPT_DIR/luxafor-channels.conf"
            else
                # Non-Teams apps (like Outlook) - show folders
                echo "--$name folders: | color=gray"
                echo "-----"
                
                # Show individual channels/folders
                while IFS='|' read -r app_name type item_name item_color item_action priority sound enabled || [ -n "$app_name" ]; do
                    # Skip comments and empty lines
                    [[ "$app_name" =~ ^[[:space:]]*# ]] && continue
                    [[ -z "$app_name" ]] && continue
                    
                    # Trim whitespace
                    app_name=$(echo "$app_name" | xargs)
                    type=$(echo "$type" | xargs)
                    item_name=$(echo "$item_name" | xargs)
                    enabled=$(echo "$enabled" | xargs)
                    
                    if [[ "$app_name" == "$name" ]]; then
                        if [[ "$enabled" == "true" ]]; then
                            echo "--☑ $item_name | bash='$SCRIPT_DIR/toggle-channel.sh' param1='$name' param2='$type' param3='$item_name' param4='false' terminal=false refresh=true"
                        else
                            echo "--☐ $item_name | bash='$SCRIPT_DIR/toggle-channel.sh' param1='$name' param2='$type' param3='$item_name' param4='true' terminal=false refresh=true"
                        fi
                    fi
                done < "$SCRIPT_DIR/luxafor-channels.conf"
            fi
        else
            echo "$checkbox $name | bash='$SCRIPT_DIR/toggle-app.sh' param1='$name' param2='$action' terminal=false refresh=true color=$swiftbar_color"
        fi
    done < "$CONFIG_FILE"
    
else
    echo "Luxafor Monitor: Stopped | color=red"
    echo "Start Monitoring | bash='$SCRIPT_DIR/luxafor-control.sh' param1='start' terminal=false refresh=true"
fi

echo "---"

# Check if Pushover is enabled
if [ -f "$SCRIPT_DIR/luxafor-pushover.conf" ]; then
    source "$SCRIPT_DIR/luxafor-pushover.conf"
    if [[ "$PUSHOVER_ENABLED" == "true" ]]; then
        echo "☑ Pushover Alerts | bash='/bin/bash' param1='-c' param2='sed -i \"\" \"s/PUSHOVER_ENABLED=\\\"true\\\"/PUSHOVER_ENABLED=\\\"false\\\"/\" \"$SCRIPT_DIR/luxafor-pushover.conf\"' terminal=false refresh=true color=green"
    else
        echo "☐ Pushover Alerts | bash='/bin/bash' param1='-c' param2='sed -i \"\" \"s/PUSHOVER_ENABLED=\\\"false\\\"/PUSHOVER_ENABLED=\\\"true\\\"/\" \"$SCRIPT_DIR/luxafor-pushover.conf\"' terminal=false refresh=true color=gray"
    fi
fi

echo "---"
echo "Edit Config | bash='code' param1='$SCRIPT_DIR/luxafor-config.conf' terminal=false"
echo "Edit Channels/Folders | bash='code' param1='$SCRIPT_DIR/luxafor-channels.conf' terminal=false"
echo "Edit Pushover Alerts | bash='code' param1='$SCRIPT_DIR/luxafor-pushover.conf' terminal=false"
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