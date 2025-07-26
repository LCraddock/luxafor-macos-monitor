tell application "System Events"
    -- Activate Axis Client first
    tell application "Axis Client" to activate
    delay 2
    
    tell process "Axis Client"
        -- Try using the application menu bar instead of the hamburger menu
        -- Click on View menu or Window menu
        try
            click menu bar item "View" of menu bar 1
            delay 0.5
            
            -- Look for Controls in the menu
            if exists menu item "Controls" of menu 1 of menu bar item "View" of menu bar 1 then
                click menu item "Controls" of menu 1 of menu bar item "View" of menu bar 1
            else
                -- Cancel this menu
                key code 53 -- Escape
                
                -- Try Window menu
                click menu bar item "Window" of menu bar 1
                delay 0.5
                if exists menu item "Controls" of menu 1 of menu bar item "Window" of menu bar 1 then
                    click menu item "Controls" of menu 1 of menu bar item "Window" of menu bar 1
                end if
            end if
        on error
            display dialog "Could not find Controls in menu bar"
        end try
    end tell
end tell