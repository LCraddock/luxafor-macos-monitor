#!/bin/bash
# Start Atmos protection toggle with notification

# Run the start script
$HOME/scripts/atmos_protection/start_protection_toggle.sh

# Show notification
osascript -e 'display notification "Internet Protection will be kept disabled" with title "Atmos Auto-Toggle Started" subtitle "Toggles every 50 minutes"'