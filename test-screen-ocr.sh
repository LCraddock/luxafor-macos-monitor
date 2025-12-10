#!/usr/bin/env bash

echo "Testing screen capture and OCR for workspace badges..."

# Workspace areas (screen coordinates)
# UKG: 10,75 to 44,114
# Craddock: 10,128 to 44,163  
# CS Alumni: 10,182 to 44,213

# Function to capture and OCR a specific screen region
check_workspace_badge() {
    local name=$1
    local x=$2
    local y=$3
    local width=$4
    local height=$5
    local temp_img="/tmp/slack_workspace_${name}.png"
    
    echo "Checking $name workspace area..."
    
    # Capture the workspace area (x,y,width,height)
    screencapture -R${x},${y},${width},${height} -x "$temp_img" 2>/dev/null
    
    if [ -f "$temp_img" ]; then
        # Try to use macOS's built-in OCR via shortcuts or Swift
        # First, let's try using the Vision framework via a Swift script
        
        # Create a temporary Swift script for OCR
        cat > /tmp/ocr_detect.swift << 'EOF'
import Vision
import AppKit

let imagePath = CommandLine.arguments[1]
guard let image = NSImage(contentsOfFile: imagePath) else {
    print("Could not load image")
    exit(1)
}

guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Could not convert to CGImage")
    exit(1)
}

let request = VNRecognizeTextRequest { request, error in
    guard let observations = request.results as? [VNRecognizedTextObservation] else {
        return
    }
    
    for observation in observations {
        if let text = observation.topCandidates(1).first?.string {
            print(text)
        }
    }
}

request.recognitionLevel = .accurate

let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try? handler.perform([request])
EOF
        
        # Run the Swift OCR script
        local ocr_result=$(swift /tmp/ocr_detect.swift "$temp_img" 2>/dev/null)
        
        if [ -n "$ocr_result" ]; then
            echo "  Found text: $ocr_result"
            # Check if it's a number (badge count)
            if [[ "$ocr_result" =~ ^[0-9]+$ ]]; then
                echo "  ✓ Badge detected with count: $ocr_result"
                return 0
            fi
        else
            echo "  No text detected"
        fi
        
        # Clean up
        rm -f "$temp_img"
    else
        echo "  Failed to capture screenshot"
    fi
    
    return 1
}

# Check each workspace
echo ""
check_workspace_badge "UKG" 10 75 34 39
echo ""
check_workspace_badge "Craddock" 10 128 34 35
echo ""
check_workspace_badge "CS_Alumni" 10 182 34 31

# Alternative: Try using the `ocr` command if available via shortcuts
if command -v shortcuts &> /dev/null; then
    echo ""
    echo "Note: 'shortcuts' command is available for OCR if needed"
fi

# Clean up
rm -f /tmp/ocr_detect.swift /tmp/slack_workspace_*.png