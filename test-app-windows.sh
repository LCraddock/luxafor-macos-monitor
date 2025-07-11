#!/usr/bin/env bash

echo "=== Alternative approach: Check app window titles ==="
echo

# Slack often shows unread count in window title
echo "Slack window titles:"
osascript -e 'tell application "System Events" to tell process "Slack" to return name of every window'

echo
echo "Outlook window titles:"
osascript -e 'tell application "System Events" to tell process "Microsoft Outlook" to return name of every window'

echo
echo "=== Let's also check if notifications are enabled ==="
echo "System Preferences > Notifications - make sure badge app icon is enabled for these apps"