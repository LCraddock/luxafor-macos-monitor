#!/usr/bin/env bash

echo "=== Testing Teams Badge ==="
echo

# Check if Teams is running
if ! pgrep -x "Microsoft Teams" > /dev/null; then
    echo "Teams is not running. Please start Teams first."
    exit 1
fi

# Check current badge
echo "Current Teams badge:"
lsappinfo info -only StatusLabel "com.microsoft.teams2" 2>/dev/null || echo "No status info"

echo
echo "To trigger a Teams notification:"
echo "1. In Teams, click 'New chat' (top left)"
echo "2. Search for your own name"
echo "3. Send yourself a message"
echo
echo "If self-chat doesn't work:"
echo "- Create a private channel in any team"
echo "- Post a message there"
echo "- Or ask someone to send you a test message"
echo
echo "Note: Teams badges may not update if minimized to system tray"
echo "Keep Teams in the Dock for best results"