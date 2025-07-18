#!/usr/bin/env bash
#
# test-teams-channel-detection.sh 
# Test Teams channel detection implementation
#

echo "=== Testing Teams Channel Detection ==="
echo

# Function to get current Teams channel/chat
get_teams_current_channel() {
    local window_title=$(osascript -e 'tell application "System Events" to tell process "Microsoft Teams" to name of window 1' 2>/dev/null)
    
    if [[ -z "$window_title" ]]; then
        echo ""
        return
    fi
    
    # Parse the window title
    # Format is usually: "Type | Channel/Chat Name | Microsoft Teams"
    if [[ "$window_title" == *" | "* ]]; then
        # Use parameter expansion to extract the middle part
        # Remove everything up to and including the first " | "
        local after_first="${window_title#* | }"
        # Remove everything from the last " | " onwards
        local channel_name="${after_first% | *}"
        echo "$channel_name"
    else
        echo ""
    fi
}

# Test the function
echo "Current Teams channel/chat:"
CHANNEL=$(get_teams_current_channel)
echo "  '$CHANNEL'"

echo
echo "Testing with configured channels:"
echo "  Checking if current channel matches any configured ones..."

# Simulate checking against configured channels
CONFIGURED_CHANNELS=("Project GUAVA: Penetration Testing" "General" "Security Alerts")

for config_channel in "${CONFIGURED_CHANNELS[@]}"; do
    if [[ "$CHANNEL" == "$config_channel" ]]; then
        echo "  ✓ Match found: $config_channel"
    else
        echo "  ✗ No match: $config_channel"
    fi
done

echo
echo "Monitoring window title changes (10 seconds):"
for i in {1..10}; do
    CHANNEL=$(get_teams_current_channel)
    echo "  $i: $CHANNEL"
    sleep 1
done