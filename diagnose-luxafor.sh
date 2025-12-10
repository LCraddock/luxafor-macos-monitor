#!/usr/bin/env bash

echo "🔍 LUXAFOR DIAGNOSTIC"
echo "===================="

echo ""
echo "1. Service Status:"
if pgrep -f luxafor-notify >/dev/null; then
    echo "✅ Service is running (PID: $(pgrep -f luxafor-notify))"
else
    echo "❌ Service is NOT running"
fi

echo ""
echo "2. Configuration Files:"
for file in luxafor-config.conf luxafor-channels.conf luxafor-enabled-apps.conf; do
    if [[ -f "/Users/larry.craddock/Projects/luxafor/$file" ]]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

echo ""
echo "3. Badge Detection Test:"

# Test Outlook
echo "   Outlook Badge:"
outlook_badge=$(lsappinfo info -only StatusLabel "com.microsoft.Outlook" 2>/dev/null | grep -o '"label"="[^"]*"' | cut -d'"' -f4)
if [[ -n "$outlook_badge" && "$outlook_badge" != "kCFNULL" ]]; then
    echo "   ✅ Outlook badge: '$outlook_badge'"
else
    echo "   ❌ No Outlook badge detected"
fi

# Test Slack  
echo "   Slack Badge:"
slack_badge=$(lsappinfo info -only StatusLabel "com.tinyspeck.slackmacgap" 2>/dev/null | grep -o '"label"="[^"]*"' | cut -d'"' -f4)
if [[ -n "$slack_badge" && "$slack_badge" != "kCFNULL" ]]; then
    echo "   ✅ Slack badge: '$slack_badge'"
elif lsappinfo info -only StatusLabel "com.tinyspeck.slackmacgap" 2>/dev/null | grep -q '"label"="•"'; then
    echo "   ✅ Slack badge: bullet (•)"
else
    echo "   ❌ No Slack badge detected"
fi

echo ""
echo "4. Luxafor CLI Test:"
if [[ -f "/Users/larry.craddock/Projects/luxafor-cli/build/luxafor" ]]; then
    echo "✅ Luxafor CLI exists"
    echo "   Testing LED..."
    /Users/larry.craddock/Projects/luxafor-cli/build/luxafor blue >/dev/null 2>&1
    sleep 1
    /Users/larry.craddock/Projects/luxafor-cli/build/luxafor off >/dev/null 2>&1
    echo "   ✅ LED test completed"
else
    echo "❌ Luxafor CLI missing"
fi

echo ""
echo "5. Debug Log:"
if [[ -f "/tmp/luxafor-debug.log" ]]; then
    echo "✅ Debug log exists, last 5 entries:"
    tail -5 /tmp/luxafor-debug.log | sed 's/^/   /'
else
    echo "❌ No debug log found"
fi

echo ""
echo "6. Current State File:"
if [[ -f "/tmp/luxafor-state" ]]; then
    echo "✅ State file exists:"
    cat /tmp/luxafor-state | sed 's/^/   /'
else
    echo "❌ No state file found"
fi

echo ""
echo "7. App Enabled Status:"
if [[ -f "/Users/larry.craddock/Projects/luxafor/luxafor-enabled-apps.conf" ]]; then
    echo "✅ Enabled apps config:"
    cat /Users/larry.craddock/Projects/luxafor/luxafor-enabled-apps.conf | sed 's/^/   /'
else
    echo "❌ No enabled apps config - all apps enabled by default"
fi

echo ""
echo "===================="
echo "🔍 DIAGNOSTIC COMPLETE"

if ! pgrep -f luxafor-notify >/dev/null; then
    echo ""
    echo "🚨 ISSUE FOUND: Service is not running!"
    echo "   Try: pkill -f luxafor-notify && nohup /Users/larry.craddock/Projects/luxafor/luxafor-notify.sh > /tmp/luxafor-output.log 2>&1 &"
fi
