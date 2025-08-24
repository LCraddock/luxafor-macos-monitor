#!/usr/bin/env bash

echo "🔍 OUTLOOK FOLDER DIAGNOSIS"
echo "=========================="

echo "1. Configured Outlook folders in channels.conf:"
grep "^Outlook|folder|" /Users/larry.craddock/Projects/luxafor/luxafor-channels.conf | while IFS='|' read -r app type name color action priority sound enabled; do
    echo "   Folder: '$name' (enabled: $enabled)"
done

echo ""
echo "2. Testing manual Outlook folder detection:"

# Test the specific function that checks Outlook folders
check_outlook_folder() {
    local folder_name="$1"
    local count=$(osascript <<APPLESCRIPT 2>/dev/null
tell application "Microsoft Outlook"
    try
        set targetFolder to missing value
        set defaultAcct to default account
        
        repeat with eachFolder in (get mail folders of defaultAcct)
            if name of eachFolder is "${folder_name}" then
                set targetFolder to eachFolder
                exit repeat
            end if
        end repeat
        
        if targetFolder is not missing value then
            return (unread count of targetFolder) as integer
        else
            return -999
        end if
        
    on error errMsg
        return -888
    end try
end tell
APPLESCRIPT
)
    
    if [[ "$count" == "-999" ]]; then
        echo "   ❌ Folder '$folder_name' not found"
    elif [[ "$count" == "-888" ]]; then
        echo "   ❌ Error accessing Outlook for folder '$folder_name'"
    elif [[ "$count" =~ ^[0-9]+$ ]]; then
        echo "   ✅ Folder '$folder_name' has $count unread emails"
    else
        echo "   ❓ Folder '$folder_name' returned: '$count'"
    fi
}

# Test the main folders from config
check_outlook_folder "Inbox"
check_outlook_folder "phishing"

echo ""
echo "3. Listing all available Outlook folders:"
osascript <<'APPLESCRIPT' 2>/dev/null
tell application "Microsoft Outlook"
    try
        set defaultAcct to default account
        set folderList to {}
        
        repeat with eachFolder in (get mail folders of defaultAcct)
            set folderName to name of eachFolder
            set unreadCount to unread count of eachFolder
            set end of folderList to folderName & " (" & unreadCount & " unread)"
        end repeat
        
        repeat with folderInfo in folderList
            log "   " & folderInfo
        end repeat
        
    on error errMsg
        log "Error: " & errMsg
    end try
end tell
APPLESCRIPT

echo ""
echo "✅ Outlook diagnosis complete"
echo ""
echo "If a folder shows -999 (not found), check the exact spelling and case."
echo "If a folder shows unread count > 0 but no LED, the service logic might be broken."
