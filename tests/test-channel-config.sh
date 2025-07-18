#!/usr/bin/env bash
#
# Test parsing of new channel config format
#

CHANNELS_CONFIG="/Users/larry.craddock/Projects/luxafor/luxafor-channels.conf"

echo "Testing channel config parser..."
echo "================================"

# Arrays to store channel config
declare -a CHANNEL_APPS
declare -a CHANNEL_TYPES
declare -a CHANNEL_NAMES
declare -a CHANNEL_COLORS
declare -a CHANNEL_ACTIONS
declare -a CHANNEL_PRIORITIES
declare -a CHANNEL_SOUNDS
declare -a CHANNEL_ENABLED

# Parse the config
index=0
while IFS='|' read -r app type name color action priority sound enabled || [ -n "$app" ]; do
    # Skip comments and empty lines
    [[ "$app" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$app" ]] && continue
    
    # Trim whitespace
    app=$(echo "$app" | xargs)
    type=$(echo "$type" | xargs)
    name=$(echo "$name" | xargs)
    color=$(echo "$color" | xargs)
    action=$(echo "$action" | xargs)
    priority=$(echo "$priority" | xargs)
    sound=$(echo "$sound" | xargs)
    enabled=$(echo "$enabled" | xargs)
    
    # Store in arrays
    CHANNEL_APPS[$index]="$app"
    CHANNEL_TYPES[$index]="$type"
    CHANNEL_NAMES[$index]="$name"
    CHANNEL_COLORS[$index]="$color"
    CHANNEL_ACTIONS[$index]="$action"
    CHANNEL_PRIORITIES[$index]="$priority"
    CHANNEL_SOUNDS[$index]="$sound"
    CHANNEL_ENABLED[$index]="$enabled"
    
    echo "Parsed: $app | $type | $name | $color | $action | p:$priority | s:$sound | e:$enabled"
    
    ((index++))
done < "$CHANNELS_CONFIG"

echo ""
echo "Total channels loaded: $index"
echo ""

# Test lookup function
lookup_channel() {
    local app_name="$1"
    local type="$2"
    local name="$3"
    
    for i in "${!CHANNEL_APPS[@]}"; do
        if [[ "${CHANNEL_APPS[$i]}" == "$app_name" ]] && \
           [[ "${CHANNEL_TYPES[$i]}" == "$type" ]] && \
           [[ "${CHANNEL_NAMES[$i]}" == "$name" ]] && \
           [[ "${CHANNEL_ENABLED[$i]}" == "true" ]]; then
            echo "Found: ${CHANNEL_COLORS[$i]}|${CHANNEL_ACTIONS[$i]}|${CHANNEL_PRIORITIES[$i]}|${CHANNEL_SOUNDS[$i]}"
            return 0
        fi
    done
    return 1
}

# Test lookups
echo "Testing lookups:"
echo -n "Outlook/folder/Phishing: "
lookup_channel "Outlook" "folder" "Phishing"

echo -n "Outlook/folder/Inbox: "
lookup_channel "Outlook" "folder" "Inbox"

echo -n "Outlook/folder/NonExistent: "
lookup_channel "Outlook" "folder" "NonExistent" || echo "Not found"