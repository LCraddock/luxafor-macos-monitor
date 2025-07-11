#!/usr/bin/env bash
#
# luxafor-test.sh
# LED test function - cycles through primary colors
#

LUXAFOR_CLI="/Users/larry.craddock/Projects/luxafor-cli/build/luxafor"

echo "Starting Luxafor LED test..."
echo "Will cycle through: Red → Green → Blue → Off"
echo "Auto-stops after 30 seconds"
echo "Press Ctrl+C to stop early"
echo ""

# Set up trap to turn off LED on exit
cleanup() {
    echo -e "\nTurning off LED..."
    $LUXAFOR_CLI off
    exit 0
}
trap cleanup EXIT INT TERM

# Start timer in background
(sleep 30 && kill $$ 2>/dev/null) &
TIMER_PID=$!

# Cycle through colors
for i in {1..10}; do
    echo "Cycle $i/10:"
    
    echo "  Red..."
    $LUXAFOR_CLI red
    sleep 1
    
    echo "  Green..."
    $LUXAFOR_CLI green
    sleep 1
    
    echo "  Blue..."
    $LUXAFOR_CLI blue
    sleep 1
done

# Kill the timer if we finished normally
kill $TIMER_PID 2>/dev/null

echo "Test complete!"