#!/usr/bin/env bash

echo "🔧 COMPLETE LUXAFOR RESET AND FIX"
echo "================================="

cd /Users/larry.craddock/Projects/luxafor

echo "Step 1: Stop all processes"
pkill -f luxafor-notify
sleep 2

echo "Step 2: Check for script errors"
if ! bash -n luxafor-notify.sh; then
    echo "❌ SYNTAX ERROR in current script!"
    if [[ -f luxafor-notify.sh.backup ]]; then
        echo "   Restoring from backup..."
        cp luxafor-notify.sh.backup luxafor-notify.sh
        if bash -n luxafor-notify.sh; then
            echo "   ✅ Backup restored and syntax OK"
        else
            echo "   ❌ Backup also has syntax errors!"
            exit 1
        fi
    else
        echo "   No backup available!"
        exit 1
    fi
else
    echo "✅ Script syntax is OK"
fi

echo ""
echo "Step 3: Clean up logs"
rm -f /tmp/luxafor-debug.log /tmp/luxafor-output.log /tmp/luxafor-state

echo ""
echo "Step 4: Enable debug mode"
touch debug

echo ""
echo "Step 5: Test basic components"

# Test luxafor CLI
if [[ -f "/Users/larry.craddock/Projects/luxafor-cli/build/luxafor" ]]; then
    echo "   Testing LED..."
    /Users/larry.craddock/Projects/luxafor-cli/build/luxafor red
    sleep 1
    /Users/larry.craddock/Projects/luxafor-cli/build/luxafor off
    echo "   ✅ LED test complete"
else
    echo "   ❌ Luxafor CLI not found!"
fi

# Test config loading
echo "   Testing config loading..."
source luxafor-notify.sh
if [[ ${#APP_NAMES[@]} -gt 0 ]]; then
    echo "   ✅ Config loaded: ${#APP_NAMES[@]} apps configured"
    for i in "${!APP_NAMES[@]}"; do
        echo "      ${APP_NAMES[$i]} -> ${COLORS[$i]} (priority ${PRIORITIES[$i]})"
    done
else
    echo "   ❌ No apps loaded from config!"
fi

echo ""
echo "Step 6: Test badge detection"
for i in "${!APP_NAMES[@]}"; do
    app_name="${APP_NAMES[$i]}"
    bundle_id="${BUNDLE_IDS[$i]}"
    
    badge_count=$(lsappinfo info -only StatusLabel "$bundle_id" 2>/dev/null | grep -o '"label"="[^"]*"' | cut -d'"' -f4)
    if [[ -n "$badge_count" && "$badge_count" != "kCFNULL" ]]; then
        echo "   $app_name: badge '$badge_count'"
    elif lsappinfo info -only StatusLabel "$bundle_id" 2>/dev/null | grep -q '"label"="•"'; then
        echo "   $app_name: bullet badge"
    else
        echo "   $app_name: no badge"
    fi
done

echo ""
echo "Step 7: Manual test of one cycle"
echo "   Running one notification check cycle..."

# Create a simple test script that runs just one cycle
cat > test-one-cycle.sh << 'EOFTEST'
#!/usr/bin/env bash
source /Users/larry.craddock/Projects/luxafor/luxafor-notify.sh

# Just run the main logic once without the infinite loop
highest_priority=999
selected_color="off"
winning_app=""

echo "Testing notification detection..."

for i in "${!APP_NAMES[@]}"; do
    app_name="${APP_NAMES[$i]}"
    bundle_id="${BUNDLE_IDS[$i]}"
    color="${COLORS[$i]}"
    priority="${PRIORITIES[$i]}"
    
    # Get badge count
    badge_count=$(get_badge_lsappinfo "$bundle_id")
    
    echo "  $app_name: badge=$badge_count, priority=$priority"
    
    # Special handling for Outlook
    if [[ "$app_name" == "Outlook" ]]; then
        badge_count=0
        echo "    Checking Outlook folders..."
        for j in "${!CHANNEL_APPS[@]}"; do
            if [[ "${CHANNEL_APPS[$j]}" == "Outlook" ]] && \
               [[ "${CHANNEL_TYPES[$j]}" == "folder" ]] && \
               [[ "${CHANNEL_ENABLED[$j]}" == "true" ]]; then
                
                folder_name="${CHANNEL_NAMES[$j]}"
                folder_count=$(check_outlook_special_folder "$folder_name")
                echo "      $folder_name: $folder_count unread"
                
                if [[ "$folder_count" -gt 0 ]]; then
                    badge_count=$folder_count
                    break
                fi
            fi
        done
    fi
    
    # Check if this app wins priority
    if [[ "$badge_count" -gt 0 ]] && [[ "$priority" -lt "$highest_priority" ]]; then
        highest_priority=$priority
        selected_color=$color
        winning_app=$app_name
        echo "    -> $app_name WINS with color $color"
    fi
done

echo ""
echo "Result: color=$selected_color, app=$winning_app"

if [[ "$selected_color" != "off" ]]; then
    echo "Setting LED to $selected_color..."
    /Users/larry.craddock/Projects/luxafor-cli/build/luxafor "$selected_color"
else
    echo "No notifications - LED off"
    /Users/larry.craddock/Projects/luxafor-cli/build/luxafor off
fi
EOFTEST

chmod +x test-one-cycle.sh
./test-one-cycle.sh

echo ""
echo "Step 8: Start the service"
nohup ./luxafor-notify.sh > /tmp/luxafor-output.log 2>&1 &
SERVICE_PID=$!
echo "   Service started with PID: $SERVICE_PID"

sleep 3

if kill -0 $SERVICE_PID 2>/dev/null; then
    echo "   ✅ Service is running"
else
    echo "   ❌ Service died - checking output..."
    cat /tmp/luxafor-output.log
fi

echo ""
echo "===========================================" 
echo "✅ RESET COMPLETE"
echo ""
echo "Monitor with:"
echo "  tail -f /tmp/luxafor-debug.log"
echo ""
echo "If you still have issues:"
echo "1. Check if folder names match exactly (case-sensitive)"
echo "2. Verify the service stays running: ps aux | grep luxafor-notify"
echo "3. Test manually: ./test-one-cycle.sh"
