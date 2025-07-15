# Channel Monitoring Implementation Notes

## Current Status
- **Branch**: feature/channel-monitoring
- **Started**: 2025-07-15
- **Goal**: Add channel/folder specific monitoring without breaking existing functionality

## Implementation Progress

### Phase 1: Unified Config System (Current)

#### Step 1.1: Design New Config Format ✅
**Decision**: Create a new file `luxafor-channels.conf` that complements existing configs
- Keeps backward compatibility
- Apps without channels continue using main config
- Channel config overrides app-level settings when matched

**Format**:
```
AppName|Type|Name|Color|Action|PushoverPriority|PushoverSound|Enabled
```

#### Step 1.2: Test with Outlook First
**Why Outlook first?**
- Already have working folder detection
- Easier to test without breaking anything
- Can validate config format before Teams/Slack complexity

**Current Outlook Config Files**:
1. `luxafor-config.conf` - Main app config (keep as-is)
2. `luxafor-outlook-folders.conf` - Current special folders (will migrate)
3. `luxafor-channels.conf` - NEW unified format (create next)

#### Step 1.3: Migration Strategy
- Read both old and new configs during transition
- New config takes precedence if both exist
- Provide migration script for users

### Testing Checkpoints

✅ **Checkpoint 0**: Backup created, git branch ready
✅ **Checkpoint 1**: New config file created and parsing works
✅ **Checkpoint 2**: Outlook folders work with new config (basic integration done, testing needed)
⏳ **Checkpoint 3**: SwiftBar shows Outlook submenus
⏳ **Checkpoint 4**: Ready for Teams/Slack implementation

### Rollback Procedures

**If something breaks**:
```bash
# Option 1: Git rollback
git checkout main
./luxafor-control.sh restart

# Option 2: Config backup
cp ~/.luxafor-backups/[latest]/* .
./luxafor-control.sh restart
```

### Key Files Being Modified

1. **luxafor-channels.conf** (NEW)
   - Unified config for all channel/folder rules
   
2. **luxafor-notify.sh**
   - Add channel config parser
   - Modify main loop to check channels first
   
3. **luxafor-toggle.1s.sh**
   - Add submenu generation
   - Handle channel enable/disable

### Design Decisions Log

**2025-07-15**: 
- Decided to use separate config file rather than extending existing
- Keeps configs focused and backward compatible
- Easier to disable entire feature if needed

### Next Steps
1. Create `luxafor-channels.conf` with Outlook examples
2. Add parser function to read channel config
3. Test with existing Outlook folders
4. Only then proceed to Teams/Slack