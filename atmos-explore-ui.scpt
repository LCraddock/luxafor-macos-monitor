tell application "System Events"
    tell process "Axis Client"
        -- Activate and make sure window is visible
        set frontmost to true
        delay 1
        
        -- Check all UI elements
        set allElements to every UI element of window 1
        set elementInfo to ""
        
        repeat with elem in allElements
            try
                set elemClass to class of elem as string
                set elementInfo to elementInfo & elemClass & ", "
            end try
        end repeat
        
        display dialog "UI Elements: " & elementInfo
        
        -- Check for toolbar or menu bar
        try
            if exists toolbar 1 of window 1 then
                display dialog "Found toolbar!"
                set toolbarButtons to every button of toolbar 1 of window 1
                display dialog "Toolbar has " & (count of toolbarButtons) & " buttons"
            end if
        end try
        
        -- Check for menu bar
        try
            if exists menu bar 1 then
                set menus to name of every menu of menu bar 1
                display dialog "Menu bar items: " & (menus as string)
            end if
        end try
        
        -- Try clicking and immediately checking for popover or sheet
        set frontmost to true
        delay 1
        
        click button 1 of window 1
        delay 0.5
        
        -- Check for popover window
        if (count of windows) > 1 then
            display dialog "New window appeared! Count: " & (count of windows)
            set secondWindow to window 2
            display dialog "Second window name: " & (name of secondWindow)
        end if
        
        -- Check for sheet
        try
            if exists sheet 1 of window 1 then
                display dialog "Found a sheet!"
            end if
        end try
        
        -- Check for popover
        try
            if exists popover 1 of window 1 then
                display dialog "Found a popover!"
            end if
        end try
    end tell
end tell