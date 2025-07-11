#!/usr/bin/env bash

echo "=== Testing Dock access ==="
echo

# Test 1: List all Dock items
echo "Test 1: Listing all Dock UI elements..."
osascript <<'APPLESCRIPT'
tell application "System Events"
  tell application process "Dock"
    set dockItems to name of every UI element of list 1
    return dockItems
  end tell
end tell
APPLESCRIPT

echo
echo "Test 2: Check accessibility permissions..."
osascript <<'APPLESCRIPT'
tell application "System Events"
  set isEnabled to UI elements enabled
  return "Accessibility enabled: " & isEnabled
end tell
APPLESCRIPT

echo
echo "Test 3: Try different app name variations..."
for app in "Slack" "Microsoft Outlook" "Outlook" "Microsoft Teams" "Teams"; do
  echo -n "Checking '$app': "
  osascript <<APPLESCRIPT
tell application "System Events"
  tell application process "Dock"
    try
      set badgeVal to value of attribute "AXBadgeValue" of UI element "$app" of list 1
      return badgeVal
    on error errMsg
      return "Error: " & errMsg
    end try
  end tell
end tell
APPLESCRIPT
done