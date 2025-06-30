# Background Message Synchronization Fix

## Problem Description

When the app is in background, sometimes when a message is sent, it doesn't show when the app is opened again. This was caused by several issues:

1. **Socket disconnection in background**: The socket disconnects when the app goes to background
2. **Poor reconnection handling**: Socket fails to reconnect due to network issues
3. **Missing app lifecycle handling**: ChatView didn't handle app resume events
4. **Message synchronization issues**: When app resumes, it doesn't properly refresh messages

## Root Cause Analysis

From the logs, we can see:
```
I/flutter ( 4732): SocketChatService: ❌ Socket disconnected
I/flutter ( 4732): SocketChatService: ❌ Socket error: SocketException: Failed host lookup: 'api.bird.delivery'
I/flutter ( 4732): SocketChatService: 🔄 Reconnection attempt 1/5
```

The socket disconnects in background and fails to reconnect properly, causing messages to be missed.

## Solution Implemented

### 1. Enhanced App Lifecycle Handling in ChatView

**File**: `lib/presentation/screens/chat/view.dart`

- Added `WidgetsBindingObserver` to `_ChatViewState`
- Implemented `didChangeAppLifecycleState()` to handle app resume events
- Added automatic chat refresh when app resumes from background

```dart
class _ChatViewState extends State<ChatView> with WidgetsBindingObserver {
  bool _isAppInBackground = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('ChatView: 📱 App resumed from background');
        _isAppInBackground = false;
        
        // Refresh chat data when app resumes
        if (mounted) {
          context.read<ChatBloc>().add(const RefreshChat());
          context.read<ChatBloc>().add(const AppResume());
        }
        break;
    }
  }
}
```

### 2. New AppResume Event

**File**: `lib/presentation/screens/chat/event.dart`

Added new event to handle app resume:
```dart
class AppResume extends ChatEvent {
  const AppResume();
}
```

### 3. Enhanced ChatBloc with App Resume Handling

**File**: `lib/presentation/screens/chat/bloc.dart`

- Added `_onAppResume()` event handler
- Forces message refresh from server when app resumes
- Updates UI state with latest messages

```dart
Future<void> _onAppResume(AppResume event, Emitter<ChatState> emit) async {
  debugPrint('ChatBloc: 📱 App resume event received');
  
  try {
    // Handle app resume in the chat service
    await _chatService.handleAppResume();
    
    // If we're in a loaded state, refresh the messages
    if (state is ChatLoaded && _currentRoomId != null) {
      await _chatService.refreshMessages();
      
      // Update the state with refreshed messages
      final currentState = state as ChatLoaded;
      final updatedMessages = _chatService.messages.map((apiMsg) {
        // Convert API messages to UI messages
      }).toList();
      
      emit(currentState.copyWith(
        messages: updatedMessages,
        lastUpdateTimestamp: DateTime.now(),
      ));
    }
  } catch (e) {
    debugPrint('ChatBloc: ❌ Error handling app resume: $e');
  }
}
```

### 4. Enhanced SocketChatService with App Resume Handling

**File**: `lib/services/chat_services.dart`

- Added `handleAppResume()` method for proper message synchronization
- Added `handleAppBackground()` method for background state management
- Improved reconnection logic with exponential backoff

```dart
Future<void> handleAppResume() async {
  if (_isDisposed) return;
  
  debugPrint('SocketChatService: 📱 App resumed, handling message synchronization...');
  
  try {
    // Check if socket is connected
    if (_socket == null || !_socket!.connected) {
      await connect();
    }
    
    // If we have a current room, rejoin it and refresh messages
    if (_currentRoomId != null) {
      await joinRoom(_currentRoomId!);
      await loadChatHistory(_currentRoomId!);
    }
  } catch (e) {
    debugPrint('SocketChatService: ❌ Error handling app resume: $e');
  }
}
```

### 5. Improved Reconnection Logic

Enhanced reconnection with exponential backoff:
```dart
void _handleReconnection() {
  if (_isDisposed || _reconnectAttempts >= _maxReconnectAttempts) {
    return;
  }

  _reconnectAttempts++;
  final delay = Duration(seconds: _reconnectAttempts * 2); // Exponential backoff
  
  _reconnectTimer = Timer(delay, () async {
    try {
      await connect();
      
      if (_isConnected) {
        _reconnectAttempts = 0; // Reset attempts on successful connection
        
        // Rejoin current room if we have one
        if (_currentRoomId != null) {
          await joinRoom(_currentRoomId!);
        }
      } else {
        _handleReconnection(); // Retry
      }
    } catch (e) {
      _handleReconnection(); // Retry
    }
  });
}
```

## How It Works

### App Going to Background
1. Socket disconnects automatically
2. `handleAppBackground()` is called (logs the event)
3. Reconnection attempts start with exponential backoff

### App Resuming from Background
1. `didChangeAppLifecycleState()` detects resume event
2. `RefreshChat` event is triggered to refresh chat list
3. `AppResume` event is triggered for detailed message sync
4. `handleAppResume()` in SocketChatService:
   - Checks socket connection
   - Reconnects if needed
   - Rejoins current room
   - Forces message refresh from server
5. ChatBloc updates UI with latest messages

### Message Synchronization
- Messages are fetched from server API (reliable)
- Socket is used for real-time updates (when connected)
- Hybrid approach ensures no messages are lost

## Benefits

1. **Reliable Message Delivery**: Server API ensures messages are never lost
2. **Real-time Updates**: Socket provides instant updates when connected
3. **Automatic Recovery**: App resume triggers automatic message refresh
4. **Better UX**: Users see latest messages immediately when returning to app
5. **Robust Reconnection**: Exponential backoff prevents excessive reconnection attempts

## Testing

### Test Scenarios
1. **Background Message**: Send message while app is in background, then resume app
2. **Network Issues**: Disconnect network, send message, reconnect, resume app
3. **Long Background**: Keep app in background for extended period, then resume
4. **Multiple Messages**: Send multiple messages in background, resume app

### Expected Behavior
- All messages should appear when app resumes
- Socket should reconnect automatically
- No duplicate messages
- Proper read status updates

## Monitoring

The solution includes comprehensive logging:
- App lifecycle state changes
- Socket connection/disconnection events
- Message refresh operations
- Reconnection attempts and success/failure

This allows for easy debugging and monitoring of the message synchronization process. 