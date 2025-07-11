#!/usr/bin/env bash

echo "=== Testing all attributes of Dock items ==="
echo

# Test specific apps and list ALL their attributes
for app in "Slack" "Microsoft Outlook" "Microsoft Teams"; do
  echo "Checking attributes for: $app"
  osascript <<APPLESCRIPT
tell application "System Events"
  tell application process "Dock"
    set dockList to list 1
    set itemCount to count of UI elements of dockList
    
    repeat with i from 1 to itemCount
      try
        set itemName to name of UI element i of dockList
        if itemName is "$app" then
          set allAttributes to name of every attribute of UI element i of dockList
          return "Attributes for " & itemName & ": " & allAttributes
        end if
      end try
    end repeat
    
    return "$app not found"
  end tell
end tell
APPLESCRIPT
  echo
done

echo "=== Checking if apps are running ==="
for app in "Slack" "Microsoft Outlook" "Microsoft Teams"; do
  echo -n "$app running: "
  osascript -e "tell application \"System Events\" to return exists (processes where name is \"$app\")"
done