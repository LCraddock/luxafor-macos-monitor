# Luxafor macOS Notification Monitor

A sophisticated macOS notification monitoring system that automatically controls your Luxafor LED device based on app notifications, with granular channel/folder control and mobile alerts.

![SwiftBar Menu](swiftbar.png)

## Overview

This system monitors macOS dock badges and window titles to detect notifications from various apps (Teams, Slack, Outlook, Zoom, etc.) and automatically changes your Luxafor LED color. It includes channel-specific monitoring, Pushover mobile alerts, and a comprehensive SwiftBar menu interface.

## Key Features

- 🚦 **Multi-App Monitoring** - Monitor any macOS app that shows dock badges
- 📂 **Granular Control** - Configure specific Outlook folders, Teams chats, and Slack channels
- 🎯 **Smart Detection** - Automatically detects which Teams/Slack channel triggered notifications
- 📱 **Mobile Alerts** - Pushover integration with channel-specific sounds and priorities
- 🎨 **Custom Colors** - Assign any color to any app, channel, or folder
- ⚡ **Flash Patterns** - Configure flashing for urgent items
- 📊 **Priority System** - Handles multiple notifications intelligently
- 🖥️ **Menu Bar Control** - Complete control via SwiftBar with real-time status
- 🔧 **Zero Maintenance** - Runs as a launch agent with auto-recovery

## Requirements

- macOS 10.15 or later
- Luxafor USB LED device
- Homebrew (for installation)
- Apps must have dock badges enabled in System Preferences → Notifications

## Quick Installation

```bash
git clone https://github.com/LCraddock/luxafor-macos-monitor.git
cd luxafor-macos-monitor
./install.sh
```

The installer will:
1. Install dependencies (SwiftBar, hidapi, cmake)
2. Build the enhanced luxafor-cli from source
3. Set up the launch agent for auto-start
4. Create default configurations
5. Start monitoring immediately

## Configuration

### Main App Configuration (`luxafor-config.conf`)

```bash
# Format: AppName|BundleID|Color|Priority
# Priority: 1 (highest) to 4 (lowest)

Teams|com.microsoft.teams2|red|1
Outlook|com.microsoft.Outlook|blue|2
Slack|com.tinyspeck.slackmacgap|green|3
Zoom|us.zoom.xos|magenta|4

# Add any app by finding its bundle ID:
# lsappinfo list | grep -i "app name"
```

### Channel/Folder Configuration (`luxafor-channels.conf`)

```bash
# Format: AppName|Type|Name|Color|Action|PushoverPriority|PushoverSound|Enabled
# Action: solid or flash
# PushoverPriority: 0=normal, 1=high (bypasses quiet hours)

# Outlook - ONLY these folders will trigger notifications
Outlook|folder|Inbox|blue|solid|0|pushover|true
Outlook|folder|Security Alerts|red|flash|1|siren|true
Outlook|folder|VIP|cyan|solid|1|tugboat|true

# Teams - Chats always alert if enabled, channels only if listed
Teams|chat|_all_chats|red|solid|0|pushover|true
Teams|channel|Security Team|red|flash|1|siren|true

# Slack - DMs always alert if enabled, channels only if listed  
Slack|dm|_all_dms|green|solid|0|pushover|true
Slack|channel|security-incidents|red|flash|1|tugboat|true
```

### Pushover Configuration (`luxafor-pushover.conf`)

```bash
# Get tokens from https://pushover.net/
PUSHOVER_APP_TOKEN="your_app_token_here"
PUSHOVER_USER_KEY="your_user_key_here"
PUSHOVER_ENABLED="true"
```

## How It Works

### Monitoring Logic

1. **Dock Badge Detection**: Polls `lsappinfo` every 5 seconds to check dock badges
2. **Channel Detection**: 
   - For Teams/Slack: Reads window title to identify active channel
   - For Outlook: Checks each configured folder for unread counts
3. **Priority Resolution**: Shows color of highest priority app with notifications
4. **Smart Alerts**: Only sends Pushover when LED transitions from off to on
5. **State Tracking**: Prevents duplicate alerts using `/tmp/luxafor-state`

### Special Behaviors

- **Outlook**: Only monitors folders explicitly listed in channels config
- **Teams**: 
  - All DMs/chats alert if `_all_chats` is enabled
  - Channels only alert if explicitly configured
  - Note: Teams only creates badges for @mentions and DMs
- **Slack**: 
  - All DMs alert if `_all_dms` is enabled
  - Channels only alert if explicitly configured
  - Handles private channels (strips "!" prefix)

## SwiftBar Menu Features

The menu bar icon shows device status:
- 🟢 Running with device connected
- 🟠 Running but no device found
- 🔴 Monitor stopped

Menu options include:
- Real-time notification counts with source details
- Enable/disable individual apps
- Expandable submenus for channels/folders
- Toggle Pushover notifications
- Quick LED tests (6s or 30s)
- Manual color controls
- Edit configuration files
- View logs and restart service

## Advanced Features

### Burp Suite Integration
Automatically flashes purple when launching Burp Suite as a reminder that proxy is active.

### Debug Mode
Enable detailed logging:
```bash
touch ~/.luxafor-monitor/debug
tail -f ~/.luxafor-monitor/luxafor-notify.log
```

### Manual Control
```bash
# Control the service
~/.luxafor-monitor/luxafor-control.sh start|stop|restart|status

# Test LED directly
~/.luxafor-monitor/luxafor-cli/build/luxafor red
~/.luxafor-monitor/luxafor-cli/build/luxafor flash green

# Run test patterns
~/.luxafor-monitor/luxafor-test.sh
```

## Troubleshooting

### LED Not Responding
1. Check menu bar icon (should be green)
2. Verify USB connection
3. Test directly: `~/.luxafor-monitor/luxafor-cli/build/luxafor red`
4. Check logs: `~/.luxafor-monitor/luxafor-notify.log`

### Notifications Not Detected
1. Ensure apps have badge notifications enabled in System Preferences
2. For Teams/Slack: Make sure window is open (minimized is OK)
3. Check if app is enabled in SwiftBar menu
4. Verify bundle ID in config matches: `lsappinfo list | grep -i "app name"`

### Pushover Not Working
1. Verify credentials in `luxafor-pushover.conf`
2. Check if enabled in SwiftBar menu
3. Test: `~/.luxafor-monitor/tests/test-pushover.sh`

## Uninstall

```bash
cd luxafor-macos-monitor
./uninstall.sh
```

This will:
- Stop the monitor service
- Remove the launch agent
- Delete all installed files
- Preserve your configurations (optional)

## Technical Details

- **Language**: Bash scripts with AppleScript for window detection
- **USB Control**: Enhanced C++ luxafor-cli with reconnection support
- **Service**: macOS launch agent with KeepAlive for crash recovery
- **Menu Bar**: SwiftBar plugin updating every second
- **Performance**: Minimal CPU usage (~0.1%), no persistent logging

## Credits

Built on [Mike Rogers' luxafor-cli](https://github.com/MikeBailleul/luxafor-cli) with enhancements for:
- Additional colors and effects
- Automatic reconnection
- Better error handling

## License

MIT License - See LICENSE file

## Contributing

Pull requests welcome! Please test with your Luxafor device before submitting.

---

**Note**: This tool requires apps to have notification badges enabled. Some apps (like Teams) only show badges for specific notification types (@mentions, DMs) and not for all channel activity.