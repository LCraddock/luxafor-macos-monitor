#!/usr/bin/env bash
#
# luxafor-notify.sh
# Monitors apps for notifications based on config file
#

# Debug mode - set to true to enable logging
DEBUG_MODE="${DEBUG_MODE:-false}"

debug_log() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo "[$(date '+%H:%M:%S')] $1" >> /tmp/luxafor-debug.log
    fi
}

POLL_INTERVAL=5
LUXAFOR_CLI="/Users/larry.craddock/Projects/luxafor-cli/build/luxafor"
CONFIG_FILE="/Users/larry.craddock/Projects/luxafor/luxafor-config.conf"
OUTLOOK_FOLDERS_CONFIG="/Users/larry.craddock/Projects/luxafor/luxafor-outlook-folders.conf"
PUSHOVER_CONFIG="/Users/larry.craddock/Projects/luxafor/luxafor-pushover.conf"


# Arrays to store config
declare -a APP_NAMES
declare -a BUNDLE_IDS
declare -a COLORS
declare -a PRIORITIES

# Read config file
load_config() {
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
}

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
  
  # Ensure we return a number
  if [[ "$count" =~ ^[0-9]+$ ]]; then
    echo "$count"
  else
    echo "0"
  fi
}

# Check specific Outlook folder for unread emails
check_outlook_special_folder() {
  local folder_name="$1"
  local count=$(osascript <<APPLESCRIPT 2>/dev/null
tell application "Microsoft Outlook"
    try
        set targetFolder to missing value
        set defaultAcct to default account
        
        repeat with eachFolder in (get mail folders of defaultAcct)
            if name of eachFolder is "${folder_name}" then
                set targetFolder to eachFolder
                exit repeat
            end if
        end repeat
        
        if targetFolder is not missing value then
            return (unread count of targetFolder) as integer
        else
            return 0
        end if
        
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

# Load configuration
load_config

# Track previous LED state
previous_color="off"

# Check if app is enabled
is_app_enabled() {
    local app_name="$1"
    local enabled_file="/Users/larry.craddock/Projects/luxafor/luxafor-enabled-apps.conf"
    
    # Default to enabled if file doesn't exist
    if [ ! -f "$enabled_file" ]; then
        return 0
    fi
    
    # Check if app is explicitly disabled
    if grep -q "^${app_name}|disabled" "$enabled_file" 2>/dev/null; then
        return 1
    fi
    
    return 0
}

# Send Pushover notification
send_pushover() {
    local app_name="$1"
    local message="$2"
    local priority="${3:-0}"
    local sound="${4:-pushover}"
    
    # Check if Pushover is enabled
    if [ -f "$PUSHOVER_CONFIG" ]; then
        # Only read the specific variables we need
        eval $(grep "^PUSHOVER_APP_TOKEN=" "$PUSHOVER_CONFIG")
        eval $(grep "^PUSHOVER_USER_KEY=" "$PUSHOVER_CONFIG")
        eval $(grep "^PUSHOVER_ENABLED=" "$PUSHOVER_CONFIG")
        
        if [[ "$PUSHOVER_ENABLED" != "true" ]]; then
            return
        fi
    else
        return
    fi
    
    # Send the notification
    curl -s -X POST https://api.pushover.net/1/messages.json \
        -d "token=$PUSHOVER_APP_TOKEN" \
        -d "user=$PUSHOVER_USER_KEY" \
        -d "title=Luxafor: $app_name" \
        -d "message=$message" \
        -d "priority=$priority" \
        -d "sound=$sound" >/dev/null 2>&1
}


while true; do
  # Find highest priority app with notifications
  highest_priority=999
  selected_color="off"
  special_folder_action=""
  special_folder_color=""
  outlook_has_special=false
  
  for i in "${!APP_NAMES[@]}"; do
    app_name="${APP_NAMES[$i]}"
    bundle_id="${BUNDLE_IDS[$i]}"
    color="${COLORS[$i]}"
    priority="${PRIORITIES[$i]}"
    
    # Get badge count
    badge_count=$(get_badge_lsappinfo "$bundle_id")
    
    # Special handling for Outlook
    if [[ "$app_name" == "Outlook" ]]; then
      outlook_total=$(get_outlook_unread_total)
      if [[ "$outlook_total" -gt "$badge_count" ]]; then
        badge_count=$outlook_total
      fi
      
      # Check special folders if Outlook is enabled
      if is_app_enabled "$app_name" && [ -f "$OUTLOOK_FOLDERS_CONFIG" ]; then
        while IFS='|' read -r folder folder_color action || [ -n "$folder" ]; do
          # Skip comments and empty lines
          [[ "$folder" =~ ^[[:space:]]*# ]] && continue
          [[ -z "$folder" ]] && continue
          
          # Trim whitespace
          folder=$(echo "$folder" | xargs)
          folder_color=$(echo "$folder_color" | xargs)
          action=$(echo "$action" | xargs)
          
          # Check if this folder has unread emails
          folder_count=$(check_outlook_special_folder "$folder")
          if [[ "$folder_count" -gt 0 ]]; then
            outlook_has_special=true
            special_folder_color="$folder_color"
            special_folder_action="$action"
            break  # Use first matching special folder
          fi
        done < "$OUTLOOK_FOLDERS_CONFIG"
      fi
    fi
    
    # Check if this app is enabled and has notifications and higher priority
    if is_app_enabled "$app_name" && [[ "$badge_count" -gt 0 ]] && [[ "$priority" -lt "$highest_priority" ]]; then
        highest_priority=$priority
        selected_color=$color
        
        # If this is Outlook with special folder, override color/action
        if [[ "$app_name" == "Outlook" ]] && [[ "$outlook_has_special" == "true" ]]; then
          selected_color=$special_folder_color
        fi
    fi
  done
  
  # Send Pushover only when LED transitions from off to on
  debug_log "LED state: previous=$previous_color, current=$selected_color"
  
  if [[ "$selected_color" != "off" ]] && [[ "$previous_color" == "off" ]] && [[ "$highest_priority" -lt 999 ]]; then
    # Find which app won the priority
    winning_app=""
    for i in "${!APP_NAMES[@]}"; do
      if [[ "${PRIORITIES[$i]}" -eq "$highest_priority" ]]; then
        winning_app="${APP_NAMES[$i]}"
        break
      fi
    done
    
    # Send simple Pushover notification
    if [[ -n "$winning_app" ]]; then
      debug_log "Sending Pushover for $winning_app (transition from off to $selected_color)"
      send_pushover "$winning_app" "$winning_app notification" "0" "pushover"
    fi
  fi
  
  # Update previous color for next iteration
  previous_color="$selected_color"
  
  # Handle LED based on whether we need to flash or not
  if [[ "$outlook_has_special" == "true" ]] && [[ "$special_folder_action" == "flash" ]] && [[ "$highest_priority" -eq 2 ]]; then
    # Flash mode for special Outlook folders
    $LUXAFOR_CLI $selected_color >/dev/null 2>&1
    sleep 0.5
    $LUXAFOR_CLI off >/dev/null 2>&1
    sleep 0.5
  else
    # Normal solid color mode
    $LUXAFOR_CLI $selected_color >/dev/null 2>&1
    sleep "$POLL_INTERVAL"
  fi
done