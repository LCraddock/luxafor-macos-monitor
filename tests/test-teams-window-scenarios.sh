#!/usr/bin/env bash
#
# test-teams-window-scenarios.sh
# Test various Teams window scenarios to understand title patterns
#

echo "=== Teams Window Title Analysis ==="
echo
echo "Please navigate through different Teams areas while this script runs."
echo "It will capture window titles and analyze patterns."
echo

# Function to get and parse Teams window
analyze_teams_window() {
    local window_title=$(osascript -e 'tell application "System Events" to tell process "Microsoft Teams" to name of window 1' 2>/dev/null)
    
    if [[ -z "$window_title" ]]; then
        echo "No Teams window found"
        return
    fi
    
    echo "Raw title: $window_title"
    
    # Parse the window title
    if [[ "$window_title" == *" | "* ]]; then
        # Split into parts
        local first_part="${window_title%% | *}"
        local after_first="${window_title#* | }"
        local middle_part="${after_first% | *}"
        local last_part="${window_title##* | }"
        
        echo "  Type/Section: $first_part"
        echo "  Content: $middle_part"
        echo "  App: $last_part"
        
        # Determine if it's a chat or channel
        if [[ "$first_part" == "Chat" ]]; then
            echo "  → This is a CHAT/DM"
        elif [[ "$first_part" == "Activity" ]] || [[ "$first_part" == "Calendar" ]] || [[ "$first_part" == "Calls" ]] || [[ "$first_part" == "Files" ]]; then
            echo "  → This is a TEAMS SECTION (not a conversation)"
        else
            # Could be a channel name or team name
            echo "  → This might be a CHANNEL: $first_part"
        fi
    else
        echo "  → Unexpected format: $window_title"
    fi
    
    echo
}

# Test scenarios
echo "=== INSTRUCTIONS ==="
echo "Please navigate to the following in Teams:"
echo "1. A direct message (1:1 chat)"
echo "2. A group chat"
echo "3. A channel in a team"
echo "4. The Activity tab"
echo "5. A meeting window (if possible)"
echo "6. Calendar, Calls, or Files sections"
echo
echo "Press Enter to start monitoring (will run for 60 seconds)..."
read

echo
echo "=== MONITORING TEAMS WINDOW TITLES ==="
echo "Navigate through different Teams areas now..."
echo

# Monitor for 60 seconds, checking every 3 seconds
for i in {1..20}; do
    echo "Check $i/20:"
    analyze_teams_window
    sleep 3
done

echo "=== SUMMARY ==="
echo "Based on the patterns observed:"
echo "- Chats show: 'Chat | Person/Group Name | Microsoft Teams'"
echo "- Channels might show: 'Channel Name | Team Name | Microsoft Teams'"
echo "- Other sections show: 'Section | Content | Microsoft Teams'"
echo
echo "We can use the first part to determine if it's a chat that should always alert."