#!/usr/bin/env bash
#
# Backup current configuration files
#

BACKUP_DIR="$HOME/.luxafor-backups/$(date +%Y%m%d_%H%M%S)"

echo "Creating backup in $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"

# Backup all config files
cp luxafor-config.conf "$BACKUP_DIR/" 2>/dev/null
cp luxafor-enabled-apps.conf "$BACKUP_DIR/" 2>/dev/null
cp luxafor-outlook-folders.conf "$BACKUP_DIR/" 2>/dev/null
cp luxafor-pushover.conf "$BACKUP_DIR/" 2>/dev/null
cp luxafor-notify.sh "$BACKUP_DIR/" 2>/dev/null
cp luxafor-toggle.1s.sh "$BACKUP_DIR/" 2>/dev/null

echo "Backup complete!"
echo "To restore: cp $BACKUP_DIR/* /Users/larry.craddock/Projects/luxafor/"