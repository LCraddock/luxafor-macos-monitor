tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        tell application "Axis Client" to activate
        delay 2
        
        -- Get window position and size
        set winPos to position of window "Atmos Agent"
        set winSize to size of window "Atmos Agent"
        
        -- Calculate click positions based on window location
        -- Hamburger menu: top-left, about 20px from left, 50px from top
        set hamburgerX to (item 1 of winPos) + 20
        set hamburgerY to (item 2 of winPos) + 50
        
        -- Click hamburger menu
        do shell script "echo 'Clicking hamburger at: " & hamburgerX & ", " & hamburgerY & "'"
        click at {hamburgerX, hamburgerY}
        delay 2
        
        -- Controls menu item: about 100px from left, 200px from top
        set controlsX to (item 1 of winPos) + 100
        set controlsY to (item 2 of winPos) + 200
        
        -- Click Controls
        do shell script "echo 'Clicking Controls at: " & controlsX & ", " & controlsY & "'"
        click at {controlsX, controlsY}
        delay 2
        
        -- Internet Protection Off button: right side of window, about 250px from top
        set offButtonX to (item 1 of winPos) + (item 1 of winSize) - 100
        set offButtonY to (item 2 of winPos) + 250
        
        -- Click Off button
        do shell script "echo 'Clicking Off button at: " & offButtonX & ", " & offButtonY & "'"
        click at {offButtonX, offButtonY}
        delay 1
        
        -- Click Confirm (center of window)
        set confirmX to (item 1 of winPos) + ((item 1 of winSize) / 2)
        set confirmY to (item 2 of winPos) + ((item 2 of winSize) / 2)
        
        do shell script "echo 'Clicking Confirm at: " & confirmX & ", " & confirmY & "'"
        click at {confirmX, confirmY}
    end tell
end tell