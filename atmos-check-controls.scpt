tell application "System Events"
    tell process "Axis Client"
        -- First, let's make sure we can activate the window
        set frontmost to true
        tell application "Axis Client" to activate
        delay 2
        
        -- Check if window exists
        if not (exists window "Atmos Agent") then
            display dialog "Window not found. Opening from menu bar..."
            -- Try to click menu bar icon
            click menu bar item 1 of menu bar 2
            delay 1
        end if
        
        -- Now let's carefully test the hamburger menu
        if exists window "Atmos Agent" then
            display dialog "Window found. Current window count: " & (count of windows)
            
            -- Click and check what happens
            click button 1 of window "Atmos Agent"
            delay 1
            
            -- Check if we now have a sheet or different window
            set windowList to name of every window
            display dialog "Windows after click: " & (windowList as string)
            
            -- Check for UI elements that might have appeared
            if exists group 1 of window "Atmos Agent" then
                set groupCount to count of groups of window "Atmos Agent"
                display dialog "Found " & groupCount & " groups. Looking for Controls..."
                
                -- Try to find Controls by checking static text in groups
                repeat with i from 1 to groupCount
                    try
                        set textList to {}
                        set allTexts to every static text of group i of window "Atmos Agent"
                        repeat with txt in allTexts
                            try
                                set txtValue to value of txt as string
                                set end of textList to txtValue
                                if txtValue contains "Controls" then
                                    display dialog "Found Controls in group " & i & ": " & txtValue
                                    click group i of window "Atmos Agent"
                                    delay 2
                                    
                                    -- Now look for Internet Protection buttons
                                    display dialog "Looking for Off buttons on Controls page..."
                                    set allButtons to every button of window "Atmos Agent"
                                    set buttonInfo to "Buttons found: "
                                    repeat with btn in allButtons
                                        try
                                            set btnName to name of btn
                                            set buttonInfo to buttonInfo & btnName & ", "
                                        end try
                                    end repeat
                                    display dialog buttonInfo
                                    
                                    exit repeat
                                end if
                            end try
                        end repeat
                    end try
                end repeat
            end if
        end if
    end tell
end tell