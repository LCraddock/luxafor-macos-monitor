# Luxafor Monitor Enhancement Plan: Channel/Folder Monitoring

## Overview
Extend the current monitoring system to support granular control over specific channels (Teams/Slack) and folders (Outlook), with SwiftBar submenus and enhanced Pushover rules.

## Phase 1: Unified Configuration System

### 1.1 New Config Format
Create a unified config structure that supports sub-items for any app:

```bash
# luxafor-channels.conf
# Format: AppName|Type|Name|Color|Action|PushoverPriority|PushoverSound

# Teams channels
Teams|channel|General|red|solid|0|default
Teams|channel|Security Alerts|red|flash|2|siren
Teams|channel|Dev Team|blue|solid|0|none

# Slack channels  
Slack|channel|#general|green|solid|0|default
Slack|channel|#incidents|yellow|flash|2|alien
Slack|channel|#random|green|solid|0|none

# Outlook folders (extend existing)
Outlook|folder|Inbox|blue|solid|0|default
Outlook|folder|Phishing|yellow|flash|2|siren
Outlook|folder|VIP|cyan|solid|1|tugboat
```

### 1.2 Enable/Disable State File
Track enabled state for each channel/folder:

```bash
# luxafor-channels-enabled.conf
Teams|channel|General|enabled
Teams|channel|Security Alerts|enabled
Teams|channel|Dev Team|disabled
Slack|channel|#general|enabled
```

## Phase 2: Detection Implementation

### 2.1 Teams Channel Detection
Teams is tricky - might need one of:
- AppleScript to read Teams window/notification content
- Monitor Teams notification text for channel names
- Use Teams Graph API with authentication
- Parse Teams local database/cache files

### 2.2 Slack Channel Detection  
Options for Slack:
- AppleScript to read Slack's accessibility elements
- Slack Web API (requires OAuth token)
- Monitor macOS notification center for channel info
- Parse Slack's local IndexedDB/storage

### 2.3 Extend Outlook Implementation
- Already have folder detection working
- Just need to integrate with new config system

## Phase 3: SwiftBar Menu Enhancement

### 3.1 Submenu Structure
```
☑ Teams ➤
  ☑ All Teams Notifications
  ---
  ☑ General
  ☑ Security Alerts  
  ☐ Dev Team
  
☑ Slack ➤
  ☑ All Slack Notifications
  ---
  ☑ #general
  ☑ #incidents
  ☐ #random

☑ Outlook ➤
  ☑ All Outlook Notifications
  ---
  ☑ Inbox
  ☑ Phishing
  ☑ VIP
```

### 3.2 Menu Implementation
- Main checkbox controls all notifications for that app
- Submenu items control individual channels/folders
- "All X Notifications" as a master toggle within submenu

## Phase 4: Enhanced Pushover Integration

### 4.1 Granular Rules
- Each channel/folder can have its own Pushover settings
- Priority levels and sounds per channel
- Option to disable Pushover for specific channels (sound: "none")

### 4.2 Smart Notifications
- Different urgency levels based on channel
- Quiet hours for non-critical channels
- Rate limiting per channel

## Phase 5: Implementation Steps

1. **Create new config files and parsers**
   - Unified channel/folder config
   - Enhanced enabled/disabled tracking

2. **Implement detection for Teams/Slack**
   - Research and test detection methods
   - Fallback to app-level if channel detection fails

3. **Update monitoring loop**
   - Check channel-specific rules first
   - Fall back to app-level rules
   - Handle color/flash per channel

4. **SwiftBar menu system**
   - Generate dynamic submenus
   - Handle checkbox states
   - Update state files on toggle

5. **Enhance Pushover logic**
   - Per-channel notification rules
   - Smart message formatting with channel info

## Technical Considerations

- **Performance**: Channel detection might be slower than badge detection
- **Reliability**: Need fallbacks if channel detection fails
- **Permissions**: May need accessibility permissions for Teams/Slack
- **Backward Compatibility**: Keep existing configs working

## Future Enhancements

- Email sender filtering for Outlook
- Keyword alerts across all apps
- Time-based rules (different colors during work hours)
- Integration with Focus modes
- Web dashboard for configuration