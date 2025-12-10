# Luxafor macOS Notification Monitor - Architecture

## System Overview

The Luxafor macOS Notification Monitor is a multi-process system that monitors macOS application notifications and controls a Luxafor USB LED device. The architecture emphasizes efficiency through caching and process separation.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface Layer                     │
├─────────────────────────────────────────────────────────────────┤
│  SwiftBar Menu (luxafor-toggle.5s.sh)                           │
│  - Reads from cache every 5 seconds                             │
│  - Provides user controls and status display                    │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ↓ (reads cache)
┌─────────────────────────────────────────────────────────────────┐
│                      Cache Layer (tmpfs)                         │
├─────────────────────────────────────────────────────────────────┤
│  /tmp/luxafor-menu-cache                                        │
│  - Generated menu content                                       │
│  - Updated every 1 second by daemon                             │
│                                                                  │
│  /tmp/luxafor-menu-daemon.pid                                   │
│  - Daemon process ID                                            │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ↑ (writes cache)
┌─────────────────────────────────────────────────────────────────┐
│                    Background Services Layer                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Menu Daemon (luxafor-menu-daemon.sh)                           │
│  - Generates menu cache every 1 second                          │
│  - Calls luxafor-toggle.1s.sh.backup for content               │
│  - Runs as background process                                   │
│                                                                  │
│  Notification Monitor (luxafor-notify.sh)                       │
│  - Polls apps every 1-5 seconds (configurable)                  │
│  - Controls Luxafor LED device                                  │
│  - Sends Pushover alerts                                        │
│  - Runs as LaunchAgent daemon                                   │
│                                                                  │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ↓ (monitors & controls)
┌─────────────────────────────────────────────────────────────────┐
│                     External Interfaces Layer                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  macOS Apps                    Luxafor Device                   │
│  - lsappinfo (badge counts)    - USB HID device                 │
│  - AppleScript (window titles) - luxafor-cli wrapper            │
│  - Slack, Teams, Outlook, etc.                                  │
│                                                                  │
│  Pushover API                  SSH Tunnels                      │
│  - Mobile notifications        - gcloud IAP tunnels             │
│                                - Regular SSH tunnels             │
│                                - Flask apps (API proxies)        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Notification Monitor (`luxafor-notify.sh`)

**Purpose:** Main monitoring daemon that polls applications and controls the Luxafor LED.

**Key Responsibilities:**
- Poll macOS app badge counts using `lsappinfo`
- Detect active window/channel using AppleScript
- Match notifications against channel-specific rules
- Calculate priority and set LED color
- Send Pushover mobile alerts
- Log debug information

**Process Model:**
- Runs as LaunchAgent: `com.luxafor.notify.plist`
- Poll interval: 1-5 seconds (configurable via `POLL_INTERVAL`)
- Keeps running until stopped via `luxafor-control.sh stop`

**Configuration Files Used:**
- `luxafor-config.conf` - App definitions and colors
- `luxafor-channels.conf` - Channel/folder specific rules
- `luxafor-enabled-apps.conf` - Enable/disable states
- `luxafor-pushover.conf` - Pushover alert settings

### 2. Menu Daemon (`luxafor-menu-daemon.sh`)

**Purpose:** Background process that generates SwiftBar menu content to reduce CPU usage.

**Key Responsibilities:**
- Call `luxafor-toggle.1s.sh.backup` to generate menu
- Write output to `/tmp/luxafor-menu-cache`
- Update cache every 1 second
- Maintain process health

**Process Model:**
- Started by `luxafor-control.sh start`
- Runs continuously in background
- PID stored in `/tmp/luxafor-menu-daemon.pid`
- Atomic cache updates using temp file + mv

**Why It Exists:**
- Original: SwiftBar plugin ran full menu generation every 1s (high CPU)
- Solution: Daemon generates once, multiple readers consume cache
- Result: ~70% CPU reduction

### 3. SwiftBar Plugin (`luxafor-toggle.5s.sh`)

**Purpose:** Lightweight menu bar interface that reads from daemon cache.

**Key Responsibilities:**
- Display cached menu content
- Refresh every 5 seconds (low overhead)
- Detect stale cache or dead daemon
- Provide fallback UI when daemon is down

**Execution Model:**
- Called by SwiftBar every 5 seconds
- Checks daemon health via PID file
- Validates cache freshness (<10 seconds old)
- Direct output to SwiftBar (no processing)

