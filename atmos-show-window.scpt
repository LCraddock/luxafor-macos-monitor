tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        delay 1
        
        -- Try to show window via menu
        try
            click menu item "Show Atmos Agent" of menu 1 of menu bar item "Axis Client" of menu bar 1
        on error
            -- Try different menu names
            try
                set menuNames to name of every menu bar item of menu bar 1
                display dialog "Menu bar items: " & (menuNames as string)
            end try
        end try
        
        -- Check if window exists now
        delay 1
        if exists window 1 then
            display dialog "Window found: " & (name of window 1)
        else
            display dialog "No window found. Try clicking the menu bar or dock icon manually."
        end if
    end tell
end tell