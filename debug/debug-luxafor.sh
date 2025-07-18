#!/usr/bin/env bash

# Test script to debug luxafor issues

echo "=== Luxafor Debug Test ==="
echo "Date: $(date)"
echo

# Check if luxafor binary exists
LUXAFOR_CLI="/Users/larry.craddock/Projects/luxafor-cli/build/luxafor"
if [ -f "$LUXAFOR_CLI" ]; then
    echo "✓ Luxafor CLI found at: $LUXAFOR_CLI"
else
    echo "✗ Luxafor CLI NOT found at: $LUXAFOR_CLI"
    exit 1
fi

# Check if it's executable
if [ -x "$LUXAFOR_CLI" ]; then
    echo "✓ Luxafor CLI is executable"
else
    echo "✗ Luxafor CLI is NOT executable"
    exit 1
fi

echo
echo "Testing luxafor device connection..."
echo "Running: $LUXAFOR_CLI red"
echo "Output:"
$LUXAFOR_CLI red 2>&1

echo
echo "Checking USB devices for Luxafor..."
system_profiler SPUSBDataType 2>/dev/null | grep -E "(Vendor ID|Product ID|Manufacturer|Product Name)" | grep -B1 -A2 -i "luxafor" || echo "No Luxafor device found in USB listing"

echo
echo "Checking all USB devices..."
system_profiler SPUSBDataType 2>/dev/null | grep -E "Product ID:|Vendor ID:" | head -20

echo
echo "Checking HID devices..."
ioreg -r -c IOHIDDevice | grep -E '"Product"|"Manufacturer"|"VendorID"|"ProductID"' | head -20