// lib/views/chat_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import 'service.dart';

class ChatView1 extends StatelessWidget {
  const ChatView1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(chatService: ChatService())
        ..add(InitializeChat())
        ..add(LoadChatRooms()),
      child: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    print('🔵 View: _sendMessage called with content: "$content"');
    if (content.isNotEmpty) {
      print('🔵 View: Dispatching SendMessage event');
      context.read<ChatBloc>().add(SendMessage(content: content));
      _messageController.clear();
      print('🔵 View: SendMessage event dispatched, text field cleared');
    } else {
      print('🔵 View: Message content is empty, not sending');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            return Text(state.currentChatRoom?.orderId ?? 'Chat');
          },
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Icon(
                      state.isSocketConnected ? Icons.wifi : Icons.wifi_off,
                      color: state.isSocketConnected ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.isSocketConnected ? 'WebSocket Connected' : 'WebSocket Disconnected',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state.status == ChatStatus.messageReceived ||
              state.status == ChatStatus.messageSent) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }

          if (state.status == ChatStatus.error && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state.isLoadingHistory) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet.\nStart a conversation!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final isMe = message.senderId == ChatService.userId;

                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Chat Rooms',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              if (state.isLoadingRooms)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state.chatRooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No chat rooms available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                ...state.chatRooms.map((room) => ListTile(
                  title: Text('Order: ${room.orderId}'),
                  subtitle: Text(
                    room.lastMessage.isNotEmpty 
                        ? room.lastMessage 
                        : 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatTime(room.lastMessageTime),
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: state.currentRoomId == room.roomId,
                  onTap: () {
                    context.read<ChatBloc>().add(
                      SwitchToRoom(
                        roomId: room.roomId,
                        orderId: room.orderId,
                      ),
                    );
                    Navigator.pop(context);
                  },
                )),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh Rooms'),
                onTap: () {
                  context.read<ChatBloc>().add(LoadChatRooms());
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Clear Messages'),
                onTap: () {
                  context.read<ChatBloc>().add(ClearMessages());
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 6,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      print('🔵 View: Text field submitted');
                      _sendMessage();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    return FloatingActionButton(
                      onPressed: state.isSendingMessage ? null : () {
                        print('🔵 View: Main send button pressed');
                        _sendMessage();
                      },
                      mini: true,
                      child: state.isSendingMessage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print('🔵 View: WebSocket send button pressed');
                      _sendWebSocketMessage();
                    },
                    icon: const Icon(Icons.wifi),
                    label: const Text('Send via WebSocket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testWebSocketConnection(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Test Connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // if (ChatService.testMode)
            //   ElevatedButton.icon(
            //     onPressed: () => _simulateReceivedMessage(),
            //     icon: const Icon(Icons.message),
            //     label: const Text('Simulate Received Message'),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.purple,
            //       foregroundColor: Colors.white,
            //     ),
            //   ),
            const SizedBox(height: 8),
            // if (ChatService.testMode)
            //   ElevatedButton.icon(
            //     onPressed: () => _testDirectMessage(),
            //     icon: const Icon(Icons.add),
            //     label: const Text('Test Direct Message'),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.red,
            //       foregroundColor: Colors.white,
            //     ),
            //   ),
            const SizedBox(height: 8),
            // if (ChatService.testMode)
            //   ElevatedButton.icon(
            //     onPressed: () => _testBlocEvent(),
            //     icon: const Icon(Icons.flash_on),
            //     label: const Text('Test BLoC Event'),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.amber,
            //       foregroundColor: Colors.black,
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  void _sendWebSocketMessage() {
    final content = _messageController.text.trim();
    print('🔵 View: _sendWebSocketMessage called with content: "$content"');
    if (content.isNotEmpty) {
      print('🔵 View: Calling chatService.sendMessage directly');
      final chatService = context.read<ChatBloc>().chatService;
      chatService.sendMessage(content);
      _messageController.clear();
      print('🔵 View: WebSocket message sent, text field cleared');
    } else {
      print('🔵 View: WebSocket message content is empty, not sending');
    }
  }

  void _testWebSocketConnection() {
    final chatService = context.read<ChatBloc>().chatService;
    if (chatService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WebSocket is connected!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WebSocket is disconnected. Attempting to reconnect...'),
          backgroundColor: Colors.orange,
        ),
      );
      chatService.connect();
    }
  }

  void _simulateReceivedMessage() {
    final chatService = context.read<ChatBloc>().chatService;
    if (chatService.isConnected) {
      chatService.simulateReceivedMessage('This is a simulated message from partner');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulated received message'),
          backgroundColor: Colors.purple,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WebSocket is disconnected. Cannot simulate received message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testDirectMessage() {
    final chatService = context.read<ChatBloc>().chatService;
    if (chatService.isConnected) {
      chatService.simulateReceivedMessage('This is a direct message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Direct message sent'),
          backgroundColor: Colors.purple,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WebSocket is disconnected. Cannot send direct message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testBlocEvent() {
    print('🔵 View: Testing BLoC event directly');
    
    // Create a test message
    final testMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: 'test-room',
      senderId: 'test-sender',
      receiverId: ChatService.userId,
      content: 'This is a direct BLoC test message',
      messageType: 'text',
      timestamp: DateTime.now(),
      readBy: [],
    );
    
    print('🔵 View: Dispatching MessageReceived event directly');
    context.read<ChatBloc>().add(MessageReceived(testMessage));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Direct BLoC event dispatched'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}