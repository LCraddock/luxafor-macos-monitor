#!/usr/bin/env bash
#
# Test Pushover integration
#

PUSHOVER_APP_TOKEN="***REMOVED***"
PUSHOVER_USER_KEY="***REMOVED***"

echo "Testing Pushover notification..."

response=$(curl -s -X POST https://api.pushover.net/1/messages.json \
  -d "token=$PUSHOVER_APP_TOKEN" \
  -d "user=$PUSHOVER_USER_KEY" \
  -d "message=Test notification from Luxafor Monitor" \
  -d "title=Luxafor Test" \
  -d "priority=0" \
  -d "sound=pushover")

echo "Response: $response"

if [[ "$response" == *'"status":1'* ]]; then
  echo "✅ Success! Check your phone."
else
  echo "❌ Failed. Check your user key."
fi