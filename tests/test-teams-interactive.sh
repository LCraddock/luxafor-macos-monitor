#!/usr/bin/env bash
#
# test-teams-interactive.sh
# Interactive Teams window title tester
#

echo "=== Interactive Teams Window Title Tester ==="
echo
echo "Instructions:"
echo "1. Navigate to a Teams area (chat, channel, activity, etc.)"
echo "2. Press Enter to capture the window title"
echo "3. Type 'quit' to exit"
echo

# Function to analyze window
analyze_teams_window() {
    local window_title=$(osascript -e 'tell application "System Events" to tell process "Microsoft Teams" to name of window 1' 2>/dev/null)
    
    if [[ -z "$window_title" ]]; then
        echo "No Teams window found"
        return
    fi
    
    echo "📍 Raw title: $window_title"
    
    # Parse the window title
    if [[ "$window_title" == *" | "* ]]; then
        # Split into parts
        local first_part="${window_title%% | *}"
        local after_first="${window_title#* | }"
        local middle_part="${after_first% | *}"
        
        echo "   Type/Section: $first_part"
        echo "   Content: $middle_part"
        
        # Determine type
        if [[ "$first_part" == "Chat" ]]; then
            echo "   ✅ This is a CHAT - would always alert"
        elif [[ "$first_part" == "Activity" ]] || [[ "$first_part" == "Calendar" ]] || [[ "$first_part" == "Calls" ]] || [[ "$first_part" == "Files" ]]; then
            echo "   ⚠️  This is a Teams section (not a conversation)"
        else
            echo "   📢 This appears to be a CHANNEL: '$first_part' in team '$middle_part'"
            echo "      Would only alert if '$first_part' is in configured channels"
        fi
    else
        echo "   ❓ Unexpected format"
    fi
    echo
}

# Main loop
while true; do
    echo -n "Navigate to Teams area and press Enter (or 'quit'): "
    read input
    
    if [[ "$input" == "quit" ]]; then
        break
    fi
    
    analyze_teams_window
done

echo
echo "=== Test Summary ==="
echo "Based on window title patterns:"
echo "- First part 'Chat' = Always alert (all chats/DMs)"
echo "- First part is channel name = Only alert if configured"
echo "- First part is section name = Don't alert (Activity, Calendar, etc.)"