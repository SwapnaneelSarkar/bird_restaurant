# Custom Ringtone Notification Setup Guide

This guide explains how to implement custom ringtone notifications that play like an incoming phone call for 10-15 seconds when notifications are received.

## Overview

The implementation includes:
- Custom audio file for ringtone sound
- AudioPlayer integration for extended playback
- Background and foreground notification handling
- Configurable ringtone duration
- Automatic stop after specified duration
- Error handling for missing audio files

## Setup Instructions

### 1. Audio File Preparation

1. **Create your custom ringtone audio file:**
   - Format: `.ogg` (preferred) or `.mp3`
   - Duration: 10-15 seconds (recommended)
   - Size: Keep under 1MB for optimal performance
   - Content: Should sound like an incoming phone call

2. **Place the audio files in both locations:**
   - **For AudioPlayer (extended playback):** `assets/audio/notification_ringtone.ogg`
   - **For Android system notifications:** `android/app/src/main/res/raw/notification_ringtone.ogg`
   - Replace the placeholder files that were created

### 2. Dependencies

The following dependencies have been added to `pubspec.yaml`:
```yaml
dependencies:
  audioplayers: ^6.1.0
```

### 3. Implementation Details

#### Notification Service Features

The `NotificationService` class now includes:

1. **Custom Ringtone Playback:**
   - `_playCustomRingtone()` - Internal method for playing ringtone
   - `playCustomRingtone()` - Public method with configurable duration
   - `stopRingtone()` - Public method to manually stop ringtone
   - `isPlayingRingtone` - Getter to check if ringtone is currently playing

2. **Automatic Integration:**
   - Foreground notifications automatically trigger ringtone
   - Background notifications use system notification sound
   - Ringtone loops for specified duration (default: 15 seconds)
   - Automatic stop after duration expires
   - Error handling for missing audio files

3. **Error Handling:**
   - Falls back to system sound if custom sound file is missing
   - Continues to work even if raw resource is not available
   - Provides detailed debug logs for troubleshooting

#### Usage Examples

```dart
// Get notification service instance
final notificationService = NotificationService();

// Play custom ringtone for 10 seconds
await notificationService.playCustomRingtone(durationSeconds: 10);

// Stop ringtone manually
await notificationService.stopRingtone();

// Check if ringtone is playing
if (notificationService.isPlayingRingtone) {
  print('Ringtone is currently playing');
}
```

### 4. Android Configuration

The Android notification channel is configured with error handling:
```dart
// Tries custom sound first, falls back to system sound if not available
NotificationDetails notificationDetails = _createNotificationDetails(useCustomSound: true);
```

### 5. iOS Configuration

For iOS, the notification sound is configured with error handling:
```dart
// Tries custom sound first, falls back to system sound if not available
const iosDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
  sound: 'notification_ringtone.ogg', // Optional, will fall back if not available
);
```

## Testing

### 1. Test Foreground Notifications
- Send a test notification while the app is open
- Verify the custom ringtone plays for the specified duration
- Check that the ringtone stops automatically

### 2. Test Background Notifications
- Send a test notification while the app is in background
- Verify the system notification sound plays
- Check that the notification appears correctly

### 3. Test Manual Control
```dart
// Test manual ringtone control
await notificationService.playCustomRingtone(durationSeconds: 5);
await Future.delayed(Duration(seconds: 2));
await notificationService.stopRingtone();
```

### 4. Test Error Handling
- Remove the audio files temporarily
- Send a notification
- Verify the app still works with system sounds
- Check debug logs for fallback messages

## Troubleshooting

### Common Issues

1. **Audio file not found:**
   - Ensure the file is placed in both locations:
     - `assets/audio/notification_ringtone.ogg`
     - `android/app/src/main/res/raw/notification_ringtone.ogg`
   - Check that the file is included in `pubspec.yaml` assets section
   - Run `flutter clean` and `flutter pub get`

2. **No sound playing:**
   - Check device volume settings
   - Verify audio file format is supported
   - Check for any audio permission issues
   - Look for fallback messages in debug logs

3. **Ringtones overlapping:**
   - The service prevents multiple ringtones from playing simultaneously
   - Check the `_isPlayingRingtone` flag

4. **Background notifications not working:**
   - Ensure Firebase Cloud Messaging is properly configured
   - Check Android manifest permissions
   - Verify notification channel settings

5. **"invalid_sound" error:**
   - This error occurs when the raw resource is missing
   - The app will automatically fall back to system sounds
   - Add the audio file to `android/app/src/main/res/raw/notification_ringtone.ogg`

### Debug Information

The service provides detailed debug logs:
- `🔔 Playing custom ringtone for X seconds...`
- `✅ Custom ringtone started playing`
- `🔔 Custom ringtone stopped`
- `❌ Error playing custom ringtone: [error]`
- `⚠️ Custom sound not available, using system sound: [error]`

## Customization Options

### 1. Change Ringtone Duration
```dart
// Play for 20 seconds
await notificationService.playCustomRingtone(durationSeconds: 20);
```

### 2. Change Audio File
1. Replace both audio files:
   - `assets/audio/notification_ringtone.ogg`
   - `android/app/src/main/res/raw/notification_ringtone.ogg`
2. Update the file path in the code if using a different filename

### 3. Add Multiple Ringtone Options
```dart
// Add different ringtones for different notification types
switch (message.data['type']) {
  case 'urgent':
    await _playCustomRingtone(durationSeconds: 20);
    break;
  case 'normal':
    await _playCustomRingtone(durationSeconds: 10);
    break;
}
```

## Performance Considerations

1. **Audio File Size:** Keep under 1MB for fast loading
2. **Format:** Use OGG format for better compression
3. **Duration:** 10-15 seconds is optimal for user experience
4. **Memory:** AudioPlayer automatically manages memory cleanup

## Security Notes

- Audio files are bundled with the app
- No external audio files are downloaded
- All audio playback is local to the device
- No sensitive data is transmitted during audio playback

## File Structure

```
your_app/
├── assets/
│   └── audio/
│       └── notification_ringtone.ogg  # For AudioPlayer
└── android/
    └── app/
        └── src/
            └── main/
                └── res/
                    └── raw/
                        └── notification_ringtone.ogg  # For Android notifications
``` 