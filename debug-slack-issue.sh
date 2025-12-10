#!/usr/bin/env bash

echo "=== Debugging Slack Multi-Workspace Issue ==="

# Source the functions
source /Users/larry.craddock/Projects/luxafor/luxafor-notify.sh

echo "1. Checking Slack badge count..."
badge_count=$(get_badge_lsappinfo "com.tinyspeck.slackmacgap")
echo "Badge count: $badge_count"

echo ""
echo "2. Testing current channel detection..."
current_info=$(get_slack_current_channel)
if [[ -n "$current_info" ]]; then
    IFS='|' read -r channel_name channel_type <<< "$current_info"
    echo "Active channel: '$channel_name' (Type: $channel_type)"
else
    echo "No active channel detected"
fi

echo ""
echo "3. Testing workspace badge detection..."
workspace_badge=$(get_slack_workspace_with_badge)
if [[ -n "$workspace_badge" ]]; then
    echo "Workspace with badge: '$workspace_badge'"
else
    echo "No workspace badges detected"
fi

echo ""
echo "4. Checking _all_dms configuration..."
for i in "${!CHANNEL_APPS[@]}"; do
    if [[ "${CHANNEL_APPS[$i]}" == "Slack" ]] && \
       [[ "${CHANNEL_TYPES[$i]}" == "dm" ]] && \
       [[ "${CHANNEL_NAMES[$i]}" == "_all_dms" ]]; then
        echo "_all_dms found: enabled=${CHANNEL_ENABLED[$i]}"
        echo "Color: ${CHANNEL_COLORS[$i]}"
        echo "Sound: ${CHANNEL_SOUNDS[$i]}"
    fi
done

echo ""
echo "5. Simulating the logic flow..."
if [[ "$badge_count" -gt 0 ]]; then
    echo "✅ Badge detected, proceeding with logic"
    
    if [[ -n "$current_info" ]]; then
        echo "✅ Current channel detected - normal flow"
    else
        echo "❌ Current channel NOT detected - entering workspace detection"
        
        if [[ -n "$workspace_badge" ]]; then
            echo "✅ Workspace badge found - should work"
        else
            echo "❌ No workspace badge - this is where it fails!"
        fi
    fi
else
    echo "❌ No badge detected at all"
fi

echo ""
echo "=== Analysis Complete ==="
