#!/usr/bin/env bash
#
# test-slack-workspace-detection.sh
# Test the new Slack workspace badge detection function
#

# Source the functions from luxafor-notify.sh
source /Users/larry.craddock/Projects/luxafor/luxafor-notify.sh 2>/dev/null

echo "=== Slack Workspace Detection Test ==="
echo ""

# Test current channel detection
echo "1. Testing current channel detection..."
current_info=$(get_slack_current_channel)
if [[ -n "$current_info" ]]; then
    IFS='|' read -r channel_name channel_type <<< "$current_info"
    echo "   ✅ Active workspace channel: '$channel_name' (Type: $channel_type)"
else
    echo "   ❌ No active channel detected (Slack may not be focused or open)"
fi

echo ""

# Test workspace badge detection  
echo "2. Testing workspace badge detection..."
workspace_badge=$(get_slack_workspace_with_badge)
if [[ -n "$workspace_badge" ]]; then
    echo "   ✅ Found workspace with badge: '$workspace_badge'"
else
    echo "   ℹ️  No workspace badges detected currently"
fi

echo ""

# Test badge count
echo "3. Testing Slack badge count..."
badge_count=$(get_badge_lsappinfo "com.tinyspeck.slackmacgap")
echo "   Current Slack dock badge count: $badge_count"

echo ""
echo "=== Test Complete ==="

if [[ "$badge_count" -gt 0 ]]; then
    echo ""
    echo "🔔 You currently have Slack notifications!"
    if [[ -n "$current_info" ]]; then
        echo "   → Active channel detected: $channel_name"
    elif [[ -n "$workspace_badge" ]]; then
        echo "   → Workspace badge detected: $workspace_badge"
    else
        echo "   → Using new logic, this would be treated as multi-workspace notification"
    fi
fi
