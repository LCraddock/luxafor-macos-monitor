# Luxafor Notification Monitor

Automatically monitors Slack, Teams, Zoom, and Outlook for notifications and displays them on your Luxafor device.

## Overview

This system monitors dock badges on macOS and lights up your Luxafor device with different colors based on which apps have notifications. It runs automatically on login and can be controlled via the menu bar.

## Components

### Core Scripts

1. **`luxafor-notify.sh`** - Main monitoring script
   - Polls app badges every 5 seconds
   - Controls Luxafor LED colors based on notifications
   - Runs silently with no logging

2. **`luxafor-control.sh`** - Manual control script
   - Commands: `start`, `stop`, `restart`, `status`
   - Alternative to launch agent for manual control

3. **`luxafor-toggle.1s.sh`** - SwiftBar menu bar plugin
   - Shows 🟢 when running, 🔴 when stopped
   - Click to start/stop monitoring

### Configuration Files

4. **`com.luxafor.notify.plist`** - macOS Launch Agent
   - Auto-starts the service on login
   - Keeps it running (restarts if it crashes)

5. **`setup-launch-agent.sh`** - Launch agent installer
   - Commands: `install`, `uninstall`

## How It Works

1. The launch agent starts `luxafor-notify.sh` automatically on login
2. The script checks notification badges using `lsappinfo` every 5 seconds
3. For Outlook, it also checks all folders via AppleScript
4. Based on priority, it sets the Luxafor to the appropriate color
5. SwiftBar displays the status in the menu bar with a 🟢/🔴 indicator
6. No logging - runs completely silent with minimal system impact

## Color Assignments

Priority order (highest to lowest):

| App | Color | Priority | Notes |
|-----|-------|----------|-------|
| Teams | Red | 1 (Highest) | Company-wide communications |
| Outlook | Blue | 2 | Checks all folders, not just inbox |
| Slack | Green | 3 | Department communications |
| Zoom | Magenta | 4 (Lowest) | Meeting notifications |

## Configuration

### Change Colors
Edit `luxafor-notify.sh` lines 75-86:
```bash
# Example: Change Teams from red to yellow
$LUXAFOR_CLI red    # Change to: $LUXAFOR_CLI yellow
```

### Change Poll Interval
Edit `luxafor-notify.sh` line 8:
```bash
POLL_INTERVAL=5    # Change to desired seconds (default: 5)
```

### Change Priority Order
Rearrange the if/elif blocks in `luxafor-notify.sh` (lines 75-90)

### Add/Remove Apps
1. Find the app's bundle ID: `lsappinfo list | grep -i appname`
2. Add a new badge check in the script
3. Add a new color condition in the priority chain

## Usage

### Menu Bar Control (Recommended)
- Click the 🟢/🔴 icon in the menu bar
- Select "Start/Stop Monitoring"

### Command Line Control
```bash
# Check status
./luxafor-control.sh status

# Manual start/stop
./luxafor-control.sh start
./luxafor-control.sh stop
./luxafor-control.sh restart
```

### Launch Agent Control
```bash
# Temporarily disable
launchctl unload ~/Library/LaunchAgents/com.luxafor.notify.plist

# Re-enable
launchctl load ~/Library/LaunchAgents/com.luxafor.notify.plist

# Permanently uninstall
./setup-launch-agent.sh uninstall
```

## Troubleshooting

### Luxafor not lighting up
1. Check if monitoring is running: `./luxafor-control.sh status`
2. Test luxafor directly: `/Users/larry.craddock/Projects/luxafor-cli/build/luxafor red`
3. Run script manually to see output: `./luxafor-notify.sh`

### Apps not detected
1. Make sure apps are in the Dock
2. Check System Settings → Notifications → ensure "Badge app icon" is enabled
3. For Teams: @mention yourself in a channel
4. For Slack: Use `/remind me test in 1 minute`

### Menu bar icon not appearing
1. Make sure SwiftBar is running
2. Check plugin folder is set to `~/Documents/SwiftBarPlugins`
3. Click SwiftBar → Refresh All

## Dependencies

- **luxafor-cli**: Located at `~/Projects/luxafor-cli/build/luxafor`
- **SwiftBar**: For menu bar control (`brew install --cask swiftbar`)
- **macOS**: Requires macOS for AppleScript and launch agents

## Files Location

All files are in `/Users/larry.craddock/Projects/luxafor/`:
- Main scripts: `luxafor-notify.sh`, `luxafor-control.sh`
- Menu bar plugin: `luxafor-toggle.1s.sh`
- Launch agent: `com.luxafor.notify.plist`
- No log files - runs silently