# SwiftBar Menu Documentation
## Luxafor Notification Monitor Interface

This document provides a detailed breakdown of all menu options available in the SwiftBar interface for the Luxafor notification monitoring system.

---

## Menu Bar Icon Indicators

The menu bar icon changes color to indicate system status:

- **🟢 Green Circle**: Monitor running with Luxafor device connected
- **🟠 Orange Circle**: Monitor running but Luxafor device not connected
- **🔴 Red Circle**: Monitor stopped

---

## Main Menu Sections

### 1. System Status & Control

#### When Monitor is Running
**Status Display:**
- Shows "Luxafor Monitor: Running" (green text)
- Or "Luxafor Monitor: Running (No Device)" (orange text)

**Actions:**
- **Stop Monitoring**: Stops the notification monitor service
  - Command: `luxafor-control.sh stop`

#### When Monitor is Stopped
**Status Display:**
- Shows "Luxafor Monitor: Stopped" (red text)

**Actions:**
- **Start Monitoring**: Starts the notification monitor service
  - Command: `luxafor-control.sh start`

### 2. Current Notifications Display

Shows real-time notification counts from monitored applications:

**Format:** `AppName: Count (Additional Info)`

**Examples:**
- `Teams: 2 (Security Team)`
- `Slack: 1 (offsec)`
- `Outlook: 3 (phishing folder)`

**Behavior:**
- Only displays apps with active notifications
- Shows "No notifications" if none present
- Includes channel/folder context when available
- Colors match configured LED colors

### 3. Application Enable/Disable Controls

#### Simple Apps (No Sub-channels)
**Format:** `☑/☐ AppName`
- **☑**: App is enabled for monitoring
- **☐**: App is disabled

**Action:** Click to toggle enabled state
- Command: `toggle-app.sh AppName enable/disable`

#### Apps with Sub-channels (Teams, Slack, Outlook)
**Format:** `☑/☐ AppName ▸` (expandable submenu)

**Teams/Slack Submenus:**
- **All Chats/All DMs Section:**
  - `☑/☐ All Chats` - Enable/disable all Teams chat monitoring
  - `☑/☐ All DMs` - Enable/disable all Slack DM monitoring

- **Individual Channels Section:**
  - `☑/☐ ChannelName` - Toggle specific channel monitoring
  - Command: `toggle-channel.sh AppName channel/dm ChannelName true/false`

**Outlook Submenus:**
- **Outlook folders Section:**
  - `☑/☐ FolderName` - Toggle specific folder monitoring
  - Command: `toggle-channel.sh Outlook folder FolderName true/false`

### 4. System Features

#### Pushover Mobile Alerts
- **☑ Pushover Alerts**: Mobile notifications enabled (green)
- **☐ Pushover Alerts**: Mobile notifications disabled (gray)
- **Action:** Toggle by modifying `luxafor-pushover.conf`

#### Debug Logging
- **☑ Debug Logging**: Debug mode active (green)
  - **Submenu:** View Log - Opens debug log in terminal
  - Command: `tail -n 50 /tmp/luxafor-debug.log`
- **☐ Debug Logging**: Debug mode inactive (gray)
- **Action:** Toggle by creating/removing debug file

#### Monitor Restart
- **Restart Monitor**: Restarts the notification monitoring service
  - Command: `luxafor-control.sh restart`
  - Opens in terminal to show output

### 5. Atmos Protection Control

Enterprise security system integration for managing Atmos/Axis protection.

#### Auto-Toggle Feature
- **☑ Auto-Toggle Active**: Automatic protection management running (orange)
  - Shows "Protection kept disabled"
  - Shows "Toggles every 50 minutes"
  - **Stop Auto-Toggle**: Disables automatic management
- **☐ Auto-Toggle Inactive**: No automatic management (gray)
  - Shows "Click to keep protection off"
  - **Start Auto-Toggle**: Enables automatic management

#### Manual Control
- **Disable Once Now**: Manually disable Atmos protection immediately
  - Command: `osascript disable_once.scpt`

### 6. SSH Tunnel Management

Manages secure tunnels to remote services.

#### Tunnel Status Display
**Active Tunnel:**
- `☑ Description (LocalPort)` (green)
- **PID: ProcessID** (gray)
- **Special Actions:**
  - **Open Kibana**: Opens Elasticsearch interface (port 5601)
  - **Open GitLab**: Opens GitLab interface (port 9443)
  - **Open Browser**: Opens web interface for other services

