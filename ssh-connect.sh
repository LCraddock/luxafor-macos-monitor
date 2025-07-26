#!/bin/bash

# SSH Connection Helper Script
# Usage: ssh-connect.sh HOST PORT USER

HOST=$1
PORT=$2
USER=$3

# Check if this is an SSH config alias
if [[ "$PORT" == "config" && "$USER" == "config" ]]; then
    # Use simple ssh command with config alias
    SSH_CMD="ssh ${HOST}"
else
    # Use full ssh command with port and user
    SSH_CMD="ssh -p ${PORT} ${USER}@${HOST}"
fi

# Open iTerm2 and connect via SSH
osascript <<EOF
tell application "iTerm"
    activate
    
    -- Try to use current window, or create new one if needed
    if (count of windows) = 0 then
        create window with default profile
    end if
    
    tell current window
        create tab with default profile
        tell current session
            write text "${SSH_CMD}"
        end tell
    end tell
end tell
EOF