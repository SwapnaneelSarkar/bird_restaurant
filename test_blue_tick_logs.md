# Blue Tick Logging Test Guide

## How to Test Blue Tick Functionality

### 1. Run the App with Debug Logs

```bash
# Run the app with verbose logging
flutter run --verbose

# Or run with specific logging level
flutter run --debug
```

### 2. Check for Blue Tick Logs

Look for these specific log patterns in the console:

#### ✅ Expected Logs for Blue Tick Updates:

```
# When message is received
SocketChatService: 📥 Received message via socket: {...}
SocketChatService: 👁️ Emitting message_seen event: {...}
SocketChatService: 🔵 Message ID: message-123
SocketChatService: 🔵 Room ID: room-456
SocketChatService: 🔵 Seen By: user-789
SocketChatService: ✅ message_seen event emitted successfully

# When read status is updated
SocketChatService: 👁️ Processing message seen event...
SocketChatService: 👁️ Message message-123 seen by user-789 at 2024-01-01T12:00:00.000Z
SocketChatService: ✅ Updated seen status for message: message-123
SocketChatService: 🔵 Blue tick status: true

# ChatBloc receiving read status updates
ChatBloc: 🔵 Received read status update: message_seen
ChatBloc: 🔵 Updated X messages with new read status

# UI updates
ChatView: 🔄 Forced refresh of read status
```

#### ❌ Error Logs to Watch For:

```
# Connection issues
SocketChatService: ❌ Cannot emit message_seen - Socket: null, Connected: false, UserID: null
SocketChatService: ❌ Socket connection timeout

# Stream issues
ChatBloc: ❌ Error in read status stream: ...
SocketChatService: ❌ Error handling message seen event: ...

# Missing data
SocketChatService: ❌ Message not found for seen update: message-123
SocketChatService: ❌ Invalid message seen data format
```

### 3. Test Scenarios

#### Scenario 1: Send Message and Check Blue Tick
1. Send a message from User A
2. Check logs for: `message_seen event emitted`
3. Receive message on User B
4. Check logs for: `Blue tick status: true`

#### Scenario 2: Real-time Blue Tick Update
1. Have two users in chat
2. User A sends message (should show grey ticks)
3. User B opens chat (should emit message_seen)
4. User A should see blue ticks immediately

#### Scenario 3: Bulk Read Status
1. Send multiple messages
2. Mark room as read
3. Check logs for: `bulk_messages_read` and `Updated X messages with blue ticks`

### 4. Using the Test Files

#### Run Blue Tick Test:
```dart
// Navigate to the test screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const BlueTickLoggingTest()),
);
```

#### Run Socket Chat Test:
```dart
// Navigate to the socket test screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SocketChatTest()),
);
```

### 5. Debug Commands

Add these to your chat screen for manual testing:

```dart
// Add to ChatView for debugging
FloatingActionButton(
  onPressed: () {
    debugPrint('🔧 Manual: Testing blue tick functionality');
    final chatBloc = context.read<ChatBloc>();
    chatBloc.add(MarkMessageAsSeen('test-message-${DateTime.now().millisecondsSinceEpoch}'));
  },
  child: const Icon(Icons.bug_report),
),
```

### 6. Log Analysis Checklist

- [ ] Socket connection established
- [ ] message_seen events are emitted when messages received
- [ ] Read status stream receives updates
- [ ] ChatBloc processes read status updates
- [ ] UI updates with blue ticks
- [ ] No error logs in the process

### 7. Common Issues and Solutions

#### Issue: Blue ticks not appearing
**Check:**
- Socket connection status
- message_seen events being emitted
- Read status stream working
- UI state updates

#### Issue: Delayed blue tick updates
**Check:**
- Network connectivity
- Socket reconnection logic
- Debounced update timers

#### Issue: Blue ticks appearing for wrong messages
**Check:**
- Message ID matching logic
- Read status calculation
- State management in ChatBloc

### 8. Performance Monitoring

Monitor these metrics:
- Time from message received to blue tick update
- Socket connection stability
- Stream processing performance
- UI update frequency

### 9. Expected Log Flow

```
1. Message Sent → REST API + Socket
2. Message Received → message_seen emitted
3. Read Status Stream → ChatBloc update
4. UI Update → Blue ticks appear
```

### 10. Testing with Real Devices

For real-time testing:
1. Use two physical devices
2. Ensure both are connected to same network
3. Monitor logs on both devices
4. Test message sending/receiving
5. Verify blue tick updates in real-time

This guide will help you verify that the blue tick functionality is working correctly with real-time socket updates. 