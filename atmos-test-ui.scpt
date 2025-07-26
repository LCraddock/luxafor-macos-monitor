tell application "System Events"
    tell process "Atmos Agent"
        set frontmost to true
        delay 1
        
        -- Click hamburger menu
        click button 1 of window "Atmos Agent"
        delay 1
        
        -- Click Controls menu item
        click menu item "Controls" of menu 1 of button 1 of window "Atmos Agent"
        delay 2
        
        -- List all UI elements to find the correct groups
        set allElements to every UI element of window "Atmos Agent"
        set elementCount to count of allElements
        
        repeat with i from 1 to elementCount
            try
                set elementInfo to (class of item i of allElements as string) & " " & i
                if class of item i of allElements is group then
                    set groupButtons to every button of item i of allElements
                    if (count of groupButtons) > 0 then
                        set buttonNames to {}
                        repeat with btn in groupButtons
                            set end of buttonNames to (name of btn as string)
                        end repeat
                        display dialog "Group " & i & " buttons: " & (buttonNames as string)
                    end if
                end if
            end try
        end repeat
    end tell
end tell