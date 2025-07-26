tell application "System Events"
    -- Activate Axis Client
    tell application "Axis Client" to activate
    delay 2
    
    -- Check if the window exists, if not, try to open it from menu bar
    tell process "Axis Client"
        if not (exists window "Atmos Agent") then
            -- Click the menu bar icon to open the window
            click menu bar item 1 of menu bar 2
            delay 2
        end if
    end tell
    
    -- Now use keyboard navigation
    tell process "Axis Client"
        set frontmost to true
        
        -- Press Tab to navigate through UI elements
        -- The hamburger menu should be one of the first elements
        repeat 3 times
            key code 48 -- Tab key
            delay 0.5
        end repeat
        
        -- Press Enter to open the hamburger menu
        key code 36 -- Return/Enter key
        delay 1
        
        -- Use arrow keys to navigate to Controls
        -- Down arrow twice (Home -> Debug Tools -> Controls)
        key code 125 -- Down arrow
        delay 0.5
        key code 125 -- Down arrow
        delay 0.5
        
        -- Press Enter to select Controls
        key code 36 -- Return/Enter key
        delay 2
        
        -- Now we should be on the Controls page
        -- Tab to navigate to Internet Protection Off button
        -- We need to skip past Private Access buttons first
        repeat 6 times -- Adjust this number as needed
            key code 48 -- Tab key
            delay 0.5
        end repeat
        
        -- Press Space or Enter to click the Off button
        key code 49 -- Space bar
        delay 1
        
        -- Handle confirmation if it appears
        -- Press Enter to confirm
        key code 36 -- Return/Enter key
    end tell
end tell