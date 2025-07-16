# Luxafor macOS Notification Monitor

Automatically monitor Slack, Teams, Zoom, Outlook and other apps for notifications and display them on your Luxafor LED device.

![SwiftBar Menu](https://img.shields.io/badge/SwiftBar-Compatible-green)
![macOS](https://img.shields.io/badge/macOS-10.15%2B-blue)
![License](https://img.shields.io/badge/license-MIT-blue)

## Features

- 🚦 **Automatic LED Control** - Changes Luxafor color based on app notifications
- 📱 **Multi-App Support** - Monitor Slack, Teams, Zoom, Outlook, and more
- 🎨 **Customizable Colors** - Assign any color to any app via config file
- 📊 **Priority System** - Shows highest priority notification when multiple exist
- 🖥️ **Menu Bar Control** - Start/stop monitoring and see notification counts
- 📁 **Granular Channel/Folder Control** - Configure specific Teams/Slack channels and Outlook folders
- 💬 **Smart Channel Detection** - Automatically detects which channel/chat triggered the notification
- 🔔 **Individual Toggle Control** - Enable/disable notifications per app, channel, or folder
- 🚨 **Flash Alerts** - Configure flashing for urgent channels/folders
- 📲 **Pushover Integration** - Get mobile alerts with channel-specific sounds and priorities
- 🟠 **Device Status** - Amber icon when Luxafor disconnected
- 🚀 **App Launch Effects** - Flash on Burp Suite or other app launches
- ⚡ **Lightweight** - Near-zero CPU usage, no logging overhead
- 🔧 **Easy Configuration** - Simple text config files, no coding required

## SwiftBar Menu

![SwiftBar Menu Screenshot](swiftbar.png)

The SwiftBar menu provides complete control over the Luxafor monitor:
- View current notification counts with channel/folder details
- Enable/disable notifications for individual apps with checkboxes
- Expandable submenus for Teams/Slack channels and Outlook folders
- Toggle individual channels/folders on/off without editing config
- Edit main config, channels config, and Pushover settings
- Quick LED tests (6s and 30s options)
- Manual color controls (hold ⌥ to keep menu open)
- Device connection status indicator (green/amber/red icon)
- One-click restart and folder access

## Quick Start

```bash
# Clone the repository
git clone https://github.com/LCraddock/luxafor-macos-monitor.git
cd luxafor-macos-monitor

# Run the installer
./install.sh
```

That's it! The monitor is now running and will start automatically on login.

### What the installer does:
- Installs dependencies (SwiftBar, hidapi, cmake)
- Clones and builds the enhanced luxafor-cli from source
- Sets up the monitor service and menu bar integration
- Creates default configuration in `~/.luxafor-monitor/`

## How It Works

1. Polls notification badges using macOS `lsappinfo` every 5 seconds
2. For Teams/Slack, detects which channel/chat triggered the notification
3. For Outlook, checks only configured folders (not all folders)
4. Sets Luxafor to the color of the highest priority app with notifications
5. Uses channel/folder-specific colors and flash modes when configured
6. Sends Pushover notifications with source details (if enabled)
7. Menu bar icon shows status (🟢 running / 🟠 no device / 🔴 stopped)

## Configuration

### Main Configuration

Edit `~/.luxafor-monitor/luxafor-config.conf` to customize:

```bash
# Format: AppName|BundleID|Color|Priority
Teams|com.microsoft.teams2|red|1
Outlook|com.microsoft.Outlook|blue|2
Slack|com.tinyspeck.slackmacgap|green|3
Zoom|us.zoom.xos|magenta|4
```

After editing, restart via the menu bar or run:
```bash
~/.luxafor-monitor/luxafor-control.sh restart
```

### Finding Bundle IDs

To monitor additional apps:
```bash
lsappinfo list | grep -i "app name"
```

### Available Colors

Basic: `red`, `green`, `blue`, `yellow`, `magenta`, `cyan`, `orange`, `purple`, `pink`, `white`, `off`

Hex: `0xFF00FF` or `#FF00FF`

### Channel-Specific Monitoring

Configure specific channels and folders for granular notification control. Edit `luxafor-channels.conf`:

```bash
# Format: AppName|Type|Name|Color|Action|PushoverPriority|PushoverSound|Enabled
# Action can be: solid (default) or flash
# PushoverSound: pushover, bike, bugle, cashregister, classical, cosmic, falling, gamelan, incoming, intermission, magic, mechanical, pianobar, siren, spacealarm, tugboat, alien, climb, persistent, echo, updown, vibrate, none

# Outlook Folders
Outlook|folder|phishing|yellow|flash|1|siren|true
Outlook|folder|Inbox|blue|solid|0|pushover|true
Outlook|folder|VIP|cyan|solid|1|tugboat|true

# Teams configuration
Teams|chat|_all_chats|red|solid|0|pushover|true  # All DMs and chats
Teams|channel|Red Team|red|flash|1|siren|true     # Specific channel

# Slack configuration  
Slack|dm|_all_dms|green|solid|0|pushover|true     # All DMs
Slack|channel|incidents|green|flash|1|tugboat|true # Specific channel
```

**Key Behaviors**: 

**Outlook**:
- ONLY alerts on explicitly configured folders
- No "all folders" monitoring - must configure each folder
- Each folder has individual color, flash mode, and Pushover settings

**Teams**: 
- All chats/DMs alert by default (if `_all_chats` is enabled)
- Channels only alert if explicitly configured and enabled
- Automatically detects which chat/channel triggered the notification
- Note: Teams only creates badges for @mentions and DMs, not regular channel messages

**Slack**:
- All DMs alert by default (if `_all_dms` is enabled)  
- Channels only alert if explicitly configured and enabled
- Handles both public and private channels
- Shows notification source in Pushover alerts

**All Apps**:
- Individual channels/folders can be toggled via SwiftBar menu
- Flash mode makes the LED blink continuously
- Pushover notifications include the source (channel/folder name)
- Priority 0=normal, 1=high (bypasses quiet hours)

### Pushover Integration

Get mobile notifications when the Luxafor LED turns on. Edit `luxafor-pushover.conf`:

```bash
PUSHOVER_APP_TOKEN="your_app_token_here"
PUSHOVER_USER_KEY="your_user_key_here"
PUSHOVER_ENABLED="true"  # Set to false to disable
```

Features:
- Notifications only sent when LED transitions from off to on
- Channel/folder-specific sounds and priorities
- Notification includes source (e.g., "Teams: Lee" or "Slack: incidents")
- Toggle on/off via SwiftBar menu without editing config

## Requirements

- macOS 10.15 or later
- Luxafor USB device
- Apps must have "Badge app icon" enabled in System Settings → Notifications

## Menu Bar Features

Click the 🟢/🟠/🔴 icon to:
- View current notification counts with source details
- Start/Stop monitoring
- Toggle apps on/off with expandable channel/folder submenus
- Toggle Pushover notifications on/off
- Edit configuration files (main, channels, Pushover)
- Run LED tests (quick 6s or full 30s)
- Set manual colors (hold ⌥ to keep menu open)

## Command Line Usage

```bash
# Control the monitor
~/.luxafor-monitor/luxafor-control.sh start|stop|restart|status

# Run LED test
~/.luxafor-monitor/luxafor-test.sh

# Manual color control
~/.luxafor-monitor/luxafor-cli/build/luxafor red
```

## Uninstall

```bash
cd luxafor-macos-monitor
./uninstall.sh
```

## Troubleshooting

**Luxafor not lighting up?**
- Check if monitoring is running (menu bar should show 🟢)
- Ensure apps have badge notifications enabled in System Settings
- Test LED directly: `~/.luxafor-monitor/luxafor-cli/build/luxafor red`

**Apps not detected?**
- Apps must be in the Dock
- For Teams: @mention yourself in a channel
- For Slack: Use `/remind me test in 1 minute`

## Dependencies

This project uses:
- [Enhanced luxafor-cli](https://github.com/LCraddock/luxafor-cli) - Fork of [Mike Rogers' luxafor-cli](https://github.com/mike-rogers/luxafor-cli) with added color and effect support
- [SwiftBar](https://github.com/swiftbar/SwiftBar) - For menu bar functionality

The installer automatically builds the enhanced luxafor-cli from source, so you don't need to install it separately.

## License

MIT License - See LICENSE file for details

## Contributing

Pull requests welcome! Please test changes with your Luxafor device before submitting.

### Development Setup

1. Fork and clone the repository
2. Make your changes
3. Test with `./install.sh` (it will update existing installation)
4. Submit a pull request

### Note on File Paths

This repository contains full absolute paths (e.g., `/Users/larry.craddock/Projects/luxafor/`) rather than using `$HOME` or relative paths. This is intentional because:

- **plist files** (Launch Agents) require absolute paths and don't expand environment variables
- **AppleScript** doesn't understand shell variables like `$HOME`
- **SwiftBar** menu actions need absolute paths in their parameters

The installer script (`install.sh`) automatically updates all paths to match your system during installation, so these hardcoded paths won't affect end users.

## TODO

- [x] Channel/folder-specific monitoring for Teams, Slack, and Outlook
- [x] Pushover integration with channel-specific alerts
- [x] Individual enable/disable for channels and folders
- [x] Flash mode for urgent notifications
- [ ] Support for multiple Luxafor devices
- [ ] Different effects for different priority levels
- [ ] DND mode scheduling
- [ ] Support for Luxafor Flag vs Orb differences
- [ ] Calendar integration for meeting alerts
- [ ] Webhook support for custom integrations