tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        tell application "Axis Client" to activate
        delay 1
        
        -- Try multiple methods to ensure window is open
        if not (exists window "Atmos Agent") then
            -- Method 1: Click dock icon
            try
                tell application "System Events" to tell process "Dock"
                    click UI element "Axis Client" of list 1
                end tell
                delay 2
            end try
            
            -- Method 2: Try menu bar again with different approach
            if not (exists window "Atmos Agent") then
                try
                    -- Look for the Axis menu bar item
                    repeat with i from 1 to count of menu bar items of menu bar 2
                        set menuBarItem to menu bar item i of menu bar 2
                        try
                            if title of menuBarItem contains "Axis" or title of menuBarItem contains "Atmos" then
                                click menuBarItem
                                delay 2
                                exit repeat
                            end if
                        end try
                    end repeat
                end try
            end if
            
            -- Method 3: Use keyboard shortcut if available
            if not (exists window "Atmos Agent") then
                -- Try Cmd+1 or other shortcuts that might open the window
                keystroke "1" using command down
                delay 1
            end if
        end if
        
        -- Check if window is now open
        if exists window "Atmos Agent" then
            display dialog "Window is open!"
        else
            display dialog "Could not open window. Please open Atmos Agent manually."
        end if
    end tell
end tell