### 4. Menu Generator (`luxafor-toggle.1s.sh.backup`)

**Purpose:** Generates complete SwiftBar menu content with all controls and status.

**Key Responsibilities:**
- Build menu structure with status indicators
- Display current notifications per app
- Provide app enable/disable toggles
- Show SSH tunnel status and controls
- List configuration file shortcuts
- Generate utility menu items

**Called By:**
- Menu daemon (`luxafor-menu-daemon.sh`)
- Not called directly by SwiftBar (legacy name preserved)

**Menu Sections Generated:**
1. System status and control
2. Current notifications display
3. Per-app notification counts
4. App enable/disable toggles
5. Pushover alert toggles
6. SSH tunnel controls
7. Atmos protection toggle
8. Screen timeout prevention
9. Configuration file shortcuts
10. Utilities

### 5. Service Controller (`luxafor-control.sh`)

**Purpose:** Start/stop/restart all Luxafor services.

**Key Responsibilities:**
- Start notification monitor via LaunchAgent
- Start menu daemon in background
- Stop both services cleanly
- Restart services (stop + start)
- Refresh SwiftBar after changes

**Services Managed:**
- Notification Monitor (LaunchAgent)
- Menu Daemon (background process)
- SwiftBar refresh trigger

### 6. Tunnel Controller (`tunnel-control.sh`)

**Purpose:** Start/stop SSH tunnels, cloud tunnels, and local proxies.

**Key Responsibilities:**
- Parse tunnel configuration from `tunnels.conf`
- Start tunnels based on type (SSH, gcloud IAP, gcloud compute SSH, Flask, web servers)
- Stop tunnels by finding and killing processes
- Display macOS notifications for status changes
- Handle virtual environment activation for Python apps
- Auto-open browser for web-based services

**Tunnel Types Supported:**
1. **Regular SSH tunnels** - `ssh -L local:remote -p port host`
2. **SSH config aliases** - `ssh -L local:remote config-alias` (no port)
3. **Google Cloud IAP tunnels** - `gcloud compute start-iap-tunnel`
4. **Google Cloud Compute SSH** - `gcloud compute ssh vm-name -- -L port:localhost:port` (auto-opens browser)
5. **Flask apps** - Python Flask scripts that run HTTP proxies with IAP headers
6. **Python web servers** - Python http.server or similar (auto-opens browser)
7. **Two-layer tunnels** - SSH tunnel + Flask proxy (e.g., OSPortal API)

## Data Flow

### Notification Detection Flow

```
1. luxafor-notify.sh polls (every 1-5s)
   ↓
2. lsappinfo gets badge count for app
   ↓
3. AppleScript gets active window/channel
   ↓
4. Match against luxafor-channels.conf rules
   ↓
5. Calculate priority (if multiple notifications)
   ↓
6. Send color command to luxafor-cli
   ↓
7. Send Pushover alert (if configured)
```

### Menu Update Flow

```
1. luxafor-menu-daemon.sh wakes up (every 1s)
   ↓
2. Calls luxafor-toggle.1s.sh.backup
   ↓
3. Script queries:
   - Notification monitor status
   - Current app notifications
   - SSH tunnel PIDs
   - Configuration states
   ↓
4. Generates SwiftBar menu markup
   ↓
5. Writes to /tmp/luxafor-menu-cache.tmp
   ↓
6. Atomic move to /tmp/luxafor-menu-cache
   ↓
7. luxafor-toggle.5s.sh reads cache (every 5s)
   ↓
8. SwiftBar displays menu
```

### User Action Flow

```
User clicks menu item in SwiftBar
   ↓
SwiftBar executes bash command with params
   ↓
Command modifies state:
   - luxafor-control.sh (start/stop services)
   - tunnel-control.sh (start/stop tunnels)
   - Edit config files
   - Toggle enable/disable states
   ↓
Script triggers SwiftBar refresh
   ↓
Menu daemon picks up changes on next cycle
   ↓
Updated menu appears in SwiftBar
```

## Configuration Architecture

### Configuration Files

