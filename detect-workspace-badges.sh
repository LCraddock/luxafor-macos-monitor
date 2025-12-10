#!/usr/bin/env bash

# Function to check if a workspace has a badge by detecting blue pixels
check_workspace_for_badge() {
    local workspace_name=$1
    local x=$2
    local y=$3
    local temp_file="/tmp/ws_${workspace_name}.png"
    
    # Capture small area around badge location (badge is ~16x16)
    screencapture -R${x},${y},20,20 -x "$temp_file" 2>/dev/null
    
    if [ -f "$temp_file" ]; then
        # Use Python to check for blue badge color
        local has_badge=$(python3 << EOF
import sys
try:
    from PIL import Image
    img = Image.open('$temp_file')
    pixels = img.load()
    
    # Check for blue pixels (Slack badge is blue)
    # Blue badge typically has high blue, low red/green
    blue_count = 0
    for i in range(img.width):
        for j in range(img.height):
            r, g, b, *_ = pixels[i, j] if len(pixels[i, j]) > 3 else (*pixels[i, j], 255)
            # Slack blue badge: high blue, lower red/green
            if b > 180 and r < 100 and g < 150:
                blue_count += 1
    
    # If more than 20% of pixels are blue, likely a badge
    if blue_count > (img.width * img.height * 0.2):
        print("true")
    else:
        print("false")
        
except Exception as e:
    print("false")
EOF
)
        rm -f "$temp_file"
        echo "$has_badge"
    else
        echo "false"
    fi
}

# Function to get all workspace badges
get_workspace_badges() {
    local badges=""
    
    # Check UKG workspace (badge around 37,94)
    if [ "$(check_workspace_for_badge 'UKG' 27 84)" = "true" ]; then
        badges="${badges}UKG,"
    fi
    
    # Check Craddock workspace (badge around 37,145)  
    if [ "$(check_workspace_for_badge 'Craddock' 35 121)" = "true" ]; then
        badges="${badges}Craddock,"
    fi
    
    # Check CS Alumni workspace (badge around 37,197)
    if [ "$(check_workspace_for_badge 'CS_Alumni' 27 187)" = "true" ]; then
        badges="${badges}CS Alumni,"
    fi
    
    # Remove trailing comma
    badges=${badges%,}
    echo "$badges"
}

echo "Checking for workspace badges..."
badges=$(get_workspace_badges)

if [ -n "$badges" ]; then
    echo "Workspaces with badges: $badges"
else
    echo "No workspace badges detected"
fi