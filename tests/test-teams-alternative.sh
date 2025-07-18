#!/usr/bin/env bash
#
# test-teams-alternative.sh
# Alternative approaches to detect Teams notifications
#

echo "=== Alternative Teams Detection Methods ==="
echo

# Method 1: Check window titles for all Teams windows
echo "1. All Teams window titles:"
osascript <<'EOF' 2>&1
tell application "System Events"
    tell process "Microsoft Teams"
        set windowTitles to {}
        repeat with w in windows
            set end of windowTitles to name of w
        end repeat
        return windowTitles
    end tell
end tell
EOF

echo
echo "2. Teams notification center process:"
ps aux | grep -i "teams.*notification" | grep -v grep

echo
echo "3. Checking if window title contains channel info:"
osascript <<'EOF' 2>&1
tell application "System Events"
    tell process "Microsoft Teams"
        try
            set mainWindow to window 1
            set windowTitle to name of mainWindow
            
            # Parse window title for channel/chat info
            if windowTitle contains " | " then
                set AppleScript's text item delimiters to " | "
                set titleParts to text items of windowTitle
                
                if (count of titleParts) ≥ 2 then
                    return "Channel/Chat: " & item 1 of titleParts & ", Context: " & item 2 of titleParts
                else
                    return "Title: " & windowTitle
                end if
            else
                return "Title: " & windowTitle
            end if
        on error errMsg
            return "Error: " & errMsg
        end try
    end tell
end tell
EOF

echo
echo "4. Check for Teams badge in dock:"
osascript <<'EOF' 2>&1
tell application "System Events"
    tell process "Dock"
        try
            set dockItems to UI elements of list 1
            repeat with item in dockItems
                try
                    if name of item contains "Teams" then
                        # Try to get badge value
                        set itemProps to properties of item
                        return "Teams in dock: " & (itemProps as string)
                    end if
                end try
            end repeat
        on error errMsg
            return "Error checking dock: " & errMsg
        end try
    end tell
end tell
EOF

echo
echo "5. Monitor window title changes (5 second test):"
for i in {1..5}; do
    TITLE=$(osascript -e 'tell application "System Events" to tell process "Microsoft Teams" to name of window 1' 2>/dev/null)
    echo "  $i: $TITLE"
    sleep 1
done