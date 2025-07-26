tell application "System Events"
    tell process "Axis Client"
        set frontmost to true
        delay 1
        
        -- Get all UI elements
        set allElements to entire contents of window "Atmos Agent"
        set outputText to ""
        
        -- Log each element type and properties
        repeat with elem in allElements
            try
                set elemClass to class of elem as string
                set elemDesc to description of elem as string
                
                -- Special handling for buttons
                if elemClass contains "button" then
                    try
                        set elemName to name of elem as string
                        set outputText to outputText & "Button: " & elemName & " (" & elemDesc & ")" & return
                    on error
                        set outputText to outputText & "Button: (no name) (" & elemDesc & ")" & return
                    end try
                end if
                
                -- Special handling for static text
                if elemClass contains "static text" then
                    try
                        set elemValue to value of elem as string
                        set outputText to outputText & "Text: " & elemValue & return
                    end try
                end if
            end try
        end repeat
        
        -- Write to file
        set outputFile to "/tmp/atmos-ui-elements.txt"
        do shell script "echo " & quoted form of outputText & " > " & outputFile
        
        display dialog "UI elements logged to: " & outputFile
    end tell
end tell