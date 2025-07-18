#!/usr/bin/env bash
#
# test-teams-ui-structure.sh
# Explore Teams UI structure for channel detection
#

echo "=== Exploring Teams UI Structure ==="
echo

# Get detailed window structure
osascript <<'EOF' 2>&1
tell application "System Events"
    tell process "Microsoft Teams"
        try
            tell window 1
                # Get all static text elements
                set textElements to every static text
                set textList to {}
                repeat with elem in textElements
                    try
                        set elemValue to value of elem
                        if elemValue is not "" and elemValue is not missing value then
                            set end of textList to elemValue
                        end if
                    end try
                end repeat
                
                # Return first 20 text elements
                set outputList to {}
                repeat with i from 1 to (minimum of 20 and count of textList)
                    set end of outputList to (i as string) & ": " & item i of textList
                end repeat
                
                return outputList as string
            end tell
        on error errMsg
            return "Error: " & errMsg
        end try
    end tell
end tell
EOF

echo
echo "=== Looking for channel/chat indicators ==="
osascript <<'EOF' 2>&1
tell application "System Events"
    tell process "Microsoft Teams"
        try
            # Look for list items (channels/chats often in lists)
            set listItems to name of every menu item of menu 1 of menu bar 1
            return "Menu items: " & (listItems as string)
        on error
            # Try different approach
            try
                tell window 1
                    set groups to every group
                    return "Found " & (count of groups) & " groups in window"
                end tell
            on error errMsg2
                return "Error: " & errMsg2
            end try
        end try
    end tell
end tell
EOF

echo
echo "=== Checking for notification badges in UI ==="
osascript <<'EOF' 2>&1
tell application "System Events"
    tell process "Microsoft Teams"
        try
            tell window 1
                # Look for any UI elements that might contain badge counts
                set allTexts to value of every static text
                set badgeTexts to {}
                
                repeat with txt in allTexts
                    try
                        if txt is not missing value and txt is not "" then
                            # Check if text looks like a number (potential badge)
                            try
                                set numValue to txt as number
                                if numValue > 0 and numValue < 100 then
                                    set end of badgeTexts to txt
                                end if
                            end try
                        end if
                    end try
                end repeat
                
                if (count of badgeTexts) > 0 then
                    return "Potential badges found: " & (badgeTexts as string)
                else
                    return "No numeric badges found"
                end if
            end tell
        on error errMsg
            return "Error: " & errMsg
        end try
    end tell
end tell
EOF