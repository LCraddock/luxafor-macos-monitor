#!/usr/bin/env bash

echo "=== Testing Outlook Folder Access ==="
echo

# Test 1: Check if Outlook is running
echo "Checking if Outlook is running..."
if pgrep -x "Microsoft Outlook" > /dev/null; then
    echo "✓ Outlook is running"
else
    echo "✗ Outlook is not running - please start it"
    exit 1
fi

echo
echo "Scanning all folders for unread emails..."

# Test 2: Get unread count from all folders
osascript <<'APPLESCRIPT'
tell application "Microsoft Outlook"
    try
        set totalUnread to 0
        set folderInfo to ""
        
        -- Get default account
        set defaultAcct to default account
        
        -- Check mail folders
        repeat with eachFolder in (get mail folders of defaultAcct)
            set unreadInFolder to unread count of eachFolder
            set folderName to name of eachFolder
            
            if unreadInFolder > 0 then
                set folderInfo to folderInfo & folderName & ": " & unreadInFolder & " unread" & return
            end if
            
            set totalUnread to totalUnread + unreadInFolder
        end repeat
        
        return "Total unread emails: " & totalUnread & return & return & "Breakdown by folder:" & return & folderInfo
        
    on error errMsg
        return "Error accessing folders: " & errMsg
    end try
end tell
APPLESCRIPT

echo
echo "Testing badge detection..."
lsappinfo info -only StatusLabel "com.microsoft.Outlook" 2>/dev/null || echo "No badge info"