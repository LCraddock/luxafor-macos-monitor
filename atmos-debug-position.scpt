tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        tell application "Axis Client" to activate
        delay 1
        
        -- Get window position
        set winPos to position of window "Atmos Agent"
        set winX to item 1 of winPos
        set winY to item 2 of winPos
        
        -- Show where we're clicking
        set debugInfo to "Window position: " & winX & ", " & winY & return
        set debugInfo to debugInfo & return & "Click positions:" & return
        set debugInfo to debugInfo & "Off button: " & (winX + 279) & ", " & (winY + 365) & return
        set debugInfo to debugInfo & return & "Make sure you're on the Controls page." & return
        set debugInfo to debugInfo & "The Off button should be visible in the Internet Protection section." & return
        set debugInfo to debugInfo & return & "Press OK to click the Off button..."
        
        display dialog debugInfo buttons {"OK", "Cancel"} default button 1
        
        if button returned of result is "OK" then
            -- Click the Off button
            click at {winX + 279, winY + 365}
            delay 2
            
            -- Now look for and click the Confirm button at bottom of page
            -- Confirm button should be near bottom, centered
            set confirmX to winX + 163  -- Half of 327 width
            set confirmY to winY + 650  -- Near bottom of 735 height window
            
            display dialog "Clicking Confirm at: " & confirmX & ", " & confirmY buttons {"OK"} default button 1
            click at {confirmX, confirmY}
        end if
    end tell
end tell