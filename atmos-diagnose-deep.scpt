tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        tell application "Axis Client" to activate
        delay 1
        
        -- Get all UI elements of the window
        tell window "Atmos Agent"
            set allElements to entire contents
            set elementInfo to "Total elements: " & (count of allElements) & return & return
            
            -- Look for specific UI element types
            set elementInfo to elementInfo & "UI Element types found:" & return
            
            -- Check for scroll areas (common container)
            try
                set scrollAreas to every scroll area
                set elementInfo to elementInfo & "Scroll areas: " & (count of scrollAreas) & return
                if (count of scrollAreas) > 0 then
                    -- Check contents of first scroll area
                    tell scroll area 1
                        set saButtons to count of buttons
                        set saGroups to count of groups
                        set saTexts to count of static texts
                        set elementInfo to elementInfo & "  In scroll area 1: " & saButtons & " buttons, " & saGroups & " groups, " & saTexts & " texts" & return
                    end tell
                end if
            end try
            
            -- Check for toolbars
            try
                set toolbars to every toolbar
                set elementInfo to elementInfo & "Toolbars: " & (count of toolbars) & return
            end try
            
            -- Check for groups at different levels
            set elementInfo to elementInfo & return & "Group hierarchy:" & return
            set allGroups to every group
            repeat with i from 1 to count of allGroups
                set grp to item i of allGroups
                set elementInfo to elementInfo & "Group " & i & ":" & return
                tell grp
                    try
                        -- Check for nested groups
                        set nestedGroups to every group
                        set elementInfo to elementInfo & "  Nested groups: " & (count of nestedGroups) & return
                        
                        -- Check for buttons in this group
                        set grpButtons to every button
                        if (count of grpButtons) > 0 then
                            set elementInfo to elementInfo & "  Buttons in group:" & return
                            repeat with btn in grpButtons
                                try
                                    set btnDesc to description of btn
                                    set elementInfo to elementInfo & "    - " & btnDesc & return
                                end try
                            end repeat
                        end if
                    end try
                end tell
            end repeat
            
            -- Try to find hamburger menu by exploring all buttons
            set elementInfo to elementInfo & return & "Looking for hamburger menu:" & return
            set allUIElements to every UI element
            repeat with elem in allUIElements
                try
                    set elemClass to class of elem as string
                    if elemClass contains "button" then
                        set elemPos to position of elem
                        set elemSize to size of elem
                        set elemDesc to description of elem
                        -- Check if it's in the top-left area (not a window control button)
                        if (item 1 of elemPos) < 100 and (item 2 of elemPos) < 100 and elemDesc does not contain "button" then
                            set elementInfo to elementInfo & "Found potential hamburger at: " & (elemPos as string) & " size: " & (elemSize as string) & return
                        end if
                    end if
                end try
            end repeat
            
            display dialog elementInfo buttons {"OK"} default button 1
        end tell
    end tell
end tell