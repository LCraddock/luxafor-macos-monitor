tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        tell application "Axis Client" to activate
        delay 1
        
        -- Make sure we're on Controls page
        display dialog "Please make sure you're on the Controls page, then click OK" buttons {"OK"} default button 1
        
        -- Get window info
        set winPos to position of window "Atmos Agent"
        set winX to item 1 of winPos
        set winY to item 2 of winPos
        
        -- Move mouse to show where we'll click (requires mouse control)
        do shell script "echo 'Moving mouse to show click positions...'"
        
        -- Show Off button position
        display dialog "Mouse will move to Off button position..." buttons {"OK"} default button 1
        
        -- Use cliclick if available, otherwise just click
        try
            do shell script "/usr/local/bin/cliclick m:" & (winX + 279) & "," & (winY + 365)
        on error
            -- Just click if cliclick not available
            click at {winX + 279, winY + 365}
        end try
        
        delay 1
        
        display dialog "Did the mouse/click hit the Off button?" buttons {"Yes", "No"} default button 1
        
        if button returned of result is "Yes" then
            display dialog "Great! The coordinates are correct." buttons {"OK"} default button 1
        else
            display dialog "The Off button might be at a different position. Try adjusting the coordinates." buttons {"OK"} default button 1
        end if
    end tell
end tell