tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        tell application "Axis Client" to activate
        delay 2
        
        -- Check if window exists
        if not (exists window "Atmos Agent") then
            display dialog "Window not found"
            return
        end if
        
        tell window "Atmos Agent"
            -- Get window info
            set windowInfo to "Window info:" & return
            set windowInfo to windowInfo & "Title: " & (get title) & return
            set windowInfo to windowInfo & "Position: " & (position as string) & return
            set windowInfo to windowInfo & "Size: " & (size as string) & return & return
            
            -- Try to get all UI elements using different methods
            set windowInfo to windowInfo & "Direct UI elements:" & return
            set directElements to UI elements
            repeat with elem in directElements
                try
                    set elemClass to class of elem as string
                    set elemRole to role of elem as string
                    set elemDesc to description of elem as string
                    set windowInfo to windowInfo & "- " & elemClass & " (role: " & elemRole & ", desc: " & elemDesc & ")" & return
                end try
            end repeat
            
            -- Check for web view or other special containers
            set windowInfo to windowInfo & return & "Checking for special containers:" & return
            
            -- Look for web areas (common in Electron apps)
            try
                set webAreas to every UI element whose role is "AXWebArea"
                set windowInfo to windowInfo & "Web areas: " & (count of webAreas) & return
            end try
            
            -- Look for groups with specific roles
            try
                set groups to every group
                set windowInfo to windowInfo & "Groups found: " & (count of groups) & return
                repeat with grp in groups
                    try
                        set grpRole to role of grp
                        set grpDesc to description of grp
                        set windowInfo to windowInfo & "  - Group role: " & grpRole & ", desc: " & grpDesc & return
                        
                        -- Check group contents
                        tell grp
                            set grpElements to UI elements
                            set windowInfo to windowInfo & "    Contains " & (count of grpElements) & " elements" & return
                        end tell
                    end try
                end repeat
            end try
            
            -- Try to interact with the window content area
            set windowInfo to windowInfo & return & "Attempting to click in content area..." & return
            try
                -- Click in the area where hamburger menu should be (avoiding title bar)
                click at {30, 60}
                delay 1
                
                -- Check if any new elements appeared
                set newElements to UI elements
                set windowInfo to windowInfo & "Elements after click: " & (count of newElements) & return
            end try
            
            display dialog windowInfo buttons {"OK"} default button 1
        end tell
    end tell
end tell