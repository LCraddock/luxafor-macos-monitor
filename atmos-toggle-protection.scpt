tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        tell application "Axis Client" to activate
        delay 1
        
        -- First ensure the window is open
        if not (exists window "Atmos Agent") then
            -- Click menu bar icon to open window
            click menu bar item 1 of menu bar 2
            delay 2
        end if
        
        -- Get window position for coordinate-based clicking
        set winPos to position of window "Atmos Agent"
        set winSize to size of window "Atmos Agent"
        
        -- Extract coordinates properly
        set winX to item 1 of winPos
        set winY to item 2 of winPos
        set winWidth to item 1 of winSize
        set winHeight to item 2 of winSize
        
        -- Click hamburger menu (top-left corner, about 20px in, 50px down)
        set hamburgerX to winX + 20
        set hamburgerY to winY + 50
        click at {hamburgerX, hamburgerY}
        delay 2
        
        -- Click Controls in slide-out menu (3rd item down)
        -- Home is around 150px, Debug Tools around 200px, Controls around 250px from top
        set controlsX to winX + 100
        set controlsY to winY + 250
        click at {controlsX, controlsY}
        delay 2
        
        -- First click ON button to reset the timer
        -- Exact coordinates: 88px from left, 401px from top of window
        set onButtonX to winX + 88
        set onButtonY to winY + 401
        click at {onButtonX, onButtonY}
        delay 2
        
        -- Click Confirm button for ON
        -- Exact coordinates: 164px from left, 679px from top of window
        set confirmX to winX + 164
        set confirmY to winY + 679
        click at {confirmX, confirmY}
        delay 2
        
        -- Now click OFF button to disable for 60 minutes
        -- Exact coordinates: 236px from left, 399px from top of window
        set offButtonX to winX + 236
        set offButtonY to winY + 399
        click at {offButtonX, offButtonY}
        delay 2
        
        -- Click Confirm button for OFF
        click at {confirmX, confirmY}
        delay 1
        
        -- Minimize the window when done
        tell window "Atmos Agent"
            set value of attribute "AXMinimized" to true
        end tell
    end tell
end tell