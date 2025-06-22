# Background Ringtone Solution

## Problem Solved ✅

**Issue:** Custom ringtone only played when app was in foreground, not in background.

**Solution:** Implemented dual approach for different app states.

## How It Works

### 🔴 **Background Notifications** (App closed/minimized)
- Uses **Raw Resource Sound** from `android/app/src/main/res/raw/notification_ringtone.ogg`
- Plays the custom ringtone through the system notification
- Works even when app is completely closed
- Duration: Brief (system notification sound length)

### 🟢 **Foreground Notifications** (App open)
- Uses **Raw Resource Sound** for initial notification
- **PLUS** AudioPlayer for extended playback (10-15 seconds)
- Provides both immediate and extended ringtone experience
- Duration: Extended (10-15 seconds via AudioPlayer)

## File Structure

```
your_app/
├── assets/
│   └── audio/
│       └── notification_ringtone.ogg  ← For AudioPlayer (extended playback)
└── android/
    └── app/
        └── src/
            └── main/
                └── res/
                    └── raw/
                        └── notification_ringtone.ogg  ← For system notifications
```

## Implementation Details

### Background Handler
```dart
const androidDetails = AndroidNotificationDetails(
  'bird_partner_channel',
  'Bird Partner Notifications',
  channelDescription: 'Notifications for Bird Partner app',
  importance: Importance.high,
  priority: Priority.high,
  icon: '@mipmap/ic_launcher',
  playSound: true,
  sound: RawResourceAndroidNotificationSound('notification_ringtone'), // ← Custom sound
);
```

### Foreground Handler
```dart
// 1. System notification with custom sound
const androidDetails = AndroidNotificationDetails(
  // ... same as background
  sound: RawResourceAndroidNotificationSound('notification_ringtone'),
);

// 2. Extended playback via AudioPlayer
await _audioPlayer.setSource(AssetSource('audio/notification_ringtone.ogg'));
await _audioPlayer.resume();
```

## Expected Behavior

### 📱 **App in Background/Closed**
- Notification appears with custom ringtone sound
- Sound plays for system notification duration (brief)
- No extended playback (AudioPlayer can't work in background)

### 📱 **App in Foreground**
- Notification appears with custom ringtone sound
- **PLUS** extended ringtone plays for 10-15 seconds
- AudioPlayer handles the extended playback

## Testing

### Test Background Notifications
1. Close the app completely
2. Send a notification
3. Should hear custom ringtone (brief)

### Test Foreground Notifications
1. Keep app open
2. Send a notification
3. Should hear custom ringtone (brief) + extended ringtone (10-15 seconds)

## Current Status

✅ **Background notifications** - Custom ringtone works  
✅ **Foreground notifications** - Custom ringtone + extended playback  
✅ **Error handling** - Graceful fallbacks  
✅ **File setup** - Both raw resource and assets configured  

## Troubleshooting

### If background notifications don't work:
1. Check `android/app/src/main/res/raw/notification_ringtone.ogg` exists
2. Verify file is actual audio (not placeholder)
3. Check device notification settings

### If foreground extended playback doesn't work:
1. Check `assets/audio/notification_ringtone.ogg` exists
2. Verify device media volume
3. Check debug logs for AudioPlayer errors

## Benefits

- **Consistent experience** - Custom ringtone in both states
- **Extended playback** - Longer ringtone when app is open
- **System integration** - Uses native notification sounds
- **Battery efficient** - No background audio processes
- **User friendly** - Works like native phone ringtones

The solution provides the best of both worlds: custom ringtone for all notifications, with extended playback when the app is open! 