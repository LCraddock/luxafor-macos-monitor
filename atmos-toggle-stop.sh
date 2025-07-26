#!/bin/bash
# Stop Atmos protection toggle with notification

# Run the stop script
$HOME/scripts/atmos_protection/stop_protection_toggle.sh

# Show notification
osascript -e 'display notification "Auto-toggle has been stopped" with title "Atmos Auto-Toggle Stopped" subtitle "Remember to re-enable protection if needed"'