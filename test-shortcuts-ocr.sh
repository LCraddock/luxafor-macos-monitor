#!/usr/bin/env bash

echo "Testing OCR with macOS shortcuts..."

# Capture Craddock workspace area where you said the badge is
# Badge center at 45:131, so roughly 28:114 to 62:148
screencapture -R28,114,34,34 -x /tmp/craddock_badge.png 2>/dev/null

if [ -f /tmp/craddock_badge.png ]; then
    echo "Screenshot captured. Checking contents..."
    
    # Use sips to check image info
    sips -g pixelWidth -g pixelHeight /tmp/craddock_badge.png
    
    # Try to create and run a shortcut for OCR
    # This requires the Shortcuts app to have a shortcut that does OCR
    
    # Alternative: Use Automator or AppleScript with Image Events
    # For now, let's at least check if we captured something
    
    # Check file size to see if we got content
    ls -la /tmp/craddock_badge.png
    
    echo ""
    echo "Image saved to /tmp/craddock_badge.png"
    echo "You can open it to verify the badge was captured: open /tmp/craddock_badge.png"
    
    # Try another approach - use Python with PIL if available
    if command -v python3 &> /dev/null; then
        echo ""
        echo "Attempting pixel analysis with Python..."
        python3 << 'EOF'
import sys
try:
    from PIL import Image
    import numpy as np
    
    img = Image.open('/tmp/craddock_badge.png')
    img_array = np.array(img)
    
    # Check for blue pixels (badge color)
    blue_pixels = np.sum((img_array[:,:,2] > 200) & (img_array[:,:,0] < 100))
    
    print(f"Image size: {img.size}")
    print(f"Blue pixels found: {blue_pixels}")
    
    if blue_pixels > 50:
        print("✓ Likely contains a blue badge!")
    
except ImportError:
    print("PIL not installed - can't analyze pixels")
except Exception as e:
    print(f"Error: {e}")
EOF
    fi
else
    echo "Failed to capture screenshot"
fi