#!/usr/bin/env bash
#
# test-teams-detection.sh
# Test script to explore Teams channel detection methods
#

echo "=== Testing Teams Detection Methods ==="
echo

# Method 1: Check if Teams has AppleScript support
echo "1. Checking AppleScript dictionary for Teams..."
osascript -e 'tell application "System Events" to get name of every process whose name contains "Teams"' 2>&1

echo
echo "2. Attempting to get Teams window information..."
osascript <<'EOF' 2>&1
tell application "System Events"
    tell process "Microsoft Teams"
        try
            set windowNames to name of every window
            return windowNames
        on error errMsg
            return "Error: " & errMsg
        end try
    end tell
end tell
EOF

echo
echo "3. Checking Teams UI elements..."
osascript <<'EOF' 2>&1
tell application "System Events"
    tell process "Microsoft Teams"
        try
            tell window 1
                set allElements to entire contents
                return (count of allElements) & " UI elements found"
            end tell
        on error errMsg
            return "Error: " & errMsg
        end try
    end tell
end tell
EOF

echo
echo "4. Looking for notification-related elements..."
osascript <<'EOF' 2>&1
tell application "System Events"
    tell process "Microsoft Teams"
        try
            # Look for common notification indicators
            set badges to every UI element whose role is "AXStaticText" and value contains "unread"
            return "Found " & (count of badges) & " unread indicators"
        on error errMsg
            return "Error: " & errMsg
        end try
    end tell
end tell
EOF

echo
echo "5. Checking Teams accessibility permissions..."
osascript -e 'tell application "System Events" to get properties of process "Microsoft Teams"' 2>&1 | head -5

echo
echo "=== End of Tests ==="