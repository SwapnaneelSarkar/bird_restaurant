# Notification Type Handling

## Overview

The notification system now supports different notification types with conditional ringtone behavior based on the `type` field in the notification data.

## Supported Notification Types

### 1. `new_order`
- **Custom Ringtone**: ✅ Enabled
- **Extended Playback**: ✅ 15 seconds via AudioPlayer
- **System Sound**: ✅ Custom ringtone file
- **Use Case**: New orders received by restaurant partners

### 2. `chat_message`
- **Custom Ringtone**: ❌ Disabled
- **Extended Playback**: ❌ Disabled
- **System Sound**: ✅ Default system notification sound
- **Use Case**: Chat messages from customers

### 3. Other Types (default)
- **Custom Ringtone**: ❌ Disabled
- **Extended Playback**: ❌ Disabled
- **System Sound**: ✅ Default system notification sound
- **Use Case**: General notifications, updates, etc.

## Implementation Details

### Foreground Notifications
```dart
// Check notification type
final notificationType = message.data['type'];

// Conditionally play custom ringtone
if (notificationType == 'new_order') {
  await _playCustomRingtone(); // Custom ringtone + extended playback
} else {
  // System default sound only
}
```

### Background Notifications
```dart
// Check notification type
final notificationType = message.data['type'];

// Create notification details based on type
if (notificationType == 'new_order') {
  // Use custom sound
  sound: RawResourceAndroidNotificationSound('notification_ringtone')
} else {
  // Use system default sound
  // No custom sound specified
}
```

## Testing

### Test Methods Available
1. **`testNewOrderNotification()`** - Tests new order notification with custom ringtone
2. **`testChatMessageNotification()`** - Tests chat message notification with system sound
3. **`testNotification()`** - Tests generic notification with system sound

### Test Widget Features
- **New Order Button** (Green) - Tests custom ringtone behavior
- **Chat Message Button** (Blue) - Tests system sound behavior
- **Generic Test Button** (Orange) - Tests default behavior
- **Audio Only Button** (Purple) - Tests direct audio playback

## Expected Behavior

### New Order Notifications (`type: 'new_order'`)
1. System notification appears with custom ringtone sound
2. Custom ringtone plays for 15 seconds (if app is in foreground)
3. Extended playback via AudioPlayer
4. Automatic stop after duration

### Chat Message Notifications (`type: 'chat_message'`)
1. System notification appears with default system sound
2. No custom ringtone playback
3. No extended audio playback
4. Standard notification behavior

### Other Notifications (any other type)
1. System notification appears with default system sound
2. No custom ringtone playback
3. No extended audio playback
4. Standard notification behavior

## Debug Logs

The system provides detailed debug logs for troubleshooting:

```
🔔 Notification type: new_order
🔔 Creating notification details - Type: new_order, Custom sound: true
🔔 Playing custom ringtone for new order notification
```

```
🔔 Notification type: chat_message
🔔 Creating notification details - Type: chat_message, Custom sound: false
🔔 Skipping custom ringtone for notification type: chat_message
```

## Configuration

### Adding New Notification Types
To add support for new notification types:

1. **Update the condition in `_showLocalNotification()`**:
```dart
if (notificationType == 'new_order' || notificationType == 'urgent_order') {
  await _playCustomRingtone();
}
```

2. **Update the condition in `_createNotificationDetails()`**:
```dart
final useCustomSound = notificationType == 'new_order' || notificationType == 'urgent_order';
```

3. **Update background handler**:
```dart
final useCustomSound = notificationType == 'new_order' || notificationType == 'urgent_order';
```

### Customizing Ringtone Duration
```dart
// For different notification types
switch (notificationType) {
  case 'new_order':
    await _playCustomRingtone(durationSeconds: 15);
    break;
  case 'urgent_order':
    await _playCustomRingtone(durationSeconds: 20);
    break;
  default:
    // No custom ringtone
    break;
}
```

## Benefits

1. **User Experience**: Different notification types have appropriate audio feedback
2. **Battery Efficiency**: Custom ringtone only plays for important notifications
3. **Flexibility**: Easy to add new notification types with different behaviors
4. **Consistency**: System sounds for less critical notifications
5. **Customization**: Configurable duration and behavior per notification type

## Troubleshooting

### Custom Ringtone Not Playing for New Orders
1. Check notification data includes `"type": "new_order"`
2. Verify audio file exists in both locations
3. Check device media volume
4. Review debug logs for type detection

### System Sound Not Playing for Chat Messages
1. Check notification data includes `"type": "chat_message"`
2. Verify device notification settings
3. Check app notification permissions
4. Review debug logs for type detection

### Testing Different Types
1. Use the test buttons in the ringtone test widget
2. Send test notifications with different `type` values
3. Monitor debug logs for behavior confirmation
4. Verify audio behavior matches expectations 