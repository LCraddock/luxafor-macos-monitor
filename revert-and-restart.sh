#!/usr/bin/env bash

echo "🔄 REVERTING TO ORIGINAL AND MAKING TARGETED FIX"
echo "==============================================="

cd /Users/larry.craddock/Projects/luxafor

# Stop the service
pkill -f luxafor-notify
echo "1. ✅ Stopped service"

# Restore from backup if it exists
if [[ -f "luxafor-notify.sh.backup" ]]; then
    cp luxafor-notify.sh.backup luxafor-notify.sh
    echo "2. ✅ Restored from backup"
else
    echo "2. ❌ No backup found - using current version"
fi

# Check syntax
if bash -n luxafor-notify.sh; then
    echo "3. ✅ Syntax is valid"
else
    echo "3. ❌ Syntax error found!"
    exit 1
fi

# Start the service
echo "4. Starting service..."
nohup ./luxafor-notify.sh > /tmp/luxafor-output.log 2>&1 &
NEW_PID=$!
echo "   ✅ Service started with PID: $NEW_PID"

# Wait a moment and check if it's still running
sleep 3
if kill -0 $NEW_PID 2>/dev/null; then
    echo "5. ✅ Service is running"
else
    echo "5. ❌ Service died - checking output..."
    cat /tmp/luxafor-output.log
    exit 1
fi

echo ""
echo "✅ Service restored and running"
echo "   Now test if basic Outlook notifications work"
echo "   Then we'll make a minimal fix for Slack workspace issue"
