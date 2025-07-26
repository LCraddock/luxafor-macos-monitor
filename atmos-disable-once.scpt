tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        delay 1
        
        -- Click hamburger menu to open slide-out panel
        click button 1 of window "Atmos Agent"
        delay 1
        
        -- Click Controls in the slide-out panel
        try
            click static text "Controls" of window "Atmos Agent"
        on error
            click group 3 of window "Atmos Agent"
        end try
        delay 2
        
        -- Now click the Off button for Internet Protection
        -- Based on the screenshot, we need the second Off button
        set offButtonCount to 0
        set allButtons to every button of window "Atmos Agent"
        repeat with btn in allButtons
            if name of btn is "Off" then
                set offButtonCount to offButtonCount + 1
                if offButtonCount is 2 then
                    -- This is the Internet Protection Off button
                    click btn
                    exit repeat
                end if
            end if
        end repeat
        
        delay 1
        
        -- Handle the confirmation dialog
        if exists (button "Confirm" of window "Atmos Agent") then
            click button "Confirm" of window "Atmos Agent"
        end if
    end tell
end tell