**Inactive Tunnel:**
- `☐ Description (LocalPort)`

#### Tunnel Actions
- **Click Active Tunnel**: Stops the tunnel
  - Command: `tunnel-control.sh stop TunnelName`
- **Click Inactive Tunnel**: Starts the tunnel
  - Command: `tunnel-control.sh start TunnelName`
  - Some tunnels auto-open browser on start

#### Configured Tunnels (from tunnels.conf)
1. **Elasticsearch/Kibana (5601)**: Access to Elasticsearch log analysis
2. **Elasticsearch API (9200)**: Direct Elasticsearch API access
3. **IP Scanner Web (8081)**: IP Scanner web interface
4. **IP Scanner SFTP (2222)**: File transfer access to IP Scanner
5. **IP Scanner API (5000)**: IP Scanner submission endpoint
6. **GitLab (9443)**: GitLab via SSH config alias
7. **OSPortal API Tunnel (8888)**: Two-layer tunnel (SSH + Flask proxy with IAP headers)
   - Layer 1: SSH tunnel to osportal server (port 5000)
   - Layer 2: Flask proxy with automatic IAP authentication
8. **Claude Sessions Browser (8765)**: Web interface for browsing Claude Code sessions
   - Auto-opens browser to http://localhost:8765
9. **Rocket Chat (3000)**: Rocket Chat instance via GCP Compute SSH
   - Auto-opens browser to http://localhost:3000

### 7. SSH Connections

Quick access to SSH servers.

#### Connection Display
**Format:** `🖥 Description`
- **Subtitle:** `user@hostname:port` (gray, small text)

#### Connection Action
- **Click**: Initiates SSH connection
  - Command: `ssh-connect.sh hostname port user`

### 8. Screen Timeout Prevention

Utility to keep the screen awake during extended work.

#### Status Display
**Active:**
- `☑ Prevent Sleep (Active)` (orange)
- Shows "Pressing Fn key every 10 min"

**Inactive:**
- `☐ Prevent Sleep`
- Shows "Click to keep screen awake"

#### Actions
- **Click Active**: Stops the prevent-sleep script
  - Command: `no-timeout-control.sh stop`
- **Click Inactive**: Starts the prevent-sleep script
  - Command: `no-timeout-control.sh start`

### 9. Configuration Editing

Direct access to edit configuration files in VS Code.

#### Available Configurations
- **Luxafor Config**: Main app monitoring settings
  - File: `luxafor-config.conf`
- **Enabled Apps**: App enable/disable states
  - File: `luxafor-enabled-apps.conf`
- **Channels/Folders**: Channel-specific monitoring rules
  - File: `luxafor-channels.conf`
- **Pushover Alerts**: Mobile notification settings
  - File: `luxafor-pushover.conf`
- **Burp Flash Script**: Custom Burp Suite integration
  - File: `luxafor-burp-flash.sh`
- **SSH Tunnels**: Tunnel definitions
  - File: `tunnels.conf`
- **SSH Connections**: Quick SSH connection list
  - File: `ssh-connections.conf`

**Action:** Click any item to open the file in VS Code
- Command: `code ConfigFileName`

### 10. Utilities

#### Open Folder
- **Open Folder**: Opens project directory in Finder
  - Command: `open /Users/larry.craddock/Projects/luxafor`

---

## Menu Behavior Notes

### Refresh Timing
- Menu updates every 1 second when daemon is active
- Menu updates every 5 seconds in lightweight mode

### Visual Indicators
- **Colors**: Match configured Luxafor LED colors
- **Checkboxes**: ☑ (enabled/active) vs ☐ (disabled/inactive)
- **Arrows**: ▸ indicates expandable submenus
- **Text Colors**: Green (active), Orange (warning), Red (error), Gray (info)

### Terminal vs Background
- **Terminal=false**: Runs command in background, menu refreshes
- **Terminal=true**: Opens terminal window to show command output
- **Refresh=true**: Forces menu to update after command execution

### Error Handling
- Missing configuration files show "No X configured" with creation options
- Failed commands show macOS notifications
- Service status automatically detected and displayed

---

## File Dependencies

The SwiftBar menu relies on these key files:
- `luxafor-toggle.5s.sh`: Current lightweight menu script
- `luxafor-toggle.1s.sh.backup`: Full-featured menu generator
- `luxafor-menu-daemon.sh`: Background cache generator
- Various `.conf` files for configuration
- Control scripts in the project directory

This documentation reflects the current menu structure as implemented in the backup script that generates the cached menu content.