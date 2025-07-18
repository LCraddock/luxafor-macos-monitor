#!/usr/bin/env bash
#
# Test Pushover integration
#

# Load from config file or use test values
if [[ -f "../luxafor-pushover.conf" ]]; then
    source ../luxafor-pushover.conf
else
    echo "Warning: luxafor-pushover.conf not found. Using template values."
    PUSHOVER_APP_TOKEN="your_app_token_here"
    PUSHOVER_USER_KEY="your_user_key_here"
fi

if [[ "$PUSHOVER_APP_TOKEN" == "your_app_token_here" ]]; then
    echo "Error: Please configure your Pushover credentials in luxafor-pushover.conf"
    exit 1
fi

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