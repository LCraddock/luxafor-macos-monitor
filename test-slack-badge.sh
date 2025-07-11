#!/usr/bin/env bash

echo "Testing Slack badge detection..."
status_info=$(lsappinfo info -only StatusLabel "com.tinyspeck.slackmacgap" 2>/dev/null)
echo "Raw status: $status_info"

# Original detection
badge_count=$(echo "$status_info" | grep -o '"label"="[0-9]*"' | cut -d'"' -f4)
echo "Number detection: '$badge_count'"

# Check for bullet
if [[ "$status_info" == *'"label"="•"'* ]]; then
    echo "Bullet detected - Slack has notifications!"
fi