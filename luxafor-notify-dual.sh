#!/usr/bin/env bash
#
# luxafor-notify-dual.sh
# Monitors Slack, Teams, Zoom, and Outlook for notifications
# Uses front/back LEDs to show two notifications simultaneously
#

POLL_INTERVAL=10
LUXAFOR_CLI="/Users/larry.craddock/Projects/luxafor-cli/build/luxafor"

# Get badge count using lsappinfo
get_badge_lsappinfo() {
  local bundle_id="$1"
  local status_info=$(lsappinfo info -only StatusLabel "$bundle_id" 2>/dev/null)
  local badge_count=$(echo "$status_info" | grep -o '"label"="[0-9]*"' | cut -d'"' -f4)
  
  if [[ -z "$badge_count" ]] || [[ "$status_info" == *"kCFNULL"* ]]; then
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

while true; do
  # Get badges for all apps
  slackBadge=$(get_badge_lsappinfo "com.tinyspeck.slackmacgap")
  teamsBadge=$(get_badge_lsappinfo "com.microsoft.teams2")
  zoomBadge=$(get_badge_lsappinfo "us.zoom.xos")
  
  # For Outlook, check both badge AND total unread
  outlookBadge=$(get_badge_lsappinfo "com.microsoft.Outlook")
  outlookTotal=$(get_outlook_unread_total)
  
  # Use whichever is higher for Outlook
  if [[ "$outlookTotal" -gt "$outlookBadge" ]]; then
    outlookCount=$outlookTotal
    outlookSource="all folders"
  else
    outlookCount=$outlookBadge
    outlookSource="inbox only"
  fi

  echo "[$(date)] Zoom: $zoomBadge, Slack: $slackBadge, Teams: $teamsBadge, Outlook: $outlookCount ($outlookSource)"

  # Create arrays for active notifications in priority order
  active_apps=()
  active_colors=()
  active_effects=()
  
  if [[ "$zoomBadge" -gt 0 ]]; then
    active_apps+=("Zoom")
    active_colors+=("red")
    active_effects+=("strobe")
  fi
  
  if [[ "$slackBadge" -gt 0 ]]; then
    active_apps+=("Slack")
    active_colors+=("cyan")
    active_effects+=("solid")
  fi
  
  if [[ "$teamsBadge" -gt 0 ]]; then
    active_apps+=("Teams")
    active_colors+=("yellow")
    active_effects+=("solid")
  fi
  
  if [[ "$outlookCount" -gt 0 ]]; then
    active_apps+=("Outlook")
    active_colors+=("green")
    active_effects+=("fade")
  fi

  # Handle notifications based on count
  case ${#active_apps[@]} in
    0)
      echo "Setting Luxafor to OFF (no notifications)"
      $LUXAFOR_CLI off
      ;;
    1)
      echo "Setting Luxafor to ${active_colors[0]} (${active_apps[0]} only)"
      if [[ "${active_effects[0]}" == "strobe" ]]; then
        $LUXAFOR_CLI strobe --color "${active_colors[0]}" --speed 10 --repeat 0
      elif [[ "${active_effects[0]}" == "fade" ]]; then
        $LUXAFOR_CLI fade --color "${active_colors[0]}" --speed 50
      else
        $LUXAFOR_CLI "${active_colors[0]}"
      fi
      ;;
    *)
      # Multiple notifications - use front for highest priority, back for second
      echo "Multiple notifications: Front=${active_apps[0]} (${active_colors[0]}), Back=${active_apps[1]} (${active_colors[1]})"
      
      # Set front LED (highest priority)
      if [[ "${active_effects[0]}" == "strobe" ]]; then
        $LUXAFOR_CLI strobe --color "${active_colors[0]}" --speed 10 --repeat 0 --led front
      elif [[ "${active_effects[0]}" == "fade" ]]; then
        $LUXAFOR_CLI fade --color "${active_colors[0]}" --speed 50 --led front
      else
        $LUXAFOR_CLI "${active_colors[0]}" --led front
      fi
      
      # Brief pause to ensure command is processed
      sleep 0.5
      
      # Set back LED (second priority)
      if [[ "${active_effects[1]}" == "strobe" ]]; then
        $LUXAFOR_CLI strobe --color "${active_colors[1]}" --speed 10 --repeat 0 --led back
      elif [[ "${active_effects[1]}" == "fade" ]]; then
        $LUXAFOR_CLI fade --color "${active_colors[1]}" --speed 50 --led back
      else
        $LUXAFOR_CLI "${active_colors[1]}" --led back
      fi
      
      # Show count if more than 2
      if [[ ${#active_apps[@]} -gt 2 ]]; then
        echo "  (Plus ${#active_apps[@]}-2 more: ${active_apps[@]:2})"
      fi
      ;;
  esac

  sleep "$POLL_INTERVAL"
done