#!/usr/bin/env bash

echo "Testing Slack workspace badge detection..."
echo "----------------------------------------"

# Test function to check workspace badges using coordinates
test_workspace_badges() {
    osascript <<'APPLESCRIPT' 2>/dev/null
tell application "System Events"
    tell process "Slack"
        try
            set workspaceInfo to {}
            
            -- Get all UI elements in the window
            tell window 1
                -- Try to find elements at specific positions
                -- UKG workspace area (around 10,75 to 44,114)
                set allElements to entire contents
                
                repeat with elem in allElements
                    try
                        set elemPos to position of elem
                        set elemSize to size of elem
                        set elemDesc to description of elem
                        set elemRole to role of elem
                        
                        -- Check if this element is in the sidebar area (x < 50)
                        if (item 1 of elemPos) < 50 then
                            -- Check for badges or unread indicators
                            if elemDesc contains "unread" or elemDesc contains "mention" or elemDesc contains "notification" then
                                set end of workspaceInfo to "Found badge: " & elemDesc & " at " & (item 1 of elemPos as string) & "," & (item 2 of elemPos as string)
                            end if
                            
                            -- Also check static texts and images in sidebar
                            if elemRole is "AXStaticText" or elemRole is "AXImage" then
                                set elemValue to value of elem
                                if elemValue is not missing value and elemValue is not "" then
                                    -- Check if it looks like a badge (number or dot)
                                    if elemValue is "•" or (elemValue as string) matches "[0-9]+" then
                                        set end of workspaceInfo to "Badge indicator: " & elemValue & " at " & (item 1 of elemPos as string) & "," & (item 2 of elemPos as string)
                                    end if
                                end if
                            end if
                        end if
                    on error
                        -- Skip elements we can't access
                    end try
                end repeat
            end tell
            
            if (count of workspaceInfo) > 0 then
                set AppleScript's text item delimiters to "; "
                return workspaceInfo as string
            else
                return "No badges found in sidebar"
            end if
            
        on error errMsg
            return "Error: " & errMsg
        end try
    end tell
end tell
APPLESCRIPT
}

# Test simpler approach - just get button names in sidebar
test_sidebar_buttons() {
    osascript <<'APPLESCRIPT' 2>/dev/null
tell application "System Events"
    tell process "Slack"
        try
            set buttonInfo to {}
            
            -- Look for all buttons in the window
            tell window 1
                set allButtons to every button
                
                repeat with btn in allButtons
                    try
                        set btnName to name of btn
                        set btnDesc to description of btn
                        set btnPos to position of btn
                        
                        -- Check if button is in left sidebar (x < 50)
                        if (item 1 of btnPos) < 50 and (item 2 of btnPos) < 250 then
                            set btnInfo to btnInfo & "Button: " & btnName & " | Desc: " & btnDesc & " | Pos: " & (item 1 of btnPos as string) & "," & (item 2 of btnPos as string) & "\n"
                        end if
                    on error
                        -- Skip inaccessible buttons
                    end try
                end repeat
            end tell
            
            if btnInfo is "" then
                return "No buttons found in sidebar area"
            else
                return btnInfo
            end if
            
        on error errMsg
            return "Error: " & errMsg
        end try
    end tell
end tell
APPLESCRIPT
}

echo "Test 1: Looking for badges in sidebar..."
result=$(test_workspace_badges)
echo "$result"
echo ""

echo "Test 2: Listing all buttons in sidebar area..."
result=$(test_sidebar_buttons)
echo "$result"
echo ""

echo "Test 3: Checking specific workspace areas..."
# Check each workspace area you identified
for workspace in "UKG:10,75:44,114" "Craddock:10,128:44,163" "CS_Alumni:10,182:44,213"; do
    IFS=':' read -r name topleft bottomright <<< "$workspace"
    echo "Checking $name area ($topleft to $bottomright)..."
done

echo ""
echo "Done. If you see badges/notifications on any workspace, compare with the output above."