#!/usr/bin/env bash
#
# Flash Luxafor with Burp Suite color (RGB: 92,74,250)
# 
# Edit this file to customize the Burp Suite launch flash
#

LUXAFOR_CLI="/Users/larry.craddock/Projects/luxafor-cli/build/luxafor"

# COLOR CONFIGURATION
# Convert RGB to hex: 92,74,250 = 0x5C4AFA
BURP_COLOR="0x5C4AFA"  # Purple-blue
# Other examples:
# BURP_COLOR="0xFF0000"  # Red
# BURP_COLOR="0x00FF00"  # Green  
# BURP_COLOR="0xFFA500"  # Orange

# FLASH CONFIGURATION
FLASH_COUNT=5      # Number of flashes
FLASH_ON_TIME=0.5  # Seconds light is on
FLASH_OFF_TIME=0.5 # Seconds light is off

# Flash sequence
for i in $(seq 1 $FLASH_COUNT); do
    $LUXAFOR_CLI "$BURP_COLOR" >/dev/null 2>&1
    sleep $FLASH_ON_TIME
    $LUXAFOR_CLI off >/dev/null 2>&1
    sleep $FLASH_OFF_TIME
done

# Optional: Keep color on after flash
# Uncomment the next line to leave the light on
# $LUXAFOR_CLI "$BURP_COLOR" >/dev/null 2>&1