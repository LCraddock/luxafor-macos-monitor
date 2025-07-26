tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        tell application "Axis Client" to activate
        delay 2
        
        tell window "Atmos Agent"
            -- Navigate the group hierarchy
            set results to "Exploring nested groups:" & return
            
            try
                -- Based on the output, we have deeply nested groups
                -- Let's navigate: group 1 -> group 1 -> group 1 -> group 1 -> UI element 1 -> group 1 -> group 1 -> group 2
                tell group 1
                    set results to results & "In group 1, found " & (count of UI elements) & " elements" & return
                    
                    tell group 1
                        set results to results & "In group 1/1, found " & (count of UI elements) & " elements" & return
                        
                        tell group 1
                            set results to results & "In group 1/1/1, found " & (count of UI elements) & " elements" & return
                            
                            tell group 1
                                set results to results & "In group 1/1/1/1, found " & (count of UI elements) & " elements" & return
                                
                                tell UI element 1
                                    set results to results & "In UI element 1, found " & (count of UI elements) & " elements" & return
                                    
                                    tell group 1
                                        set results to results & "In final group, found " & (count of UI elements) & " elements" & return
                                        
                                        -- Look for buttons here
                                        set allButtons to every button
                                        set results to results & "Buttons found: " & (count of allButtons) & return
                                        
                                        repeat with btn in allButtons
                                            try
                                                set btnDesc to description of btn
                                                set btnPos to position of btn
                                                set results to results & "Button: " & btnDesc & " at " & (btnPos as string) & return
                                                
                                                -- If this looks like hamburger menu position
                                                if (item 1 of btnPos) < 100 then
                                                    set results to results & "Found hamburger menu! Clicking..." & return
                                                    click btn
                                                    delay 2
                                                    
                                                    -- After clicking, look for Controls
                                                    set allTexts to every static text of window "Atmos Agent"
                                                    repeat with txt in allTexts
                                                        if value of txt contains "Controls" then
                                                            set results to results & "Found Controls! Clicking..." & return
                                                            click txt
                                                            delay 2
                                                            exit repeat
                                                        end if
                                                    end repeat
                                                end if
                                            end try
                                        end repeat
                                    end tell
                                end tell
                            end tell
                        end tell
                    end tell
                end tell
            on error errMsg
                set results to results & "Error: " & errMsg & return
            end try
            
            display dialog results buttons {"OK"} default button 1
        end tell
    end tell
end tell