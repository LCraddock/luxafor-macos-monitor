#!/usr/bin/env bash

echo "🧪 QUICK LUXAFOR TEST"
echo "==================="

# Kill any existing service
pkill -f luxafor-notify

echo "1. Stopped existing service"

# Check if debug file exists
if [[ -f "/Users/larry.craddock/Projects/luxafor/debug" ]]; then
    echo "2. Debug mode is enabled"
else
    echo "2. Creating debug file..."
    touch /Users/larry.craddock/Projects/luxafor/debug
fi

# Start the service manually and capture any errors
echo "3. Starting service manually..."
cd /Users/larry.craddock/Projects/luxafor

# Check if the script is executable
if [[ -x luxafor-notify.sh ]]; then
    echo "   ✅ Script is executable"
else
    echo "   ❌ Script not executable - fixing..."
    chmod +x luxafor-notify.sh
fi

# Try to run one iteration manually to see what happens
echo "4. Testing one cycle manually..."
timeout 15 ./luxafor-notify.sh &
TEST_PID=$!

sleep 10
kill $TEST_PID 2>/dev/null

echo "5. Checking for errors..."
if [[ -f /tmp/luxafor-debug.log ]]; then
    echo "   Debug log entries:"
    tail -10 /tmp/luxafor-debug.log | sed 's/^/   /'
else
    echo "   ❌ No debug log created"
fi

echo "6. Starting service in background..."
nohup ./luxafor-notify.sh > /tmp/luxafor-output.log 2>&1 &
echo "   Service PID: $!"

echo ""
echo "✅ Service restarted. Check /tmp/luxafor-output.log and /tmp/luxafor-debug.log for details."
echo "   Monitor with: tail -f /tmp/luxafor-debug.log"
