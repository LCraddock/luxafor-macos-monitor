# Luxafor macOS Notification Monitor - Developer Guide

This guide covers common development tasks for extending and customizing the Luxafor notification system.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Adding New App Monitoring](#adding-new-app-monitoring)
3. [Modifying Detection Logic](#modifying-detection-logic)
4. [Adding New Tunnel Types](#adding-new-tunnel-types)
5. [Configuration File Formats](#configuration-file-formats)
6. [Common Customization Patterns](#common-customization-patterns)
7. [Testing and Debugging](#testing-and-debugging)
8. [Code Style and Conventions](#code-style-and-conventions)
9. [Common Pitfalls](#common-pitfalls)

---

## Getting Started

### Development Environment Setup

1. **Clone or locate the repository:**
   ```bash
   cd /Users/larry.craddock/Projects/luxafor
   ```

2. **Install dependencies:**
   - SwiftBar (for menu bar interface)
   - luxafor-cli (for LED control)
   - Optional: Pushover account for mobile alerts

3. **Enable debug mode:**
   ```bash
   touch debug
   tail -f /tmp/luxafor-debug.log
   ```

4. **Make changes to scripts:**
   - Edit scripts in your preferred editor
   - Scripts are executed directly (no compilation needed)
   - Remember to maintain executable permissions: `chmod +x script.sh`

5. **Test changes:**
   ```bash
   # Restart services to pick up changes
   ./luxafor-control.sh restart

   # Watch logs for issues
   tail -f /tmp/luxafor-notify.stderr
   tail -f /tmp/luxafor-menu-daemon.log
   ```

### Key Files for Development

| File | When to Edit | Restart Required |
|------|--------------|------------------|
| `luxafor-notify.sh` | Add app monitoring logic | Yes (monitor) |
| `luxafor-toggle.1s.sh.backup` | Modify menu structure | Yes (daemon) |
| `tunnel-control.sh` | Add tunnel types | No |
| `luxafor-config.conf` | Add apps, change colors | No (auto-reload) |
| `luxafor-channels.conf` | Add channel rules | No (auto-reload) |
| `tunnels.conf` | Add tunnels | No |

---

## Adding New App Monitoring

### Step 1: Find the Badge Name

Every macOS app that shows dock badges can be monitored. First, find the app's badge identifier:

```bash
# List all running apps and their badge counts
lsappinfo list | grep -i "appname"

# Get detailed info for a specific app
lsappinfo info -only bundleID -only StatusLabel <ASN>
```

**Example output:**
```
"StatusLabel"={ "label"="3" "badge"=3 }
"bundleID"="com.microsoft.Outlook"
```

The `label` value is what you'll use as the `BADGE_NAME` in configuration.

### Step 2: Add to Configuration

Edit `luxafor-config.conf` and add a new line:

```
APP_NAME|BADGE_NAME|COLOR|FLASH|PUSHOVER
```

**Example - Adding Discord monitoring:**

```bash
# 1. Find Discord's badge name
lsappinfo list | grep -i discord
# Output: "label"="Discord" "badge"=5

# 2. Add to luxafor-config.conf
echo "Discord|Discord|purple|0|0" >> luxafor-config.conf

# 3. Enable the app
echo "Discord=enabled" >> luxafor-enabled-apps.conf

# No restart needed - config auto-reloads
```

**Parameters Explained:**
- `APP_NAME`: Display name (used in menu)
- `BADGE_NAME`: Badge identifier from lsappinfo
- `COLOR`: Luxafor color (red, green, blue, yellow, purple, pink, etc.)
- `FLASH`: 0=solid, 1=flash
- `PUSHOVER`: 0=no alerts, 1=send Pushover notifications

### Step 3: Add Custom Detection (Optional)

If the app needs custom window title detection, edit `luxafor-notify.sh`:

```bash
# Add to the app-specific detection section
elif [ "$app" = "Discord" ]; then
    # Get current channel from window title
    current_channel=$(osascript -e 'tell application "Discord" to get name of front window' 2>/dev/null)
    debug_log "Discord current channel: $current_channel"
    # ... additional logic
fi
```

### Example: Adding Telegram Monitoring

**Complete example:**

```bash
# 1. Find badge name
lsappinfo list | grep -i telegram
# Output: "label"="Telegram" "badge"=2

# 2. Add configuration
cat >> luxafor-config.conf << 'EOF'
Telegram|Telegram|cyan|0|1
EOF

# 3. Enable app
echo "Telegram=enabled" >> luxafor-enabled-apps.conf

# 4. Test
# Send yourself a Telegram message
# Check debug log
tail -f /tmp/luxafor-debug.log
```

---

## Modifying Detection Logic

### Window Title Detection

The system uses AppleScript to detect active windows and extract channel/folder names.

**Location:** `luxafor-notify.sh` - Look for `get_teams_current_channel()` or similar functions.

**Example - Adding custom Slack workspace detection:**

```bash
# Function to get Slack workspace from window title
get_slack_workspace() {
    local window_title=$(osascript -e '
        tell application "Slack"
            if it is running then
                try
                    return name of front window
                end try
            end if
        end tell
    ' 2>/dev/null)

    # Extract workspace name from title
    # Title format: "channel-name | workspace-name"
    if [[ "$window_title" =~ \|\ (.+)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
}
```

### Badge Count Detection

Badge counts are retrieved using `lsappinfo`. The `get_badge_lsappinfo()` function handles this.

**Customization example - Add retry logic:**

```bash
get_badge_lsappinfo() {
    local app=$1
    local badge_name=$2
    local max_retries=3
    local retry=0

    while [ $retry -lt $max_retries ]; do
        # Get app ASN (Application Sequence Number)
        local asn=$(lsappinfo list | grep "\"$badge_name\"" | head -1 | sed 's/^[^"]*"\([^"]*\)".*/\1/')

        if [ -n "$asn" ]; then
            # Get badge value
            local badge=$(lsappinfo info -only StatusLabel "$asn" | grep -o '"badge"=[0-9]*' | grep -o '[0-9]*')
            echo "${badge:-0}"
            return 0
        fi

        ((retry++))
        sleep 0.1
    done

    echo "0"
}
```

### Channel Matching Logic

Channel-specific rules are matched in `luxafor-notify.sh` after detection.

**Example - Add fuzzy matching for channel names:**

```bash
# In the channel matching section
match_channel_fuzzy() {
    local app=$1
    local current_channel=$2

    # Loop through channel config
    for i in "${!CHANNEL_APP[@]}"; do
        if [ "${CHANNEL_APP[$i]}" = "$app" ]; then
            local channel_name="${CHANNEL_NAME[$i]}"

            # Exact match
            if [ "$channel_name" = "$current_channel" ]; then
                echo "$i"
                return 0
            fi

            # Fuzzy match (case-insensitive substring)
            if [[ "${current_channel,,}" == *"${channel_name,,}"* ]]; then
                echo "$i"
                return 0
            fi
        fi
    done
}
```

---

## Adding New Tunnel Types

### Step 1: Add Tunnel Configuration

Edit `tunnels.conf` and add your new tunnel:

```
NAME|LOCAL_PORT|REMOTE_SPEC|SSH_HOST|SSH_PORT|DESCRIPTION
```

**Example tunnel types:**

```bash
# Regular SSH tunnel
mysql|3306|localhost:3306|user@server.com|22|MySQL Database

# SSH config alias
gitlab|9443|localhost:443|gitlab|config|GitLab HTTPS

# Google Cloud IAP tunnel
instance-ssh|2222|instance-name:22|gcloud|iap|GCP Instance SSH

# Google Cloud Compute SSH tunnel (with port forwarding and auto-browser)
rocket|3000|redt-deb-intl-vm1|gcloud|compute-ssh|Rocket Chat

# Flask proxy
api-proxy|8080|/path/to/proxy.py|python|flask|API Proxy

# Python web server
claude-sessions|8765|/path/to/launcher.sh|python|webserver|Claude Sessions Browser
```

### Step 2: Add Start Logic

Edit `tunnel-control.sh` in the `start_tunnel()` function:

```bash
start_tunnel() {
    local config=$(get_tunnel_config "$TUNNEL")
    IFS='|' read -r local_port remote_spec ssh_host ssh_port description <<< "$config"

    # Add your new tunnel type detection
    if [ "$ssh_port" = "YOUR_TYPE" ] && [ "$ssh_host" = "YOUR_HOST" ]; then
        # Your custom start logic
        echo "Starting YOUR_TYPE tunnel: $description" >> /tmp/tunnel-debug.log

        # Example: Start a custom service
        /path/to/your/service --port "$local_port" &

    elif [ "$ssh_port" = "iap" ] && [ "$ssh_host" = "gcloud" ]; then
        # ... existing logic
    fi
}
```

### Step 3: Add Stop Logic

Edit `tunnel-control.sh` in the `stop_tunnel()` function:

```bash
stop_tunnel() {
    local config=$(get_tunnel_config "$TUNNEL")
    IFS='|' read -r local_port remote_spec ssh_host ssh_port description <<< "$config"

    # Add your process detection logic
    if [ "$ssh_port" = "YOUR_TYPE" ] && [ "$ssh_host" = "YOUR_HOST" ]; then
        # Find your process
        PID=$(ps aux | grep -E "your_process_pattern" | grep -v grep | awk '{print $2}')

    elif [ "$ssh_port" = "flask" ] && [ "$ssh_host" = "python" ]; then
        # ... existing logic
    fi

    # Common kill logic (runs for all types)
    if [ -n "$PID" ]; then
        kill $PID
    fi
}
```

### Step 4: Add Menu Detection

Edit `luxafor-toggle.1s.sh.backup` to detect your tunnel type in the menu:

```bash
# In the SSH Tunnels section, find the tunnel detection block
if [ "$ssh_port" = "YOUR_TYPE" ] && [ "$ssh_host" = "YOUR_HOST" ]; then
    # Detect your process
    tunnel_pid=$(ps aux | grep -E "your_process_pattern" | grep -v grep | awk '{print $2}')

elif [ "$ssh_port" = "iap" ] && [ "$ssh_host" = "gcloud" ]; then
    # ... existing logic
fi
```

### Complete Example: Adding WireGuard VPN Support

```bash
# 1. Add to tunnels.conf
wireguard-vpn|51820|wg0|wireguard|vpn|WireGuard VPN

# 2. Add start logic to tunnel-control.sh
elif [ "$ssh_port" = "vpn" ] && [ "$ssh_host" = "wireguard" ]; then
    # remote_spec contains interface name (wg0)
    interface="$remote_spec"
    echo "Starting WireGuard interface: $interface" >> /tmp/tunnel-debug.log
    sudo wg-quick up "$interface" 2>> /tmp/tunnel-debug.log &

# 3. Add stop logic to tunnel-control.sh
elif [ "$ssh_port" = "vpn" ] && [ "$ssh_host" = "wireguard" ]; then
    # Check if WireGuard interface is up
    if ip link show "$remote_spec" > /dev/null 2>&1; then
        PID="active"  # Dummy PID to trigger kill section
        # We'll handle stop separately
        sudo wg-quick down "$remote_spec"
    fi

# 4. Add menu detection to luxafor-toggle.1s.sh.backup
elif [ "$ssh_port" = "vpn" ] && [ "$ssh_host" = "wireguard" ]; then
    # Check if interface exists
    if ip link show "$remote_spec" > /dev/null 2>&1; then
        tunnel_pid="active"
    fi
```

---

## Configuration File Formats

### luxafor-config.conf

**Format:**
```
APP_NAME|BADGE_NAME|COLOR|FLASH|PUSHOVER
```

**Fields:**
- `APP_NAME`: Display name (used in menus and logs)
- `BADGE_NAME`: Badge label from lsappinfo output
- `COLOR`: Luxafor color name (see available colors below)
- `FLASH`: 0 (solid) or 1 (flashing)
- `PUSHOVER`: 0 (no alerts) or 1 (send mobile notifications)

**Available Colors:**
```
red, green, blue, white, yellow, magenta, cyan, orange, purple, pink,
brown, gray, grey, lime, navy, maroon, olive, silver, teal, aqua,
fuchsia, indigo, violet, gold, coral, salmon, khaki, plum, tan, crimson,
black (off)
```

**Special Configuration:**
```
POLL_INTERVAL=1  # Poll apps every N seconds (1-5)
```

**Example:**
```
Teams|Microsoft Teams|blue|0|1
Slack|Slack|yellow|0|1
Outlook|Outlook|orange|1|1
POLL_INTERVAL=2
```

### luxafor-channels.conf

**Format:**
```
APP_NAME|CHANNEL_NAME|COLOR|FLASH|PUSHOVER
```

**Purpose:** Override app-level settings for specific channels/folders/chats.

**Example:**
```
# High-priority Slack channels
Slack|security-alerts|red|1|1
Slack|incidents|red|1|1
Slack|general|yellow|0|0

# Important Teams chats
Teams|Security Team|red|1|1
Teams|General|blue|0|0

# Outlook folder monitoring
Outlook|phishing|red|1|1
Outlook|inbox|orange|0|1
```

### luxafor-enabled-apps.conf

**Format:**
```
APP_NAME=enabled
APP_NAME=disabled
```

**Purpose:** Runtime enable/disable without removing configuration.

**Example:**
```
Teams=enabled
Slack=enabled
Outlook=disabled
Zoom=enabled
```

### luxafor-pushover.conf

**Format:**
```
APP_NAME|CHANNEL_NAME|SOUND|PRIORITY
```

**Fields:**
- `APP_NAME`: App name (must match config)
- `CHANNEL_NAME`: Channel/folder name (use `*` for app-level default)
- `SOUND`: Pushover sound name
- `PRIORITY`: -2 (silent), -1 (quiet), 0 (normal), 1 (high), 2 (emergency)

**Pushover Sounds:**
```
pushover, bike, bugle, cashregister, classical, cosmic, falling,
gamelan, incoming, intermission, magic, mechanical, pianobar,
siren, spacealarm, tugboat, alien, climb, persistent, echo, updown, none
```

**Example:**
```
# App-level defaults
Teams|*|pushover|0
Slack|*|cosmic|0
Outlook|*|mechanical|-1

# Channel-specific overrides
Slack|security-alerts|siren|2
Slack|incidents|siren|1
Teams|Security Team|siren|2
Outlook|phishing|alien|1
```

### tunnels.conf

**Format:**
```
NAME|LOCAL_PORT|REMOTE_SPEC|SSH_HOST|SSH_PORT|DESCRIPTION
```

**Tunnel Types:**

1. **Regular SSH tunnel:**
   ```
   postgres|5432|localhost:5432|user@db.example.com|22|PostgreSQL
   ```

2. **SSH config alias:**
   ```
   gitlab|9443|localhost:443|gitlab|config|GitLab HTTPS
   ```

3. **Google Cloud IAP:**
   ```
   NAME|LOCAL_PORT|instance:remote_port|gcloud|iap|DESCRIPTION
   ```
   Example:
   ```
   gcp-ssh|2222|my-instance:22|gcloud|iap|GCP Instance
   ```

4. **Google Cloud Compute SSH:**
   ```
   NAME|LOCAL_PORT|vm-name|gcloud|compute-ssh|DESCRIPTION
   ```
   Example:
   ```
   rocket|3000|redt-deb-intl-vm1|gcloud|compute-ssh|Rocket Chat
   ```
   Features: Auto-opens browser to http://localhost:PORT on start

5. **Flask app proxy:**
   ```
   NAME|LOCAL_PORT|/path/to/script.py|python|flask|DESCRIPTION
   ```
   Example:
   ```
   api-proxy|8888|/Users/user/proxy.py|python|flask|API Proxy
   ```

6. **Python web server:**
   ```
   NAME|LOCAL_PORT|/path/to/launcher.sh|python|webserver|DESCRIPTION
   ```
   Example:
   ```
   claude-sessions|8765|/path/to/claude-sessions|python|webserver|Claude Sessions Browser
   ```
   Features: Auto-opens browser to http://localhost:PORT on start

---

## Common Customization Patterns

### Pattern 1: Add Priority-Based Color

Set higher priority channels to override app colors:

```bash
# In luxafor-notify.sh, modify priority calculation
calculate_priority() {
    local app=$1
    local channel=$2

    # Critical channels get priority 100
    if [[ "$channel" == "security-alerts" ]] || [[ "$channel" == "incidents" ]]; then
        echo "100"
    # High priority apps get 50
    elif [[ "$app" == "Teams" ]] || [[ "$app" == "Slack" ]]; then
        echo "50"
    # Everything else gets 10
    else
        echo "10"
    fi
}
```

### Pattern 2: Time-Based Behavior

Change LED behavior based on time of day:

```bash
# In luxafor-notify.sh, before setting color
current_hour=$(date +%H)

# Quiet hours: 10 PM - 8 AM
if [ $current_hour -ge 22 ] || [ $current_hour -lt 8 ]; then
    # Disable flashing during quiet hours
    flash=0
    # Skip Pushover alerts
    send_pushover=0
fi
```

### Pattern 3: Notification Threshold

Only alert after N unread messages:

```bash
# Add threshold check before setting LED
NOTIFICATION_THRESHOLD=5

if [ $badge_count -lt $NOTIFICATION_THRESHOLD ]; then
    # Below threshold - use dim color or skip
    debug_log "Below threshold ($badge_count < $NOTIFICATION_THRESHOLD), skipping"
    continue
fi
```

### Pattern 4: Multi-Stage Escalation

Change color based on how long notification has been unread:

```bash
# Track when notification first appeared
declare -A notification_timestamps

check_notification_age() {
    local app=$1
    local current_time=$(date +%s)

    if [ -z "${notification_timestamps[$app]}" ]; then
        # First time seeing notification
        notification_timestamps[$app]=$current_time
        echo "new"
    else
        # Calculate age
        local age=$((current_time - ${notification_timestamps[$app]}))

        if [ $age -gt 300 ]; then  # 5 minutes
            echo "urgent"
        elif [ $age -gt 60 ]; then  # 1 minute
            echo "warning"
        else
            echo "normal"
        fi
    fi
}

# Use in color selection
age=$(check_notification_age "$app")
case "$age" in
    "new")     color="blue" ;;
    "normal")  color="yellow" ;;
    "warning") color="orange" ;;
    "urgent")  color="red"; flash=1 ;;
esac
```

### Pattern 5: Keyword-Based Alerts

Scan notification content for keywords:

```bash
# Get notification content (requires additional AppleScript)
get_notification_content() {
    osascript -e '
        tell application "System Events"
            tell process "Notification Center"
                try
                    return value of static text of window 1
                end try
            end tell
        end tell
    ' 2>/dev/null
}

# Check for keywords
content=$(get_notification_content)
if [[ "$content" =~ (urgent|critical|security|breach) ]]; then
    color="red"
    flash=1
    priority=2  # Emergency Pushover
fi
```

---

## Testing and Debugging

### Enable Debug Logging

```bash
# Enable
touch /Users/larry.craddock/Projects/luxafor/debug

# Watch logs
tail -f /tmp/luxafor-debug.log

# Disable
rm /Users/larry.craddock/Projects/luxafor/debug
```

### Test Individual Components

**Test badge detection:**
```bash
# Run detection manually
lsappinfo list | grep -E "(Slack|Teams|Outlook)"

# Test badge extraction
asn=$(lsappinfo list | grep "Slack" | head -1 | sed 's/^[^"]*"\([^"]*\)".*/\1/')
lsappinfo info -only StatusLabel "$asn"
```

**Test window detection:**
```bash
# Get current window title
osascript -e 'tell application "Slack" to get name of front window'
osascript -e 'tell application "Microsoft Teams" to get name of front window'
```

**Test Luxafor commands:**
```bash
luxafor-cli --color red
luxafor-cli --flash green
luxafor-cli --off
```

**Test tunnel start/stop:**
```bash
# Enable debug
tail -f /tmp/tunnel-debug.log &

# Test start
/Users/larry.craddock/Projects/luxafor/tunnel-control.sh start osportal-api

# Check process
ps aux | grep osportal_api.py

# Test stop
/Users/larry.craddock/Projects/luxafor/tunnel-control.sh stop osportal-api
```

### Common Debug Scenarios

**Monitor not detecting app:**
```bash
# 1. Verify app is in config
grep "AppName" luxafor-config.conf

# 2. Verify app is enabled
grep "AppName" luxafor-enabled-apps.conf

# 3. Check badge name
lsappinfo list | grep -i "appname"

# 4. Check monitor logs
grep "AppName" /tmp/luxafor-debug.log
```

**Channel not matching:**
```bash
# 1. Enable debug mode
touch debug

# 2. Trigger notification
# (send message to channel)

# 3. Check detection
tail -20 /tmp/luxafor-debug.log | grep -A5 "current_channel"

# 4. Verify channel config
grep "ChannelName" luxafor-channels.conf
```

**Tunnel not showing in menu:**
```bash
# 1. Check tunnel config
cat tunnels.conf | grep "tunnel-name"

# 2. Verify process is running
ps aux | grep "tunnel-pattern"

# 3. Check menu cache
grep "tunnel-name" /tmp/luxafor-menu-cache

# 4. Restart menu daemon
./luxafor-control.sh restart
```

### Performance Testing

**Monitor CPU usage:**
```bash
# Before optimization
top -pid $(pgrep -f luxafor-notify) -stats cpu,mem -l 10

# After optimization
top -pid $(pgrep -f luxafor-notify) -stats cpu,mem -l 10
```

**Measure poll interval impact:**
```bash
# Test with different intervals
echo "POLL_INTERVAL=1" > test-config.conf
# ... monitor CPU for 1 minute

echo "POLL_INTERVAL=5" > test-config.conf
# ... monitor CPU for 1 minute
```

---

## Code Style and Conventions

### Naming Conventions

**Variables:**
```bash
# Global config arrays - UPPERCASE
declare -a APP_NAME
declare -a APP_BADGE

# Function parameters - lowercase
get_badge_count() {
    local app_name=$1
    local badge_name=$2
}

# File paths - UPPERCASE
SCRIPT_DIR="/Users/larry.craddock/Projects/luxafor"
CONFIG_FILE="$SCRIPT_DIR/luxafor-config.conf"

# Temporary values - lowercase
current_channel=$(get_channel_name)
badge_count=$(get_badge_lsappinfo "$app")
```

**Functions:**
```bash
# Use snake_case for function names
get_badge_lsappinfo() { ... }
load_channel_config() { ... }
send_pushover_alert() { ... }

# Use descriptive names
# Good:
check_outlook_special_folder() { ... }

# Bad:
chk_ol_fld() { ... }
```

### Comments

**Function headers:**
```bash
# Get badge count using lsappinfo
# Args:
#   $1 - app name
#   $2 - badge name
# Returns:
#   Badge count (0 if not found)
get_badge_lsappinfo() {
    # Implementation
}
```

**Inline comments:**
```bash
# Skip comments and empty lines
[[ "$line" =~ ^#.*$ ]] && continue

# Parse config line format: APP|BADGE|COLOR|FLASH|PUSHOVER
IFS='|' read -r app badge color flash pushover <<< "$line"
```

### Error Handling

**Check command success:**
```bash
if ! luxafor-cli --color "$color"; then
    debug_log "ERROR: Failed to set color $color"
    return 1
fi
```

**Validate inputs:**
```bash
if [ -z "$app" ] || [ -z "$badge" ]; then
    debug_log "ERROR: Missing required parameters"
    return 1
fi
```

**Provide fallbacks:**
```bash
# Try primary method
badge=$(get_badge_lsappinfo "$app" "$badge_name")

# Fallback to alternative
if [ -z "$badge" ] || [ "$badge" = "0" ]; then
    badge=$(get_badge_alternative "$app")
fi

# Default value
echo "${badge:-0}"
```

### Configuration Parsing

**Consistent format:**
```bash
# Always skip comments and empty lines
while IFS='|' read -r field1 field2 field3; do
    # Skip comments
    [[ "$field1" =~ ^#.*$ ]] && continue

    # Skip empty lines
    [ -z "$field1" ] && continue

    # Process line
    # ...
done < "$CONFIG_FILE"
```

---

## Common Pitfalls

### 1. File Permission Issues

**Problem:** Scripts not executable or configs not readable.

**Solution:**
```bash
# Make scripts executable
chmod +x *.sh

# Secure sensitive configs
chmod 600 luxafor-pushover.conf

# Make other configs readable
chmod 644 *.conf
```

### 2. Config Not Auto-Reloading

**Problem:** Changes to config not taking effect.

**Cause:** Monitor caches config in memory, only reloads on change detection.

**Solution:**
```bash
# Force reload by restarting monitor
./luxafor-control.sh restart

# Or touch the config file to trigger reload
touch luxafor-config.conf
```

### 3. AppleScript Timeout

**Problem:** Window detection hangs or times out.

**Cause:** App not responding or accessibility permissions missing.

**Solution:**
```bash
# Add timeout to AppleScript calls
osascript -e 'with timeout of 2 seconds
    tell application "Slack"
        get name of front window
    end tell
end timeout' 2>/dev/null
```

### 4. Process Detection False Positives

**Problem:** Tunnel detection matches wrong process.

**Cause:** Grep pattern too broad.

**Solution:**
```bash
# Bad - matches too much
ps aux | grep python

# Good - specific pattern
ps aux | grep -E "python.*osportal_api\.py" | grep -v grep

# Better - use pgrep with full command
pgrep -f "python.*osportal_api\.py"
```

### 5. Race Conditions in Cache

**Problem:** SwiftBar reads partial/corrupted cache.

**Cause:** Non-atomic writes to cache file.

**Solution:**
```bash
# Bad - direct write
echo "content" > /tmp/luxafor-menu-cache

# Good - atomic write
echo "content" > /tmp/luxafor-menu-cache.tmp
mv /tmp/luxafor-menu-cache.tmp /tmp/luxafor-menu-cache
```

### 6. Badge Name Changes

**Problem:** App updates change badge label format.

**Cause:** App developer changed how badges are labeled.

**Solution:**
```bash
# Check current badge name
lsappinfo list | grep -i "AppName"

# Update config with new badge name
# OLD: Teams|Microsoft Teams|blue|0|1
# NEW: Teams|MS Teams|blue|0|1
```

### 7. Memory Leaks in Long-Running Scripts

**Problem:** Daemon consumes increasing memory over time.

**Cause:** Arrays/variables not cleared between iterations.

**Solution:**
```bash
# Clear arrays before reloading config
APP_NAME=()
APP_BADGE=()
APP_COLOR=()

# Load fresh config
load_config
```

### 8. LaunchAgent Not Auto-Starting

**Problem:** Monitor doesn't start on login.

**Cause:** LaunchAgent plist not loaded.

**Solution:**
```bash
# Load the LaunchAgent
launchctl load ~/Library/LaunchAgents/com.luxafor.notify.plist

# Verify it's loaded
launchctl list | grep luxafor

# Check for errors
launchctl error luxafor
```

### 9. SwiftBar Menu Not Updating

**Problem:** Menu shows stale data or doesn't refresh.

**Cause:** Menu daemon crashed or cache is stale.

**Solution:**
```bash
# Check daemon status
ps aux | grep luxafor-menu-daemon

# Check cache age
ls -lh /tmp/luxafor-menu-cache

# Restart daemon
./luxafor-control.sh restart

# Force SwiftBar refresh
open -g "swiftbar://refreshallplugins"
```

### 10. Pushover Alerts Not Sending

**Problem:** Mobile notifications not delivered.

**Causes:**
1. Invalid API keys
2. Network connectivity
3. Rate limiting

**Solution:**
```bash
# Test Pushover manually
curl -s \
  -F "token=YOUR_APP_TOKEN" \
  -F "user=YOUR_USER_KEY" \
  -F "message=Test message" \
  https://api.pushover.net/1/messages.json

# Check debug log for Pushover errors
grep -i pushover /tmp/luxafor-debug.log

# Verify config format
cat luxafor-pushover.conf
```

---

## Quick Reference

### Restart Services

```bash
./luxafor-control.sh restart
```

### View Logs

```bash
tail -f /tmp/luxafor-debug.log
tail -f /tmp/luxafor-notify.stderr
tail -f /tmp/luxafor-menu-daemon.log
```

### Test LED

```bash
luxafor-cli --color red
luxafor-cli --flash green
luxafor-cli --off
```

### Reload Configuration

```bash
# Auto-reload (just edit the file)
vim luxafor-config.conf

# Force reload
./luxafor-control.sh restart
```

### Check Process Status

```bash
# Monitor daemon
ps aux | grep luxafor-notify.sh

# Menu daemon
ps aux | grep luxafor-menu-daemon.sh

# LaunchAgent
launchctl list | grep luxafor
```

---

## Getting Help

1. **Check logs first:**
   - `/tmp/luxafor-debug.log` (enable debug mode first)
   - `/tmp/luxafor-notify.stderr`
   - `/tmp/luxafor-menu-daemon.log`

2. **Review documentation:**
   - `README.md` - User guide
   - `ARCHITECTURE.md` - System design
   - `SwiftBar_Menu_Documentation.md` - Menu reference

3. **Test components individually:**
   - Badge detection: `lsappinfo list`
   - Window detection: `osascript -e '...'`
   - LED control: `luxafor-cli`

4. **Enable verbose debugging:**
   ```bash
   touch debug
   tail -f /tmp/luxafor-debug.log
   ```

5. **Check permissions:**
   ```bash
   ls -la *.sh *.conf
   # Scripts should be executable (755)
   # Configs should be readable (644)
   ```

Happy developing! 🚀
