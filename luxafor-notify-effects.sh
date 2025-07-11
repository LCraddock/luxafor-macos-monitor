#!/usr/bin/env bash
#
# luxafor-notify-effects.sh
# Enhanced version with various effects based on notification state
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

  # Count active notifications
  activeCount=0
  [[ "$zoomBadge" -gt 0 ]] && ((activeCount++))
  [[ "$slackBadge" -gt 0 ]] && ((activeCount++))
  [[ "$teamsBadge" -gt 0 ]] && ((activeCount++))
  [[ "$outlookCount" -gt 0 ]] && ((activeCount++))

  # Priority order: Zoom > Slack > Teams > Outlook
  if [[ "$zoomBadge" -gt 0 ]]; then
    # ZOOM: Urgent red strobe
    echo "Setting Luxafor to RED STROBE (Zoom - meeting waiting!)"
    $LUXAFOR_CLI strobe --color red --speed 10 --repeat 0
    
  elif [[ "$activeCount" -ge 3 ]]; then
    # MULTIPLE URGENT: Use wave pattern to show multiple notifications
    echo "Setting Luxafor to WAVE PATTERN (3+ apps have notifications!)"
    $LUXAFOR_CLI wave --type 1 --color magenta --speed 30 --repeat 0
    
  elif [[ "$activeCount" -eq 2 ]]; then
    # TWO NOTIFICATIONS: Alternate between them using pattern
    echo "Setting Luxafor to PATTERN (2 apps have notifications)"
    $LUXAFOR_CLI pattern --id 7 --repeat 0
    
  elif [[ "$slackBadge" -gt 0 ]]; then
    if [[ "$slackBadge" -gt 5 ]]; then
      # Many Slack messages: Pulse effect
      echo "Setting Luxafor to CYAN STROBE ($slackBadge Slack messages!)"
      $LUXAFOR_CLI strobe --color cyan --speed 50 --repeat 0
    else
      # Few Slack messages: Solid
      echo "Setting Luxafor to CYAN (Slack)"
      $LUXAFOR_CLI cyan
    fi
    
  elif [[ "$teamsBadge" -gt 0 ]]; then
    # Teams: Yellow with fade effect
    echo "Setting Luxafor to YELLOW FADE (Teams)"
    $LUXAFOR_CLI fade --color yellow --speed 30
    
  elif [[ "$outlookCount" -gt 0 ]]; then
    if [[ "$outlookCount" -gt 10 ]]; then
      # Many emails: Wave pattern
      echo "Setting Luxafor to GREEN WAVE ($outlookCount emails!)"
      $LUXAFOR_CLI wave --type 2 --color green --speed 40 --repeat 0
    else
      # Few emails: Gentle fade
      echo "Setting Luxafor to GREEN FADE (Outlook)"
      $LUXAFOR_CLI fade --color green --speed 50
    fi
    
  else
    echo "Setting Luxafor to OFF (no notifications)"
    $LUXAFOR_CLI off
  fi

  sleep "$POLL_INTERVAL"
done