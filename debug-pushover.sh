#!/usr/bin/env bash
#
# Debug version of luxafor-notify.sh with Pushover logging
#

POLL_INTERVAL=5
LUXAFOR_CLI="/Users/larry.craddock/Projects/luxafor-cli/build/luxafor"
CONFIG_FILE="/Users/larry.craddock/Projects/luxafor/luxafor-config.conf"
OUTLOOK_FOLDERS_CONFIG="/Users/larry.craddock/Projects/luxafor/luxafor-outlook-folders.conf"
PUSHOVER_CONFIG="/Users/larry.craddock/Projects/luxafor/luxafor-pushover.conf"

echo "Starting debug monitor with Pushover logging..."

# Source the main script functions
source /Users/larry.craddock/Projects/luxafor/luxafor-notify.sh

# Override the main loop with debug version
while true; do
  echo "=== Poll cycle at $(date) ==="
  
  # Find highest priority app with notifications
  highest_priority=999
  selected_color="off"
  
  for i in "${!APP_NAMES[@]}"; do
    app_name="${APP_NAMES[$i]}"
    bundle_id="${BUNDLE_IDS[$i]}"
    color="${COLORS[$i]}"
    priority="${PRIORITIES[$i]}"
    
    # Get badge count
    badge_count=$(get_badge_lsappinfo "$bundle_id")
    
    if [[ "$badge_count" -gt 0 ]]; then
      echo "Found $badge_count notifications for $app_name"
      
      # Check Pushover
      pushover_result=$(should_send_pushover "$app_name" "" "$badge_count")
      if [[ $? -eq 0 ]]; then
        echo "Pushover rule matched for $app_name: $pushover_result"
        IFS='|' read -r push_priority push_sound <<< "$pushover_result"
        echo "Would send Pushover with priority=$push_priority sound=$push_sound"
      else
        echo "No Pushover rule matched for $app_name"
      fi
    fi
  done
  
  sleep 5
done