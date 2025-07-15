# Implementation Notes

## Channel-Specific Monitoring

### Completed Features

1. **Outlook Folder-Specific Monitoring** ✓
   - Migrated from old config to unified `luxafor-channels.conf`
   - Each folder has individual color, flash mode, and Pushover settings
   - SwiftBar submenus with individual folder toggles
   - Removed "all folders" fallback - ONLY alerts on configured folders
   - Fixed all issues: Pushover priority 2, duplicate processes, config corruption

### In Progress

2. **Teams Channel Detection**
   - Window title format: `Type | Channel/Chat Name | Microsoft Teams`
   - Can extract channel/chat name from window title
   - Strategy:
     - All chats/DMs alert by default
     - Channels only alert if explicitly configured
   - Config format:
     ```
     Teams|chat|_all_chats|blue|solid|0|pushover|true
     Teams|channel|Security Alerts|red|flash|2|siren|true
     ```

### Planned

3. **Slack Channel Detection**
   - Similar approach to Teams
   - Detect window title or use accessibility API
   - Same strategy: all DMs alert, channels only if configured

## Technical Details

### Teams Detection
- Process name: `Microsoft Teams` (bundle: `com.microsoft.teams2`)
- Has notification center: `com.microsoft.teams2.notificationcenter`
- Window title parsing works reliably
- Need to test different scenarios:
  - Channel vs Chat distinction
  - Group chats vs 1:1 chats
  - Meeting windows

### SwiftBar Menu Structure
For apps with channels:
```
☑ Teams ▸
  Teams:
  -----
  ☑ All Chats
  -----
  ☑ Security Alerts
  ☐ Incidents
```

### State Management
- Each channel/folder can be individually enabled/disabled
- State persists in `luxafor-channels.conf`
- Toggle script preserves formatting and comments
- Monitor restarts automatically on config changes

## Current Architecture

1. **luxafor-notify.sh**: Main monitoring script
   - Polls badge counts and special folders/channels
   - Determines highest priority notification
   - Controls LED color/flash
   - Sends Pushover alerts on state changes

2. **luxafor-toggle.1s.sh**: SwiftBar menu plugin
   - Shows current notification status
   - Provides app/channel toggles
   - Launches config editors
   - Shows submenu for apps with channels

3. **luxafor-channels.conf**: Unified channel configuration
   - Format: `AppName|Type|Name|Color|Action|PushoverPriority|PushoverSound|Enabled`
   - Supports folders, channels, chats
   - Individual settings per item

4. **toggle-channel.sh**: Individual channel toggle script
   - Updates enabled state in config
   - Preserves formatting
   - Triggers monitor restart