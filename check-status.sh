#!/usr/bin/env bash

echo "🧪 TESTING CURRENT STATUS"
echo "========================"

echo "1. Service check:"
if pgrep -f luxafor-notify; then
    echo "   ✅ Service running (PID: $(pgrep -f luxafor-notify))"
else
    echo "   ❌ Service not running"
fi

echo ""
echo "2. Badge detection:"

# Test Outlook badge
outlook_status=$(lsappinfo info -only StatusLabel "com.microsoft.Outlook" 2>/dev/null)
if [[ "$outlook_status" == *'"label"='* ]]; then
    outlook_badge=$(echo "$outlook_status" | grep -o '"label"="[^"]*"' | cut -d'"' -f4)
    echo "   Outlook badge: '$outlook_badge'"
else
    echo "   Outlook: No badge"
fi

# Test Slack badge
slack_status=$(lsappinfo info -only StatusLabel "com.tinyspeck.slackmacgap" 2>/dev/null)
if [[ "$slack_status" == *'"label"="•"'* ]]; then
    echo "   Slack badge: bullet (•)"
elif [[ "$slack_status" == *'"label"='* ]]; then
    slack_badge=$(echo "$slack_status" | grep -o '"label"="[^"]*"' | cut -d'"' -f4)
    echo "   Slack badge: '$slack_badge'"
else
    echo "   Slack: No badge"
fi

echo ""
echo "3. Current LED state:"
if [[ -f "/tmp/luxafor-state" ]]; then
    cat /tmp/luxafor-state | sed 's/^/   /'
else
    echo "   No state file found"
fi

echo ""
echo "4. Debug log (last 5 lines):"
if [[ -f "/tmp/luxafor-debug.log" ]]; then
    tail -5 /tmp/luxafor-debug.log | sed 's/^/   /'
else
    echo "   No debug log found"
fi

echo ""
echo "5. Manual LED test:"
echo "   Testing blue..."
/Users/larry.craddock/Projects/luxafor-cli/build/luxafor blue
sleep 2
echo "   Testing off..."
/Users/larry.craddock/Projects/luxafor-cli/build/luxafor off

echo ""
echo "✅ Status check complete"
echo ""
echo "If you have badges but no LED, the service might not be processing them correctly."
echo "Check if Outlook 'Inbox' folder name matches exactly in the config."
