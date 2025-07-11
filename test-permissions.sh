#!/usr/bin/env bash

echo "=== Checking accessibility permissions ==="
echo

# Check if Terminal has accessibility access
echo "Checking which app is running this script..."
ps -p $$ -o comm=

echo
echo "To fix badge detection:"
echo "1. Open System Settings > Privacy & Security > Accessibility"
echo "2. Make sure Terminal (or iTerm) is in the list and checked"
echo "3. If it's already there, try removing and re-adding it"
echo "4. You may need to restart Terminal after granting permission"

echo
echo "=== Testing with explicit accessibility check ==="
osascript <<'APPLESCRIPT'
tell application "System Events"
  try
    -- This will prompt for accessibility if not granted
    tell application process "Dock"
      return "Accessibility granted - testing badge access..."
    end tell
  on error
    return "Accessibility not granted - please check System Settings"
  end try
end tell
APPLESCRIPT