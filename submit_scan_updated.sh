#!/bin/bash

# Script to submit IP scans via the forwarder
# Usage: ./submit_scan.sh <ip1> [ip2] [ip3] ...
# Example: ./submit_scan.sh 8.8.8.8
# Example: ./submit_scan.sh 8.8.8.8 1.1.1.1 192.168.1.0/24

# Check if at least one argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <ip1> [ip2] [ip3] ..."
    echo "Examples:"
    echo "  $0 8.8.8.8"
    echo "  $0 8.8.8.8 1.1.1.1"
    echo "  $0 192.168.1.0/24"
    echo "  $0 8.8.8.8 192.168.1.0/24 10.0.0.1"
    exit 1
fi

# Check if local tunnel is active first
if nc -z localhost 5000 2>/dev/null; then
    # Use local tunnel (through IAP)
    FORWARDER_URL="http://localhost:5000/api/scan"
    echo "Using local SSH tunnel (port 5000)"
else
    # Fall back to Kali forwarder
    FORWARDER_URL="http://192.168.1.189:5000/submit"
    echo "Using Kali forwarder"
fi

# Build JSON array from arguments
if [ $# -eq 1 ]; then
    # Single IP - use "ip" field for backward compatibility
    JSON_DATA="{\"ip\": \"$1\"}"
else
    # Multiple IPs - use "targets" field
    TARGETS=""
    for ip in "$@"; do
        if [ -z "$TARGETS" ]; then
            TARGETS="\"$ip\""
        else
            TARGETS="$TARGETS, \"$ip\""
        fi
    done
    JSON_DATA="{\"targets\": [$TARGETS]}"
fi

# Submit the scan
echo "Submitting scan for: $@"
echo "JSON payload: $JSON_DATA"
echo ""

response=$(curl -s -X POST "$FORWARDER_URL" \
  -H "Content-Type: application/json" \
  -d "$JSON_DATA" \
  -w "\nHTTP_CODE:%{http_code}")

# Extract HTTP code
http_code=$(echo "$response" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
body=$(echo "$response" | sed 's/HTTP_CODE:[0-9]*$//')

# Check response
if [ "$http_code" = "200" ] || [ "$http_code" = "201" ] || [ "$http_code" = "202" ]; then
    echo "✓ Scan submitted successfully!"
    echo "$body" | jq . 2>/dev/null || echo "$body"
else
    echo "✗ Error submitting scan (HTTP $http_code)"
    echo "$body" | jq . 2>/dev/null || echo "$body"
fi