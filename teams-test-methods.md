# Teams Notification Test Methods

## Methods that CREATE badge notifications:

### 1. **@mentions in any channel**
- Post a message in any channel with @YourName
- This creates a notification even if you wrote it yourself
- Example: "@Larry test notification"

### 2. **Reply to your own message**
- Post a message in any channel
- Wait a moment, then reply to it
- Replies to your messages create notifications

### 3. **Teams Bot/App notifications**
- Install "Praise" app from Teams store
- Send praise to yourself
- Many Teams apps can send you notifications

### 4. **Planner/Tasks assignments**
- Create a task in Microsoft Planner
- Assign it to yourself with a due date
- This triggers a notification

### 5. **Calendar reminders**
- Create a Teams meeting
- Set it to start in 1 minute
- Meeting reminders create badge notifications

### 6. **Use Teams PowerShell or Graph API**
```powershell
# If you have Teams PowerShell module
Send-TeamChannelMessage -GroupId <team-id> -ChannelName "General" -Message "@YourName test"
```

## Quick test sequence:
1. Open any Teams channel
2. Type: "@[Your Full Name] testing notification"
3. Press Enter
4. Badge should appear within seconds