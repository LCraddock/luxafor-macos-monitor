#!/bin/bash

# Create directory for scripts if it doesn't exist
mkdir -p ~/scripts/atmos_protection

# 1. Create the toggle protection AppleScript
cat > ~/scripts/atmos_protection/toggle_protection.scpt << 'EOL'
tell application "System Events"
    tell process "Atmos Agent"
        set frontmost to true
        delay 1
        
        -- First, turn protection ON (regardless of current state)
        click button "On" of group 2 of window "Atmos Agent"
        delay 1
        
        -- Handle the confirmation dialog if it appears
        if exists (button "Confirm" of window "Atmos Agent") then
            click button "Confirm" of window "Atmos Agent"
            delay 2 -- Give it time to complete the action
        end if
        
        -- Then, turn protection OFF
        click button "Off" of group 2 of window "Atmos Agent"
        delay 1
        
        -- Handle the confirmation dialog
        if exists (button "Confirm" of window "Atmos Agent") then
            click button "Confirm" of window "Atmos Agent"
        end if
    end tell
end tell
EOL

# 2. Create a script to disable protection once
cat > ~/scripts/atmos_protection/disable_once.scpt << 'EOL'
tell application "System Events"
    tell process "Atmos Agent"
        set frontmost to true
        delay 1
        
        -- Click the Off button
        click button "Off" of group 2 of window "Atmos Agent"
        delay 1
        
        -- Handle the confirmation dialog
        if exists (button "Confirm" of window "Atmos Agent") then
            click button "Confirm" of window "Atmos Agent"
        end if
    end tell
end tell
EOL

# 3. Create the launchd plist file
cat > ~/Library/LaunchAgents/com.user.toggleprotection.plist << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.toggleprotection</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/osascript</string>
        <string>${HOME}/scripts/atmos_protection/toggle_protection.scpt</string>
    </array>
    <key>StartInterval</key>
    <integer>3000</integer>
    <key>Disabled</key>
    <true/>
</dict>
</plist>
EOL

# 4. Create the start script
cat > ~/scripts/atmos_protection/start_protection_toggle.sh << 'EOL'
#!/bin/bash
# First, run the disable script once
osascript ~/scripts/atmos_protection/disable_once.scpt

# Then enable the automatic toggling
launchctl load ~/Library/LaunchAgents/com.user.toggleprotection.plist
launchctl enable ~/Library/LaunchAgents/com.user.toggleprotection.plist
launchctl start com.user.toggleprotection

echo "Atmos Internet Protection is now disabled and will remain disabled while you work."
EOL

# 5. Create the stop script
cat > ~/scripts/atmos_protection/stop_protection_toggle.sh << 'EOL'
#!/bin/bash
# Stop and unload the automatic toggling
launchctl stop com.user.toggleprotection
launchctl disable ~/Library/LaunchAgents/com.user.toggleprotection.plist
launchctl unload ~/Library/LaunchAgents/com.user.toggleprotection.plist

echo "Atmos Internet Protection toggling has been stopped."
echo "Note: Protection may still be disabled. Use Atmos Agent UI to re-enable if needed."
EOL

# Make the scripts executable
chmod +x ~/scripts/atmos_protection/start_protection_toggle.sh
chmod +x ~/scripts/atmos_protection/stop_protection_toggle.sh

# Create aliases for easier use
echo "" >> ~/.bash_profile
echo "# Atmos Protection Toggle Aliases" >> ~/.bash_profile
echo "alias burp-start='~/scripts/atmos_protection/start_protection_toggle.sh'" >> ~/.bash_profile
echo "alias burp-stop='~/scripts/atmos_protection/stop_protection_toggle.sh'" >> ~/.bash_profile

# Create aliases for zsh users too
if [ -f ~/.zshrc ]; then
    echo "" >> ~/.zshrc
    echo "# Atmos Protection Toggle Aliases" >> ~/.zshrc
    echo "alias burp-start='~/scripts/atmos_protection/start_protection_toggle.sh'" >> ~/.zshrc
    echo "alias burp-stop='~/scripts/atmos_protection/stop_protection_toggle.sh'" >> ~/.zshrc
fi

echo "======================================================"
echo "Installation complete!"
echo "To disable Internet Protection when starting Burp Suite:"
echo "$ burp-start"
echo ""
echo "To stop the automatic toggling when done with Burp Suite:"
echo "$ burp-stop"
echo ""
echo "You can also run the scripts directly from:"
echo "~/scripts/atmos_protection/start_protection_toggle.sh"
echo "~/scripts/atmos_protection/stop_protection_toggle.sh"
echo "======================================================"

