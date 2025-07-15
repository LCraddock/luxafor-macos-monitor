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
CHANNELS_CONFIG="/Users/larry.craddock/Projects/luxafor/luxafor-channels.conf"


# Arrays to store config
declare -a APP_NAMES
declare -a BUNDLE_IDS
declare -a COLORS
declare -a PRIORITIES

# Arrays to store channel config
declare -a CHANNEL_APPS
declare -a CHANNEL_TYPES
declare -a CHANNEL_NAMES
declare -a CHANNEL_COLORS
declare -a CHANNEL_ACTIONS
declare -a CHANNEL_PRIORITIES
declare -a CHANNEL_SOUNDS
declare -a CHANNEL_ENABLED

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

# Read channel config file
load_channel_config() {
    if [ ! -f "$CHANNELS_CONFIG" ]; then
        debug_log "No channels config found, skipping"
        return
    fi
    
    local index=0
    while IFS='|' read -r app type name color action priority sound enabled || [ -n "$app" ]; do
        # Skip comments and empty lines
        [[ "$app" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$app" ]] && continue
        
        # Trim whitespace
        app=$(echo "$app" | xargs)
        type=$(echo "$type" | xargs)
        name=$(echo "$name" | xargs)
        color=$(echo "$color" | xargs)
        action=$(echo "$action" | xargs)
        priority=$(echo "$priority" | xargs)
        sound=$(echo "$sound" | xargs)
        enabled=$(echo "$enabled" | xargs)
        
        # Store in arrays
        CHANNEL_APPS[$index]="$app"
        CHANNEL_TYPES[$index]="$type"
        CHANNEL_NAMES[$index]="$name"
        CHANNEL_COLORS[$index]="$color"
        CHANNEL_ACTIONS[$index]="$action"
        CHANNEL_PRIORITIES[$index]="$priority"
        CHANNEL_SOUNDS[$index]="$sound"
        CHANNEL_ENABLED[$index]="$enabled"
        
        debug_log "Loaded channel: $app/$type/$name"
        ((index++))
    done < "$CHANNELS_CONFIG"
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

# Get current Teams channel/chat name
get_teams_current_channel() {
    local window_title=$(osascript -e 'tell application "System Events" to tell process "Microsoft Teams" to name of window 1' 2>/dev/null)
    
    if [[ -z "$window_title" ]]; then
        echo ""
        return
    fi
    
    # Parse the window title
    # Format: "Type | Channel/Chat Name | Microsoft Teams"
    if [[ "$window_title" == *" | "* ]]; then
        # Extract the middle part (channel/chat name)
        local after_first="${window_title#* | }"
        local channel_name="${after_first% | *}"
        echo "$channel_name"
    else
        echo ""
    fi
}

# Check if Teams name is a configured channel
is_teams_configured_channel() {
    local channel_name="$1"
    
    # Check if this name matches any configured Teams channels
    for i in "${!CHANNEL_APPS[@]}"; do
        if [[ "${CHANNEL_APPS[$i]}" == "Teams" ]] && \
           [[ "${CHANNEL_TYPES[$i]}" == "channel" ]] && \
           [[ "${CHANNEL_NAMES[$i]}" == "$channel_name" ]]; then
            return 0  # Found it
        fi
    done
    
    return 1  # Not found
}

# Load configuration
load_config
load_channel_config

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
    debug_log "Sending Pushover: app=$app_name, msg=$message, pri=$priority, snd=$sound"
    
    # Build curl command with base parameters
    curl_cmd="curl -s -X POST https://api.pushover.net/1/messages.json"
    curl_cmd="$curl_cmd -d 'token=$PUSHOVER_APP_TOKEN'"
    curl_cmd="$curl_cmd -d 'user=$PUSHOVER_USER_KEY'"
    curl_cmd="$curl_cmd -d 'title=Luxafor: $app_name'"
    curl_cmd="$curl_cmd -d 'message=$message'"
    curl_cmd="$curl_cmd -d 'priority=$priority'"
    curl_cmd="$curl_cmd -d 'sound=$sound'"
    
    # Add expire and retry for emergency priority
    if [[ "$priority" == "2" ]]; then
        curl_cmd="$curl_cmd -d 'expire=3600'"  # 1 hour
        curl_cmd="$curl_cmd -d 'retry=60'"     # retry every minute
    fi
    
    response=$(eval $curl_cmd 2>&1)
    debug_log "Pushover response: $response"
}


while true; do
  # Find highest priority app with notifications
  highest_priority=999
  selected_color="off"
  special_folder_action=""
  special_folder_color=""
  outlook_has_special=false
  outlook_special_folder=""
  outlook_pushover_priority="0"
  outlook_pushover_sound="pushover"
  
  for i in "${!APP_NAMES[@]}"; do
    app_name="${APP_NAMES[$i]}"
    bundle_id="${BUNDLE_IDS[$i]}"
    color="${COLORS[$i]}"
    priority="${PRIORITIES[$i]}"
    
    # Get badge count
    badge_count=$(get_badge_lsappinfo "$bundle_id")
    
    # Special handling for Outlook - ONLY check configured folders
    if [[ "$app_name" == "Outlook" ]]; then
      # Skip general badge count - we only care about configured folders
      badge_count=0
      
      # Check configured folders
      if is_app_enabled "$app_name"; then
        # First check new channels config
        found_in_channels=false
        for i in "${!CHANNEL_APPS[@]}"; do
          if [[ "${CHANNEL_APPS[$i]}" == "Outlook" ]] && \
             [[ "${CHANNEL_TYPES[$i]}" == "folder" ]] && \
             [[ "${CHANNEL_ENABLED[$i]}" == "true" ]]; then
            
            folder_name="${CHANNEL_NAMES[$i]}"
            folder_count=$(check_outlook_special_folder "$folder_name")
            
            if [[ "$folder_count" -gt 0 ]]; then
              outlook_has_special=true
              outlook_special_folder="$folder_name"
              special_folder_color="${CHANNEL_COLORS[$i]}"
              special_folder_action="${CHANNEL_ACTIONS[$i]}"
              outlook_pushover_priority="${CHANNEL_PRIORITIES[$i]}"
              outlook_pushover_sound="${CHANNEL_SOUNDS[$i]}"
              found_in_channels=true
              badge_count=$folder_count  # Set badge count for this folder
              debug_log "Found mail in channel config folder: $folder_name"
              break
            fi
          fi
        done
        
        # Fall back to old config if not found in channels (DISABLED - using channels now)
        if false && [[ "$found_in_channels" == "false" ]] && [ -f "$OUTLOOK_FOLDERS_CONFIG" ]; then
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
    fi
    
    # Special handling for Teams - check current channel/chat
    if [[ "$app_name" == "Teams" ]]; then
      teams_current_channel=""
      teams_has_special=false
      teams_special_color=""
      teams_special_action=""
      teams_pushover_priority="0"
      teams_pushover_sound="pushover"
      
      # Get current Teams channel/chat name
      if [[ "$badge_count" -gt 0 ]] && is_app_enabled "$app_name"; then
        teams_current_channel=$(get_teams_current_channel)
        
        if [[ -n "$teams_current_channel" ]]; then
          # Check if this is a configured channel
          if is_teams_configured_channel "$teams_current_channel"; then
            # This is a configured channel - check if it's enabled
            for i in "${!CHANNEL_APPS[@]}"; do
              if [[ "${CHANNEL_APPS[$i]}" == "Teams" ]] && \
                 [[ "${CHANNEL_TYPES[$i]}" == "channel" ]] && \
                 [[ "${CHANNEL_NAMES[$i]}" == "$teams_current_channel" ]] && \
                 [[ "${CHANNEL_ENABLED[$i]}" == "true" ]]; then
                
                # Channel is enabled - use its settings
                teams_has_special=true
                teams_special_color="${CHANNEL_COLORS[$i]}"
                teams_special_action="${CHANNEL_ACTIONS[$i]}"
                teams_pushover_priority="${CHANNEL_PRIORITIES[$i]}"
                teams_pushover_sound="${CHANNEL_SOUNDS[$i]}"
                debug_log "Found Teams channel notification: $teams_current_channel"
                break
              fi
            done
            
            # If channel is not enabled, don't alert
            if [[ "$teams_has_special" == "false" ]]; then
              badge_count=0
              debug_log "Teams channel disabled: $teams_current_channel"
            fi
          else
            # This is NOT a configured channel - assume it's a chat
            # Check if all chats are enabled
            for i in "${!CHANNEL_APPS[@]}"; do
              if [[ "${CHANNEL_APPS[$i]}" == "Teams" ]] && \
                 [[ "${CHANNEL_TYPES[$i]}" == "chat" ]] && \
                 [[ "${CHANNEL_NAMES[$i]}" == "_all_chats" ]] && \
                 [[ "${CHANNEL_ENABLED[$i]}" == "true" ]]; then
                
                # All chats are enabled - use chat settings
                teams_has_special=true
                teams_special_color="${CHANNEL_COLORS[$i]}"
                teams_special_action="${CHANNEL_ACTIONS[$i]}"
                teams_pushover_priority="${CHANNEL_PRIORITIES[$i]}"
                teams_pushover_sound="${CHANNEL_SOUNDS[$i]}"
                debug_log "Found Teams chat notification: $teams_current_channel"
                break
              fi
            done
            
            # If all chats are disabled, don't alert
            if [[ "$teams_has_special" == "false" ]]; then
              badge_count=0
              debug_log "Teams chats disabled: $teams_current_channel"
            fi
          fi
        fi
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
        
        # If this is Teams with special channel/chat, override color/action
        if [[ "$app_name" == "Teams" ]] && [[ "$teams_has_special" == "true" ]]; then
          selected_color=$teams_special_color
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
      
      # Use channel-specific settings if available
      push_priority="0"
      push_sound="pushover"
      push_message="$winning_app notification"
      
      if [[ "$winning_app" == "Outlook" ]] && [[ "$outlook_has_special" == "true" ]]; then
        push_priority="$outlook_pushover_priority"
        push_sound="$outlook_pushover_sound"
        push_message="$winning_app: $outlook_special_folder"
      fi
      
      if [[ "$winning_app" == "Teams" ]] && [[ "$teams_has_special" == "true" ]]; then
        push_priority="$teams_pushover_priority"
        push_sound="$teams_pushover_sound"
        if [[ -n "$teams_current_channel" ]]; then
          push_message="$winning_app: $teams_current_channel"
        fi
      fi
      
      # Don't send if sound is "none"
      if [[ "$push_sound" != "none" ]]; then
        debug_log "Pushover settings: priority=$push_priority, sound=$push_sound, message=$push_message"
        send_pushover "$winning_app" "$push_message" "$push_priority" "$push_sound"
      else
        debug_log "Skipping Pushover - sound is 'none'"
      fi
    fi
  fi
  
  # Update previous color for next iteration
  previous_color="$selected_color"
  
  # Write current state for SwiftBar to read
  state_file="/tmp/luxafor-state"
  echo "color=$selected_color" > "$state_file"
  echo "app=$winning_app" >> "$state_file"
  if [[ "$winning_app" == "Outlook" ]] && [[ -n "$outlook_special_folder" ]]; then
    echo "folder=$outlook_special_folder" >> "$state_file"
  fi
  if [[ "$winning_app" == "Teams" ]] && [[ -n "$teams_current_channel" ]]; then
    echo "channel=$teams_current_channel" >> "$state_file"
  fi
  
  # Handle LED based on whether we need to flash or not
  should_flash=false
  
  if [[ "$outlook_has_special" == "true" ]] && [[ "$special_folder_action" == "flash" ]]; then
    should_flash=true
  fi
  
  if [[ "$teams_has_special" == "true" ]] && [[ "$teams_special_action" == "flash" ]]; then
    should_flash=true
  fi
  
  if [[ "$should_flash" == "true" ]]; then
    # Flash mode for special channels/folders
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