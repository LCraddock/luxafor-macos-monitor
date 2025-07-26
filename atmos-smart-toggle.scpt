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
        set controlsX to winX + 100
        set controlsY to winY + 250
        click at {controlsX, controlsY}
        delay 2
        
        -- Set button coordinates
        set onButtonX to winX + 88
        set onButtonY to winY + 401
        set offButtonX to winX + 236
        set offButtonY to winY + 399
        set confirmX to winX + 164
        set confirmY to winY + 679
        
        -- Try clicking OFF first (in case protection is currently ON)
        click at {offButtonX, offButtonY}
        delay 1
        
        -- Check if Confirm button appeared by looking for UI changes
        -- If it did, click it. If not, we need to do the full sequence
        set needsFullSequence to false
        
        try
            -- Try to click confirm
            click at {confirmX, confirmY}
            delay 1
            
            -- Check if we're back at Controls page (no confirm dialog)
            -- If confirm worked, we're done. If not, window might have confirm dialog still
            -- Try clicking in a neutral area to see if dialog is still there
            click at {winX + 50, winY + 300}
            delay 0.5
            
        on error
            set needsFullSequence to true
        end try
        
        -- If the OFF button was already disabled (protection was already OFF),
        -- we need to do the full sequence: ON -> Confirm -> OFF -> Confirm
        -- We'll detect this by trying to click OFF again
        click at {offButtonX, offButtonY}
        delay 1
        
        -- Look for confirm button area change
        click at {confirmX, confirmY}
        delay 0.5
        
        -- If nothing happened, do the full sequence
        if needsFullSequence or (not (exists window "Atmos Agent")) then
            -- Reopen window if needed
            if not (exists window "Atmos Agent") then
                click menu bar item 1 of menu bar 2
                delay 2
                click at {hamburgerX, hamburgerY}
                delay 2
                click at {controlsX, controlsY}
                delay 2
            end if
            
            -- Full sequence: ON -> Confirm -> OFF -> Confirm
            click at {onButtonX, onButtonY}
            delay 2
            click at {confirmX, confirmY}
            delay 2
            click at {offButtonX, offButtonY}
            delay 2
            click at {confirmX, confirmY}
        end if
    end tell
end tell