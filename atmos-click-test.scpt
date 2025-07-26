tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        tell application "Axis Client" to activate
        delay 2
        
        tell window "Atmos Agent"
            -- Get window bounds
            set winPos to position
            set winSize to size
            
            set results to "Testing clicks at different positions:" & return
            
            -- Click where hamburger menu should be (top-left, below title bar)
            set hamburgerX to (item 1 of winPos) + 20
            set hamburgerY to (item 2 of winPos) + 50
            
            set results to results & "Clicking at hamburger position (" & hamburgerX & ", " & hamburgerY & ")..." & return
            click at {hamburgerX, hamburgerY}
            delay 2
            
            -- Check if any new UI elements appeared
            set afterClickElements to count of UI elements
            set results to results & "UI elements after hamburger click: " & afterClickElements & return
            
            -- Check if window is still there
            if exists window "Atmos Agent" then
                set results to results & "Window still exists" & return
                
                -- Try to find any text that says "Controls"
                set allElements to entire contents
                repeat with elem in allElements
                    try
                        set elemClass to class of elem as string
                        if elemClass contains "static text" then
                            set txtValue to value of elem
                            if txtValue contains "Control" then
                                set results to results & "Found Controls text!" & return
                                click elem
                                delay 2
                                exit repeat
                            end if
                        end if
                    end try
                end repeat
                
                -- If slide-out menu is open, try clicking where Controls should be
                -- Based on screenshot, it's about 1/3 down the menu
                set controlsX to (item 1 of winPos) + 100
                set controlsY to (item 2 of winPos) + 200
                
                set results to results & "Clicking at Controls position (" & controlsX & ", " & controlsY & ")..." & return
                click at {controlsX, controlsY}
                delay 2
                
                -- Now try to find Off button
                -- It should be on the right side of the window
                set offButtonX to (item 1 of winPos) + (item 1 of winSize) - 100
                set offButtonY to (item 2 of winPos) + 250
                
                set results to results & "Clicking at Off button position (" & offButtonX & ", " & offButtonY & ")..." & return
                click at {offButtonX, offButtonY}
                delay 1
                
                -- Click confirm if needed
                set confirmX to (item 1 of winPos) + (item 1 of winSize) / 2
                set confirmY to (item 2 of winPos) + (item 2 of winSize) / 2
                click at {confirmX, confirmY}
                
            else
                set results to results & "Window was closed!" & return
            end if
            
            display dialog results buttons {"OK"} default button 1
        end tell
    end tell
end tell