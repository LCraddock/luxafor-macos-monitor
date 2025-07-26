-- First try to activate the app
tell application "Atmos Agent"
    activate
end tell

delay 2

-- Now work with System Events
tell application "System Events"
    set allProcesses to name of every process
    display dialog "All processes: " & (count of allProcesses) & " total. Looking for Atmos..."
    
    -- Try different possible names
    set possibleNames to {"Atmos Agent", "Atmos", "AtmosAgent", "atmosagent"}
    
    repeat with procName in possibleNames
        if exists process procName then
            display dialog "Found process: " & procName
            return
        end if
    end repeat
    
    display dialog "Could not find Atmos process. Check the exact name in Activity Monitor."
end tell