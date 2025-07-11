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
- ⚡ **Lightweight** - Near-zero CPU usage, no logging overhead
- 🔧 **Easy Configuration** - Simple text config file, no coding required

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/luxafor-macos-monitor.git
cd luxafor-macos-monitor

# Run the installer
./install.sh
```

That's it! The monitor is now running and will start automatically on login.

## How It Works

1. Polls notification badges using macOS `lsappinfo` every 5 seconds
2. For Outlook, also checks all folders (not just inbox)
3. Sets Luxafor to the color of the highest priority app with notifications
4. Menu bar icon shows status (🟢 running / 🔴 stopped)

## Configuration

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

## Requirements

- macOS 10.15 or later
- Luxafor USB device
- Apps must have "Badge app icon" enabled in System Settings → Notifications

## Menu Bar Features

Click the 🟢/🔴 icon to:
- View current notification counts
- Start/Stop monitoring
- Edit configuration
- Run LED tests
- Set manual colors

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

## Credits

- Uses [luxafor-cli](https://github.com/mike-rogers/luxafor-cli) by Mike Rogers
- Menu bar functionality via [SwiftBar](https://github.com/swiftbar/SwiftBar)

## License

MIT License - See LICENSE file for details

## Contributing

Pull requests welcome! Please test changes with your Luxafor device before submitting.

### Development Setup

1. Fork and clone the repository
2. Make your changes
3. Test with `./install.sh` (it will update existing installation)
4. Submit a pull request

## TODO

- [ ] Support for multiple Luxafor devices
- [ ] Different effects for different priority levels
- [ ] DND mode scheduling
- [ ] Support for Luxafor Flag vs Orb differences