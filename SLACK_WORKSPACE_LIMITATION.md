# Slack Multi-Workspace Limitation

## Known Issue
When using multiple Slack workspaces, notifications from inactive workspaces may be incorrectly attributed to the currently visible channel in your active workspace.

### Example Scenario
- You're viewing the `telegram-tmp` channel in your corporate Slack workspace
- You receive a message in the Craddock workspace
- The Luxafor will light up correctly, but the notification will be identified as coming from `telegram-tmp` instead of the Craddock workspace

## Why This Happens

1. **macOS Limitation**: `lsappinfo` only provides the total badge count for Slack, not workspace-specific information
2. **Slack UI Limitation**: Slack doesn't expose its workspace UI elements to AppleScript for detection
3. **Window Detection**: The script reads the window title to identify the notification source, which shows the current channel

## Technical Details

We attempted several approaches to solve this:
- **AppleScript UI Detection**: Slack's custom rendering doesn't expose workspace badges as UI elements
- **Screen Capture + OCR**: Requires Slack window to be visible/on top, making it impractical for background monitoring
- **Pixel Color Detection**: Same visibility requirement as OCR

## Workarounds

### Option 1: Switch to Home View
When you get a notification and want accurate detection:
1. Switch to Slack's home view (not a specific channel)
2. The script will detect it as a generic Slack notification rather than misattributing it

### Option 2: Configure Channel Exclusions
If certain channels frequently cause misattribution:
1. Remove them from `luxafor-channels.conf`
2. Or set them to `enabled|false`

### Option 3: Visual Cues
Since the LED color is correct (based on Slack's priority), you can:
- Use different colors for different workspace priorities
- Rely on the LED color rather than the notification text

## Future Improvements

If Slack later provides:
- Better API access to workspace information
- Accessibility improvements that expose UI elements
- Workspace-specific bundle IDs or status labels

Then this limitation could be resolved.

## Configuration Note

Despite this limitation, the system still correctly:
- Detects that Slack has notifications
- Shows the appropriate LED color based on Slack's priority
- Sends Pushover notifications (though with incorrect channel attribution)
- Clears the LED when all notifications are read

The only issue is the attribution of the notification source when multiple workspaces are involved.