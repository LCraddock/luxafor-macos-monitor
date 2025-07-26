tell application "System Events"
    tell process "Axis Client"
        -- Activate and make sure window is visible
        set frontmost to true
        delay 1
        
        -- Check if window exists
        if not (exists window "Atmos Agent") then
            display dialog "Atmos Agent window not found. Please make sure it's open."
            return
        end if
        
        -- Get initial window info
        set windowName to name of window 1
        display dialog "Found window: " & windowName
        
        -- List all buttons in the window
        try
            set allButtons to name of every button of window 1
            display dialog "Main window buttons: " & (allButtons as string)
        on error
            display dialog "No buttons found in main window"
        end try
        
        -- Now try to find and click the hamburger menu
        -- It might be button 1, 2, or 3
        repeat with btnNum from 1 to 3
            try
                display dialog "Trying to click button " & btnNum
                click button btnNum of window 1
                delay 2
                
                -- Check if a menu appeared
                if exists menu 1 of button btnNum of window 1 then
                    set menuItems to name of every menu item of menu 1 of button btnNum of window 1
                    display dialog "Found menu items: " & (menuItems as string)
                    
                    -- Click Controls if found
                    if "Controls" is in menuItems then
                        click menu item "Controls" of menu 1 of button btnNum of window 1
                        delay 2
                        display dialog "Clicked Controls. Check if the window changed."
                        exit repeat
                    end if
                end if
            on error errMsg
                display dialog "Button " & btnNum & " error: " & errMsg
            end try
        end repeat
    end tell
end tell