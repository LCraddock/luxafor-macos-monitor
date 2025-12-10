#!/usr/bin/env bash

echo "Getting Slack window position and workspace elements..."

osascript <<'APPLESCRIPT'
tell application "System Events"
    tell process "Slack"
        try
            tell window 1
                set winPos to position
                set winSize to size
                
                set output to "Window position: (" & (item 1 of winPos) & "," & (item 2 of winPos) & ")\n"
                set output to output & "Window size: " & (item 1 of winSize) & "x" & (item 2 of winSize) & "\n\n"
                
                -- Your workspace screen coordinates:
                -- UKG: 10,75 to 44,114
                -- Craddock: 10,128 to 44,163  
                -- CS Alumni: 10,182 to 44,213
                
                -- Convert to window-relative (subtract window position)
                set winX to item 1 of winPos
                set winY to item 2 of winPos
                
                set output to output & "Workspace areas (window-relative):\n"
                set output to output & "UKG: (" & (10 - winX) & "," & (75 - winY) & ")\n"
                set output to output & "Craddock: (" & (10 - winX) & "," & (128 - winY) & ")\n"
                set output to output & "CS Alumni: (" & (10 - winX) & "," & (182 - winY) & ")\n\n"
                
                -- Look for images (workspace icons) near those positions
                set output to output & "=== Images found ===\n"
                set allImages to every image
                
                repeat with img in allImages
                    try
                        set imgPos to position of img
                        set imgDesc to description of img
                        -- Check if in sidebar area (assuming sidebar is on left)
                        if (item 1 of imgPos) < 100 then
                            set output to output & "Image at (" & (item 1 of imgPos) & "," & (item 2 of imgPos) & "): " & imgDesc & "\n"
                        end if
                    on error
                        -- Skip
                    end try
                end repeat
                
                return output
            end tell
        on error errMsg
            return "Error: " & errMsg
        end try
    end tell
end tell
APPLESCRIPT