| File | Purpose | Format | Reload Behavior |
|------|---------|--------|-----------------|
| `luxafor-config.conf` | App definitions, colors, poll interval | `APP_NAME\|BADGE_NAME\|COLOR\|FLASH\|PUSHOVER` | Auto-reload on change |
| `luxafor-channels.conf` | Channel/folder specific rules | `APP\|CHANNEL_NAME\|COLOR\|FLASH\|PUSHOVER` | Auto-reload on change |
| `luxafor-enabled-apps.conf` | Enable/disable states | `APP_NAME=enabled/disabled` | Auto-reload on change |
| `luxafor-pushover.conf` | Pushover alert settings | `APP\|CHANNEL\|SOUND\|PRIORITY` | Auto-reload on change |
| `tunnels.conf` | SSH tunnel definitions | `NAME\|LOCAL_PORT\|REMOTE\|HOST\|PORT\|DESC` | Static (read on command) |

### Configuration Hierarchy

```
luxafor-config.conf (base app settings)
   ↓
luxafor-channels.conf (overrides for specific channels)
   ↓
luxafor-enabled-apps.conf (runtime enable/disable)
   ↓
luxafor-pushover.conf (alert customization)
```

**Priority Rules:**
- Channel-specific rules override app-level rules
- Disabled apps are skipped entirely
- Higher priority notifications win when multiple apps have badges

## Process Management

### LaunchAgent (Notification Monitor)

**Plist Location:** `~/Library/LaunchAgents/com.luxafor.notify.plist`

**Key Settings:**
- `KeepAlive`: true (auto-restart on crash)
- `RunAtLoad`: true (start on login)
- `StandardErrorPath`: `/tmp/luxafor-notify.stderr`
- `StandardOutPath`: `/tmp/luxafor-notify.stdout`

**Control Commands:**
```bash
launchctl load ~/Library/LaunchAgents/com.luxafor.notify.plist
launchctl unload ~/Library/LaunchAgents/com.luxafor.notify.plist
launchctl list | grep luxafor
```

### Background Process (Menu Daemon)

**PID File:** `/tmp/luxafor-menu-daemon.pid`
**Log File:** `/tmp/luxafor-menu-daemon.log`

**Lifecycle:**
1. Check for existing instance (prevent duplicates)
2. Write PID to file
3. Set up cleanup trap (EXIT, INT, TERM)
4. Enter main loop
5. On exit: remove PID file and cache

**Health Monitoring:**
- SwiftBar plugin checks PID file existence
- Validates process is still running via `ps -p`
- Checks cache freshness (age < 10 seconds)

## Performance Optimizations

### CPU Usage Reduction

**Problem:** Original design had SwiftBar calling full menu generation every 1 second.

**Solution:** Daemon + Cache architecture
- **Before:** 15-30% CPU usage on menu generation
- **After:** <5% CPU usage with cache reads
- **Reduction:** ~70% CPU savings

### Cache Freshness Strategy

**Cache Validation:**
- Menu plugin checks cache age before reading
- If cache >10 seconds old: display "stale cache" warning
- If daemon dead: display "daemon stopped" message
- Both cases: provide restart button

**Atomic Writes:**
```bash
# Write to temp file
echo "content" > /tmp/luxafor-menu-cache.tmp
# Atomic move (prevents partial reads)
mv /tmp/luxafor-menu-cache.tmp /tmp/luxafor-menu-cache
```

### Poll Interval Configuration

**Configurable via luxafor-config.conf:**
```
POLL_INTERVAL=1  # 1-5 seconds
```

**Trade-offs:**
- Lower interval: More responsive, higher CPU
- Higher interval: Less responsive, lower CPU
- Default: 1 second (good balance for most users)

## Security Considerations

### Credential Storage

**SSH Tunnels:**
- Uses SSH config aliases (credentials in `~/.ssh/config`)
- Uses gcloud credentials (managed by gcloud SDK)
- No plaintext passwords in configuration

**Pushover API:**
- API keys stored in `luxafor-pushover.conf`
- File permissions should be 600 (user read/write only)

**Flask Apps:**
- IAP headers injected by proxy scripts
- Email addresses in scripts (not passwords)
- Tunnels run as user process (not elevated)

### File Permissions

**Recommended:**
```bash
chmod 600 luxafor-pushover.conf  # Contains API keys
chmod 755 *.sh                   # Scripts executable
chmod 644 *.conf                 # Other configs readable
```

## Extension Points

### Adding New App Monitoring

1. Add entry to `luxafor-config.conf`
2. Define badge name (from `lsappinfo` output)
3. Set color and flash behavior
4. Add to `luxafor-enabled-apps.conf`

### Adding New Tunnel Types

1. Add entry to `tunnels.conf` with new type identifier
2. Update `tunnel-control.sh`:
   - Add detection logic in `start_tunnel()`
   - Add process finding logic in `stop_tunnel()`
