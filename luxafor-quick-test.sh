#!/usr/bin/env bash
#
# luxafor-quick-test.sh
# Quick LED test - no terminal needed
#

LUXAFOR_CLI="/Users/larry.craddock/Projects/luxafor-cli/build/luxafor"

# Flash each color for 2 seconds
$LUXAFOR_CLI red
sleep 2
$LUXAFOR_CLI green
sleep 2
$LUXAFOR_CLI blue
sleep 2
$LUXAFOR_CLI off