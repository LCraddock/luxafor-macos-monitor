#!/usr/bin/env bash
# Test script to check badge values

get_badge() {
  local app="$1"
  osascript <<APPLESCRIPT
tell application "System Events"
  tell application process "Dock"
    try
      set badgeVal to value of attribute "AXBadgeValue" of UI element "$app" of list 1
    on error
      set badgeVal to 0
    end try
  end tell
  return badgeVal
end tell
APPLESCRIPT
}

echo "Testing badge values..."
echo "Slack badge: $(get_badge "Slack")"
echo "Outlook badge: $(get_badge "Microsoft Outlook")"
echo "Teams badge: $(get_badge "Microsoft Teams")"