3. Update `luxafor-toggle.1s.sh.backup`:
   - Add detection pattern for new tunnel type

### Custom Pushover Sounds

1. Add sound name to `luxafor-pushover.conf`
2. Sound must be available in Pushover app
3. Can set per-app or per-channel

## Debugging and Troubleshooting

### Debug Mode

**Enable:**
```bash
touch /Users/larry.craddock/Projects/luxafor/debug
```

**Disable:**
```bash
rm /Users/larry.craddock/Projects/luxafor/debug
```

**Log Location:** `/tmp/luxafor-debug.log`

### Log Files

| Component | Log Location |
|-----------|-------------|
| Notification Monitor | `/tmp/luxafor-notify.stdout` |
| Notification Monitor Errors | `/tmp/luxafor-notify.stderr` |
| Menu Daemon | `/tmp/luxafor-menu-daemon.log` |
| Debug Output | `/tmp/luxafor-debug.log` |
| Tunnel Control | `/tmp/tunnel-debug.log` |

### Common Issues

**Monitor Not Working:**
1. Check LaunchAgent: `launchctl list | grep luxafor`
2. Check stderr log: `tail /tmp/luxafor-notify.stderr`
3. Verify Luxafor device connected: `luxafor-cli --status`

**Menu Not Updating:**
1. Check daemon running: `ps aux | grep luxafor-menu-daemon`
2. Check cache age: `ls -lh /tmp/luxafor-menu-cache`
3. Check daemon log: `tail /tmp/luxafor-menu-daemon.log`

**SSH Tunnel Detection Wrong:**
1. Check tunnel config format in `tunnels.conf`
2. Verify process detection pattern in `luxafor-toggle.1s.sh.backup`
3. Test manual start: `/Users/larry.craddock/Projects/luxafor/tunnel-control.sh start <name>`

## File Structure Reference

```
/Users/larry.craddock/Projects/luxafor/
├── Core Scripts
│   ├── luxafor-notify.sh              # Main notification monitor
│   ├── luxafor-menu-daemon.sh         # Menu cache generator
│   ├── luxafor-toggle.5s.sh           # SwiftBar plugin (cache reader)
│   ├── luxafor-toggle.1s.sh.backup    # Menu content generator
│   ├── luxafor-control.sh             # Service control
│   └── tunnel-control.sh              # SSH tunnel control
│
├── Configuration Files
│   ├── luxafor-config.conf            # App settings
│   ├── luxafor-channels.conf          # Channel rules
│   ├── luxafor-enabled-apps.conf      # Enable/disable states
│   ├── luxafor-pushover.conf          # Pushover settings
│   └── tunnels.conf                   # SSH tunnel definitions
│
├── LaunchAgent
│   └── com.luxafor.notify.plist       # LaunchAgent definition
│
└── Documentation
    ├── README.md                      # User documentation
    ├── ARCHITECTURE.md                # This file
    ├── DEVELOPER.md                   # Developer guide
    └── SwiftBar_Menu_Documentation.md # Menu reference

/tmp/
├── luxafor-menu-cache                 # SwiftBar menu cache
├── luxafor-menu-daemon.pid            # Menu daemon PID
├── luxafor-menu-daemon.log            # Menu daemon log
├── luxafor-notify.stdout              # Monitor stdout
├── luxafor-notify.stderr              # Monitor stderr
├── luxafor-debug.log                  # Debug output
└── tunnel-debug.log                   # Tunnel control log
```

## Technology Stack

- **Shell:** Bash 3.2+ (macOS default)
- **macOS APIs:**
  - `lsappinfo` (badge counts)
  - `osascript` (AppleScript for window detection)
  - `launchctl` (LaunchAgent management)
- **Hardware:** Luxafor USB LED device (HID interface)
- **Menu Bar:** SwiftBar (BitBar fork)
- **External APIs:** Pushover (mobile notifications)
- **SSH Tools:** OpenSSH, gcloud SDK
- **Python:** Flask (for API proxy tunnels)

## Version History

This architecture evolved through several iterations:

1. **v1.0** - Single script monitoring with direct SwiftBar calls
2. **v2.0** - Split into monitor + menu generator
3. **v3.0** - Added daemon + cache architecture (70% CPU reduction)
4. **v3.1** - Added SSH tunnel integration
5. **v3.2** - Added Flask app support for API proxies
6. **v3.3** - Added duplicate instance protection

Current architecture represents v3.3+.
