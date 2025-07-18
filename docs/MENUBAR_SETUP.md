# Menu Bar Setup for Luxafor Control

## Option 1: SwiftBar (Recommended - Free & Modern)

1. **Install SwiftBar** (if you don't have it):
   ```bash
   brew install --cask swiftbar
   ```

2. **Set up the plugin**:
   - Open SwiftBar and set the plugin folder (it will ask on first launch)
   - Suggested folder: `~/Documents/SwiftBarPlugins`
   
3. **Install the Luxafor plugin**:
   ```bash
   # Create plugin folder if needed
   mkdir -p ~/Documents/SwiftBarPlugins
   
   # Copy or link the plugin
   ln -s /Users/larry.craddock/Projects/luxafor/luxafor-toggle.1s.sh ~/Documents/SwiftBarPlugins/
   ```

4. **First-time setup**:
   - Make sure the launch agent is installed:
     ```bash
     cd /Users/larry.craddock/Projects/luxafor
     ./setup-launch-agent.sh install
     ```

## Option 2: BitBar (Classic)

Same process but install BitBar instead:
```bash
brew install --cask bitbar
```

## Features

The menu bar icon shows:
- 🟢 Green dot when monitoring is active
- 🔴 Red dot when monitoring is stopped

Click the icon to see:
- Current status
- Start/Stop toggle
- Recent notification activity
- Quick access to logs and folder

## Customization

To change the refresh rate, rename the file:
- `luxafor-toggle.1s.sh` = refresh every 1 second
- `luxafor-toggle.5s.sh` = refresh every 5 seconds
- `luxafor-toggle.30s.sh` = refresh every 30 seconds

## Alternative: Native macOS Shortcuts

If you prefer not to install SwiftBar, you can create a Shortcuts app shortcut:

1. Open Shortcuts app
2. Create new shortcut
3. Add "Run Shell Script" action
4. Use this script to toggle:
   ```bash
   if launchctl list | grep -q "com.luxafor.notify"; then
       launchctl unload ~/Library/LaunchAgents/com.luxafor.notify.plist
       osascript -e 'display notification "Luxafor monitoring stopped" with title "Luxafor"'
   else
       launchctl load ~/Library/LaunchAgents/com.luxafor.notify.plist
       osascript -e 'display notification "Luxafor monitoring started" with title "Luxafor"'
   fi
   ```
5. Add to menu bar or assign keyboard shortcut