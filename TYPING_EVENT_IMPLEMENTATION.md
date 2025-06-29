# Typing Event Implementation Strategy

## Overview

This document outlines the implementation of a **page-lifecycle and message-receipt-based typing system** that uses typing events as a mechanism to trigger blue tick updates for both previous and new messages on an open chat page.

## Core Strategy

### **Implementation Flow**:
```
Chat Page Opens → Emit "user_typing" (once) → Updates blue ticks for previous messages
↓
Wait for new messages...
↓
New Message Received + Page is Open → Emit "user_typing" → Updates blue ticks for new message
↓
Chat Page Closes → Emit "user_stop_typing"
```

### **Key Requirements**:
- **On page open**: Single typing emission to handle previous unread messages
- **On message receipt**: Emit typing when new message arrives on active chat page
- **No continuous emission**: Don't emit typing every few seconds
- **Page state awareness**: Only emit if the specific chat page is currently visible/active
- **Clean stop**: Always emit stop_typing when leaving the page
- **Symmetrical behavior**: Both User and Partner apps emit typing events

## Implementation Details

### 1. Socket Event Names
- **Emitted events**: `user_typing`, `user_stop_typing`
- **Listened events**: `user_typing`, `user_stop_typing`

### 2. Files Modified

#### `lib/services/chat_services.dart`
- Updated `sendTyping()` and `sendStopTyping()` methods to emit correct event names
- Enhanced `user_typing` event listener to trigger `_markAllMessagesAsReadForBlueTicks()`
- Added comprehensive blue tick update logic in `_markAllMessagesAsReadForBlueTicks()`
- **Temporarily disabled**: `message_seen` event listener and `_handleMessageSeen()` method
- **NEW**: Auto-emission of typing events when receiving messages

#### `lib/services/socket_chat_service.dart`
- Updated typing event listeners to use `user_typing` and `user_stop_typing`
- Added `_markAllMessagesAsReadForBlueTicks()` method
- Updated `sendTyping()` and `sendStopTyping()` methods
- **Temporarily disabled**: `message_seen` event listener, `_handleMessageSeen()`, `_emitMessageSeen()`, and `markMessageAsSeen()` methods
- **NEW**: Auto-emission of typing events when receiving messages

#### `lib/presentation/screens/chat/view.dart`
- **Page Open**: `_emitTypingOnPageOpen()` - Emits typing once when chat page opens
- **New Message**: `_emitTypingOnNewMessage()` - Emits typing when new message received
- **Page Close**: `dispose()` - Emits stop typing when leaving chat page
- **Timing Control**: View layer controls when to start/stop typing (3-second intervals)
- **Temporarily disabled**: `_markMessageAsSeen()` method

#### `lib/presentation/screens/chat/bloc.dart`
- Updated `_onStartTyping()` to remove auto-timer (now controlled by view)
- Enhanced read status stream handling for typing-based blue tick updates
- Added support for `typing_blue_tick_update` events
- **Temporarily disabled**: `_onMarkMessageAsSeen()` event handler

### 3. Blue Tick Update Logic

The `_markAllMessagesAsReadForBlueTicks()` method:
- Iterates through all messages in the current room
- Updates messages sent by current user that aren't already read
- Adds a dummy read entry (`typing_user`) to simulate message being read
- Emits updates through the read status stream for UI updates
- Triggers `notifyListeners()` for immediate UI refresh

### 4. Event Flow

#### Page Open Flow:
1. Chat page initializes
2. After 500ms delay: `_emitTypingOnPageOpen()` called
3. `StartTyping` event sent to bloc
4. `sendTyping()` emits `user_typing` via socket
5. Socket listener triggers `_markAllMessagesAsReadForBlueTicks()`
6. Blue ticks updated for previous messages
7. After 3 seconds: `StopTyping` event sent automatically

#### New Message Flow:
1. New message received via socket
2. `_handleReceivedMessage()` processes message
3. **NEW**: Auto-emit typing event immediately
4. `_checkForNewMessages()` detects new message
5. `_emitTypingOnNewMessage()` called (additional typing emission)
6. `StartTyping` event sent to bloc
7. `sendTyping()` emits `user_typing` via socket
8. Socket listener triggers `_markAllMessagesAsReadForBlueTicks()`
9. Blue ticks updated for new message
10. After 3 seconds: `StopTyping` event sent automatically

#### Page Close Flow:
1. `dispose()` called when leaving chat page
2. `StopTyping` event sent to bloc
3. `sendStopTyping()` emits `user_stop_typing` via socket
4. Clean typing state

### 5. Symmetrical Behavior

**Both User and Partner apps now:**
- ✅ **Emit typing** when chat page opens
- ✅ **Emit typing** when receiving messages
- ✅ **Listen for typing** events to update blue ticks
- ✅ **Stop typing** when leaving chat page

**This ensures bidirectional blue tick updates:**
- User sends message → Partner receives → Partner emits typing → User updates blue ticks
- Partner sends message → User receives → User emits typing → Partner updates blue ticks

## Current Status

### ✅ **Active Implementation**
- **Typing Events**: Fully implemented and active
- **Blue Tick Updates**: Working via typing events
- **Page Lifecycle Management**: Proper start/stop typing
- **Auto-Emission**: Typing events auto-emitted when receiving messages
- **Symmetrical Behavior**: Both apps emit and listen for typing events

### 🔄 **Temporarily Disabled**
- **Message Seen Events**: All `message_seen` functionality commented out
- **Individual Message Seen**: `MarkMessageAsSeen` events disabled
- **Manual Seen Updates**: `_emitMessageSeen()` and `markMessageAsSeen()` disabled

### 📝 **Testing Focus**
The current implementation focuses on testing the **typing event strategy** in isolation to verify:
1. Blue tick updates work solely through typing events
2. Page lifecycle typing events function correctly
3. No conflicts with message_seen events
4. Performance and reliability of typing-based approach
5. Symmetrical behavior between User and Partner apps

## Benefits

1. **Reliable Blue Tick Updates**: Typing events provide a consistent mechanism for triggering read status updates
2. **Page-Aware**: Only emits typing when chat page is actually open and active
3. **Real-Time**: Immediate blue tick updates without waiting for actual user interaction
4. **Clean State Management**: Proper cleanup when leaving chat page
5. **Backward Compatible**: Works with existing socket infrastructure
6. **Isolated Testing**: Can test typing strategy without message_seen interference
7. **Symmetrical Communication**: Both apps participate in typing-based blue tick updates

## Debug Logs

The implementation includes comprehensive logging:
- `🔵` - Blue tick related operations
- `⌨️` - Typing events
- `📡` - Socket emissions
- `✅` - Successful operations
- `❌` - Error conditions

## Testing

To test the implementation:
1. Open a chat page - should see typing indicator and blue tick updates
2. Send a message - should see blue tick updates for previous messages
3. Receive a message - should see typing indicator and blue tick updates
4. Close chat page - should see stop typing event
5. **NEW**: Verify symmetrical behavior between User and Partner apps

## Future Enhancements

1. **Typing Debouncing**: Add debouncing to prevent excessive typing events
2. **Typing Indicators**: Show actual typing indicators in UI
3. **Typing Timeout**: Configurable timeout for typing events
4. **Typing Analytics**: Track typing patterns for insights
5. **Message Seen Re-enablement**: Option to re-enable message_seen events if needed 