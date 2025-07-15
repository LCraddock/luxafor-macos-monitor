#!/usr/bin/env bash

# Test if we can detect Teams notifications and send Pushover

echo "Testing Teams notification detection..."

# Source the config
source /Users/larry.craddock/Projects/luxafor/luxafor-pushover.conf

echo "Pushover enabled: $PUSHOVER_ENABLED"
echo "App token: ${PUSHOVER_APP_TOKEN:0:10}..."
echo "User key: ${PUSHOVER_USER_KEY:0:10}..."

# Get Teams badge count
bundle_id="com.microsoft.teams2"
status_info=$(lsappinfo info -only StatusLabel "$bundle_id" 2>/dev/null)
echo "Raw status info: $status_info"

badge_count=$(echo "$status_info" | grep -o '"label"="[0-9]*"' | cut -d'"' -f4)
if [[ -z "$badge_count" ]]; then
    badge_count="0"
fi

echo "Teams badge count: $badge_count"

# Check if should send according to rules
echo ""
echo "Checking Pushover rules..."
while IFS='|' read -r rule_app condition priority sound || [ -n "$rule_app" ]; do
    # Skip comments and empty lines
    [[ "$rule_app" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$rule_app" ]] && continue
    
    # Trim whitespace
    rule_app=$(echo "$rule_app" | xargs)
    echo "Rule: $rule_app | $condition | $priority | $sound"
    
    if [[ "$rule_app" == "Teams" ]]; then
        echo "Found Teams rule!"
        if [[ "$condition" == "any" ]] && [[ "$badge_count" -gt 0 ]]; then
            echo "Rule matches! Sending notification..."
            
            curl -s -X POST https://api.pushover.net/1/messages.json \
                -d "token=$PUSHOVER_APP_TOKEN" \
                -d "user=$PUSHOVER_USER_KEY" \
                -d "title=Test: Teams" \
                -d "message=$badge_count new notification(s)" \
                -d "priority=$priority" \
                -d "sound=$sound"
                
            echo ""
            echo "Notification sent!"
        fi
    fi
done < /Users/larry.craddock/Projects/luxafor/luxafor-pushover.conf