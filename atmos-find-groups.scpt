tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        delay 1
        
        -- Click hamburger menu
        click button 1 of window "Atmos Agent"
        delay 1
        
        -- Click Controls menu item
        click menu item "Controls" of menu 1 of button 1 of window "Atmos Agent"
        delay 2
        
        -- Count groups
        set groupCount to count of groups of window "Atmos Agent"
        display dialog "Found " & groupCount & " groups in the window"
        
        -- Check each group for buttons
        repeat with i from 1 to groupCount
            try
                set buttonList to name of every button of group i of window "Atmos Agent"
                set buttonText to ""
                repeat with btnName in buttonList
                    set buttonText to buttonText & btnName & ", "
                end repeat
                display dialog "Group " & i & " buttons: " & buttonText
            on error
                -- No buttons in this group
            end try
        end repeat
    end tell
end tell