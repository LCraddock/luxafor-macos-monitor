#!/usr/bin/env bash

echo "=== Testing AXStatusLabel (alternative badge location) ==="
echo

get_status_label() {
  local appName="$1"
  osascript <<APPLESCRIPT
tell application "System Events"
  tell application process "Dock"
    set dockList to list 1
    set itemCount to count of UI elements of dockList
    
    repeat with i from 1 to itemCount
      try
        set itemName to name of UI element i of dockList
        if itemName is "$appName" then
          try
            set statusVal to value of attribute "AXStatusLabel" of UI element i of dockList
            return statusVal
          on error
            return "No status"
          end try
        end if
      end try
    end repeat
    
    return "App not found"
  end tell
end tell
APPLESCRIPT
}

for app in "Slack" "Microsoft Outlook" "Microsoft Teams"; do
  echo "$app status: $(get_status_label "$app")"
done

echo
echo "=== Manual badge check ==="
echo "1. Make sure you have unread messages in Slack/Outlook"
echo "2. Look at the Dock - do you see red badge numbers on the app icons?"
echo "3. If yes, the issue is with AppleScript access"
echo "4. If no, try quitting and restarting the apps"