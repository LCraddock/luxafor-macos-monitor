tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        tell application "Axis Client" to activate
        delay 1
        
        -- Get window position for coordinate-based clicking
        set winPos to position of window "Atmos Agent"
        set winSize to size of window "Atmos Agent"
        
        -- Extract coordinates properly
        set winX to item 1 of winPos
        set winY to item 2 of winPos
        set winWidth to item 1 of winSize
        set winHeight to item 2 of winSize
        
        -- Show window info
        set windowInfo to "Window position: " & winX & ", " & winY & return
        set windowInfo to windowInfo & "Window size: " & winWidth & " x " & winHeight & return & return
        
        -- Calculate where we're clicking for the Off button
        set offButtonX to winX + (winWidth * 0.7)
        set offButtonY to winY + 350
        
        set windowInfo to windowInfo & "Off button click position: " & offButtonX & ", " & offButtonY & return
        set windowInfo to windowInfo & return & "The script will click at these coordinates." & return
        set windowInfo to windowInfo & "Adjust the multiplier (0.7) and Y offset (350) as needed."
        
        display dialog windowInfo buttons {"OK"} default button 1
    end tell
end tell