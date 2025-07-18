#!/usr/bin/env bash
#
# test-slack-detection.sh
# Test script to explore Slack window title formats
#

echo "=== Testing Slack Detection Methods ==="
echo

# Check if Slack is running
echo "1. Checking for Slack process..."
ps aux | grep -i "[S]lack" | grep -v Helper

echo
echo "2. Getting Slack window title..."
osascript <<'EOF' 2>&1
tell application "System Events"
    if exists process "Slack" then
        tell process "Slack"
            set windowTitle to name of front window
            return "Window: " & windowTitle
        end tell
    else
        return "Slack is not running"
    end if
end tell
EOF

echo
echo "3. Getting all Slack windows..."
osascript <<'EOF' 2>&1
tell application "System Events"
    if exists process "Slack" then
        tell process "Slack"
            set windowNames to name of every window
            return "Windows: " & (windowNames as string)
        end tell
    else
        return "Slack is not running"
    end if
end tell
EOF

echo
echo "4. Interactive test - capture current window..."
echo "Navigate to different Slack areas and press Enter to capture:"
echo "- A channel (like #general)"
echo "- A direct message"
echo "- The threads view"
echo

while true; do
    echo -n "Press Enter to capture current window (or 'quit'): "
    read input
    
    if [[ "$input" == "quit" ]]; then
        break
    fi
    
    WINDOW_TITLE=$(osascript -e 'tell application "System Events" to tell process "Slack" to name of front window' 2>/dev/null)
    echo "   Title: $WINDOW_TITLE"
    
    # Try to parse the title
    if [[ "$WINDOW_TITLE" == *" - "* ]]; then
        # Extract parts before/after delimiter
        FIRST_PART="${WINDOW_TITLE%% - *}"
        REMAINING="${WINDOW_TITLE#* - }"
        echo "   First part: '$FIRST_PART'"
        echo "   Remaining: '$REMAINING'"
    fi
    echo
done