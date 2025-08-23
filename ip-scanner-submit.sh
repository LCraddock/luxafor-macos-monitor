#!/bin/bash

# IP Scanner Submit Script
# Submits IPs to the scanner through the SSH tunnel

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if IP/target provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <ip_address> or $0 --targets <target1,target2,...>"
    exit 1
fi

# Check if tunnel is active
if ! nc -z localhost 5000 2>/dev/null; then
    echo "Error: IP Scanner API tunnel not active on port 5000"
    echo "Please start the tunnel from SwiftBar menu first"
    exit 1
fi

# Prepare JSON data
if [ "$1" == "--targets" ]; then
    # Multiple targets
    JSON_DATA="{\"targets\": \"$2\"}"
else
    # Single IP
    JSON_DATA="{\"ip\": \"$1\"}"
fi

# Submit to API
echo "Submitting to IP Scanner API..."
RESPONSE=$(curl -s -X POST http://localhost:5000/api/scan \
    -H "Content-Type: application/json" \
    -d "$JSON_DATA" \
    -w "\nHTTP_STATUS:%{http_code}")

# Extract HTTP status
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_STATUS:")

# Display result
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
    echo "✅ Success:"
    echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
else
    echo "❌ Error (HTTP $HTTP_STATUS):"
    echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
fi