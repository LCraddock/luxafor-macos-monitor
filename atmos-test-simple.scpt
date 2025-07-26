tell application "System Events"
    -- Check if Atmos Agent is running
    if not (exists process "Atmos Agent") then
        display dialog "Atmos Agent is not running. Please start it first."
        return
    end if
    
    tell process "Atmos Agent"
        -- Activate the app
        tell application "Atmos Agent" to activate
        delay 2
        
        -- Get window info
        set windowCount to count of windows
        display dialog "Atmos Agent has " & windowCount & " window(s)"
        
        if windowCount > 0 then
            -- Try to click hamburger menu (usually button 1)
            try
                set buttonCount to count of buttons of window 1
                display dialog "Window 1 has " & buttonCount & " button(s)"
                
                -- Click first button (hamburger menu)
                click button 1 of window 1
                delay 1
                
                -- Check for menu
                if exists menu 1 of button 1 of window 1 then
                    set menuItems to name of every menu item of menu 1 of button 1 of window 1
                    display dialog "Menu items: " & (menuItems as string)
                end if
            on error errMsg
                display dialog "Error: " & errMsg
            end try
        end if
    end tell
end tell