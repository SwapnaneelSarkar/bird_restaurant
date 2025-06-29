// lib/test/socket_chat_test.dart - Test file for Socket Chat with Message Seen functionality

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chat_services.dart';

class SocketChatTest extends StatefulWidget {
  const SocketChatTest({Key? key}) : super(key: key);

  @override
  State<SocketChatTest> createState() => _SocketChatTestState();
}

class _SocketChatTestState extends State<SocketChatTest> {
  final SocketChatService _chatService = SocketChatService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _messageIdController = TextEditingController();
  
  String _connectionStatus = 'Disconnected';
  String _lastEvent = 'No events yet';
  List<String> _events = [];
  List<ApiChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _setupChatService();
  }

  void _setupChatService() {
    // Listen to chat service changes
    _chatService.addListener(() {
      setState(() {
        _messages = _chatService.messages;
        _connectionStatus = _chatService.isConnected ? 'Connected' : 'Disconnected';
      });
    });

    // Listen to message stream
    _chatService.messageStream.listen((message) {
      setState(() {
        _events.add('📥 New message: ${message.content}');
        _lastEvent = '📥 New message: ${message.content}';
      });
    });
  }

  @override
  void dispose() {
    _chatService.dispose();
    _messageController.dispose();
    _roomIdController.dispose();
    _messageIdController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    try {
      await _chatService.connect();
      setState(() {
        _events.add('🔌 Connection attempt initiated');
        _lastEvent = '🔌 Connection attempt initiated';
      });
    } catch (e) {
      setState(() {
        _events.add('❌ Connection error: $e');
        _lastEvent = '❌ Connection error: $e';
      });
    }
  }

  Future<void> _joinRoom() async {
    final roomId = _roomIdController.text.trim();
    if (roomId.isEmpty) {
      setState(() {
        _events.add('⚠️ Please enter a room ID');
        _lastEvent = '⚠️ Please enter a room ID';
      });
      return;
    }

    try {
      await _chatService.joinRoom(roomId);
      setState(() {
        _events.add('🏠 Joined room: $roomId');
        _lastEvent = '🏠 Joined room: $roomId';
      });
    } catch (e) {
      setState(() {
        _events.add('❌ Error joining room: $e');
        _lastEvent = '❌ Error joining room: $e';
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _events.add('⚠️ Please enter a message');
        _lastEvent = '⚠️ Please enter a message';
      });
      return;
    }

    try {
      final roomId = _roomIdController.text.trim();
      if (roomId.isEmpty) {
        setState(() {
          _events.add('⚠️ Please enter a room ID first');
          _lastEvent = '⚠️ Please enter a room ID first';
        });
        return;
      }

      final success = await _chatService.sendMessage(roomId, message);
      if (success) {
        setState(() {
          _events.add('📤 Message sent: $message');
          _lastEvent = '📤 Message sent: $message';
        });
        _messageController.clear();
      } else {
        setState(() {
          _events.add('❌ Failed to send message');
          _lastEvent = '❌ Failed to send message';
        });
      }
    } catch (e) {
      setState(() {
        _events.add('❌ Error sending message: $e');
        _lastEvent = '❌ Error sending message: $e';
      });
    }
  }

  void _markAsRead() {
    final roomId = _roomIdController.text.trim();
    if (roomId.isEmpty) {
      setState(() {
        _events.add('⚠️ Please enter a room ID');
        _lastEvent = '⚠️ Please enter a room ID';
      });
      return;
    }

    try {
      _chatService.markAsReadViaSocket(roomId);
      setState(() {
        _events.add('📖 Marked room as read: $roomId');
        _lastEvent = '📖 Marked room as read: $roomId';
      });
    } catch (e) {
      setState(() {
        _events.add('❌ Error marking as read: $e');
        _lastEvent = '❌ Error marking as read: $e';
      });
    }
  }

  void _emitMessageSeen() {
    final messageId = _messageIdController.text.trim();
    if (messageId.isEmpty) {
      setState(() {
        _events.add('⚠️ Please enter a message ID');
        _lastEvent = '⚠️ Please enter a message ID';
      });
      return;
    }

    try {
      _chatService.emitMessageSeen(messageId);
      setState(() {
        _events.add('👁️ Emitted message_seen: $messageId');
        _lastEvent = '👁️ Emitted message_seen: $messageId';
      });
    } catch (e) {
      setState(() {
        _events.add('❌ Error emitting message_seen: $e');
        _lastEvent = '❌ Error emitting message_seen: $e';
      });
    }
  }

  void _testConnection() async {
    try {
      final health = await _chatService.checkConnectionHealth();
      setState(() {
        _events.add('🔍 Connection health: ${health.toString()}');
        _lastEvent = '🔍 Connection health: ${health.toString()}';
      });
    } catch (e) {
      setState(() {
        _events.add('❌ Error checking connection health: $e');
        _lastEvent = '❌ Error checking connection health: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket Chat Test'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status: $_connectionStatus',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _connectionStatus == 'Connected' ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last Event: $_lastEvent',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Connection Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Connection Controls',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _connect,
                            child: const Text('Connect'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _testConnection,
                            child: const Text('Test Connection'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Room Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Room Controls',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _roomIdController,
                      decoration: const InputDecoration(
                        labelText: 'Room ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _joinRoom,
                      child: const Text('Join Room'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Message Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Message Controls',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _sendMessage,
                            child: const Text('Send Message'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _markAsRead,
                            child: const Text('Mark Room as Read'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Message Seen Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Message Seen Controls',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageIdController,
                      decoration: const InputDecoration(
                        labelText: 'Message ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _emitMessageSeen,
                      child: const Text('Emit Message Seen'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Messages List
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Messages (${_messages.length})',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return ListTile(
                              title: Text(message.content),
                              subtitle: Text(
                                '${message.senderId} - ${message.createdAt.toString()}',
                              ),
                              trailing: Text(
                                'Read: ${message.readBy.length}',
                                style: TextStyle(
                                  color: message.readBy.isNotEmpty ? Colors.green : Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Events Log
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Events Log',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _events.clear();
                              });
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                _events[_events.length - 1 - index],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 