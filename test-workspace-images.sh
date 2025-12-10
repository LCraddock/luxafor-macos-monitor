#!/usr/bin/env bash

echo "Testing Slack workspace detection - Image approach..."
echo "---------------------------------------------------"

# Try to find workspace images and their badges
osascript <<'APPLESCRIPT'
tell application "System Events"
    tell process "Slack"
        try
            set output to "=== All Images in Slack Window ===\n"
            
            tell window 1
                -- Get all images
                set allImages to every image
                
                repeat with img in allImages
                    try
                        set imgDesc to description of img
                        set imgPos to position of img
                        set imgSize to size of img
                        
                        -- Focus on left sidebar area (x < 60)
                        if (item 1 of imgPos) < 60 then
                            set output to output & "Image: " & imgDesc & " at (" & (item 1 of imgPos) & "," & (item 2 of imgPos) & ") size: " & (item 1 of imgSize) & "x" & (item 2 of imgSize) & "\n"
                            
                            -- Check if this might be a workspace with badge
                            if imgDesc contains "workspace" or imgDesc contains "unread" or imgDesc contains "notification" then
                                set output to output & "  ^^ POSSIBLE WORKSPACE WITH BADGE!\n"
                            end if
                        end if
                    on error
                        -- Skip if can't access
                    end try
                end repeat
                
                set output to output & "\n=== Static Texts in Sidebar ===\n"
                
                -- Get all static texts (might show badge counts)
                set allTexts to every static text
                
                repeat with txt in allTexts
                    try
                        set txtValue to value of txt
                        set txtPos to position of txt
                        
                        -- Focus on left sidebar area
                        if (item 1 of txtPos) < 60 and txtValue is not "" then
                            -- Check if it's a number (badge count) or bullet
                            try
                                set numValue to txtValue as number
                                set output to output & "Badge count: " & txtValue & " at (" & (item 1 of txtPos) & "," & (item 2 of txtPos) & ")\n"
                            on error
                                if txtValue is "•" then
                                    set output to output & "Badge bullet: '" & txtValue & "' at (" & (item 1 of txtPos) & "," & (item 2 of txtPos) & ")\n"
                                end if
                            end try
                        end if
                    on error
                        -- Skip
                    end try
                end repeat
            end tell
            
            return output
            
        on error errMsg
            return "Error: " & errMsg
        end try
    end tell
end tell
APPLESCRIPT