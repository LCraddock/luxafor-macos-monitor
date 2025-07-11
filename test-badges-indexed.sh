#!/usr/bin/env bash

echo "=== Testing badge access by index ==="
echo

# Get all UI elements with their badges
osascript <<'APPLESCRIPT'
tell application "System Events"
  tell application process "Dock"
    set output to ""
    set dockList to list 1
    set itemCount to count of UI elements of dockList
    
    repeat with i from 1 to itemCount
      try
        set itemName to name of UI element i of dockList
        set badgeValue to value of attribute "AXBadgeValue" of UI element i of dockList
        set output to output & "Item " & i & ": " & itemName & " - Badge: " & badgeValue & return
      on error
        try
          set itemName to name of UI element i of dockList
          set output to output & "Item " & i & ": " & itemName & " - No badge" & return
        end try
      end try
    end repeat
    
    return output
  end tell
end tell
APPLESCRIPT