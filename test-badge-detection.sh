#!/usr/bin/env bash

echo "Testing badge detection at known position..."

osascript <<'APPLESCRIPT'
tell application "System Events"
    tell process "Slack"
        try
            tell window 1
                set output to "=== Looking for badge elements ===\n"
                
                -- Check all static texts
                set allTexts to every static text
                set textCount to count of allTexts
                set output to output & "Found " & textCount & " static text elements\n\n"
                
                repeat with txt in allTexts
                    try
                        set txtValue to value of txt
                        set txtPos to position of txt
                        
                        -- Only show texts that might be badges (numbers or bullets)
                        try
                            set numValue to txtValue as number
                            set output to output & "Number badge '" & txtValue & "' at (" & (item 1 of txtPos) & "," & (item 2 of txtPos) & ")\n"
                        on error
                            if txtValue is "•" or txtValue is "·" or txtValue contains "1" or txtValue contains "2" then
                                set output to output & "Possible badge '" & txtValue & "' at (" & (item 1 of txtPos) & "," & (item 2 of txtPos) & ")\n"
                            end if
                        end try
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