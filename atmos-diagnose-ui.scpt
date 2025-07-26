tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        tell application "Axis Client" to activate
        delay 1
        
        -- Check if window exists
        if not (exists window "Atmos Agent") then
            return "No window found. Opening from menu bar..."
            click menu bar item 1 of menu bar 2
            delay 2
        end if
        
        -- Get detailed info about the window
        tell window "Atmos Agent"
            set windowInfo to "Window exists: yes" & return
            
            -- Count UI elements
            set buttonCount to count of buttons
            set groupCount to count of groups
            set staticTextCount to count of static texts
            
            set windowInfo to windowInfo & "Buttons: " & buttonCount & return
            set windowInfo to windowInfo & "Groups: " & groupCount & return
            set windowInfo to windowInfo & "Static texts: " & staticTextCount & return & return
            
            -- Get info about each group
            repeat with i from 1 to groupCount
                try
                    set groupInfo to "Group " & i & ": "
                    set groupButtons to count of buttons of group i
                    set groupTexts to count of static texts of group i
                    set groupInfo to groupInfo & groupButtons & " buttons, " & groupTexts & " texts"
                    set windowInfo to windowInfo & groupInfo & return
                    
                    -- List buttons in this group
                    if groupButtons > 0 then
                        repeat with j from 1 to groupButtons
                            try
                                set btnDesc to description of button j of group i
                                set windowInfo to windowInfo & "  - Button " & j & ": " & btnDesc & return
                            end try
                        end repeat
                    end if
                end try
            end repeat
            
            -- Get info about all buttons (not in groups)
            set windowInfo to windowInfo & return & "All buttons:" & return
            repeat with i from 1 to buttonCount
                try
                    set btnDesc to description of button i
                    set btnName to ""
                    try
                        set btnName to name of button i
                    end try
                    set windowInfo to windowInfo & "Button " & i & ": " & btnDesc & " (name: " & btnName & ")" & return
                end try
            end repeat
            
            display dialog windowInfo buttons {"OK"} default button 1
        end tell
    end tell
end tell