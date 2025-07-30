// lib/test/blue_tick_logging_test.dart - Simple logging test for Blue Tick functionality

import 'package:flutter/material.dart';
import '../services/chat_services.dart';

class BlueTickLoggingTest extends StatefulWidget {
  const BlueTickLoggingTest({Key? key}) : super(key: key);

  @override
  State<BlueTickLoggingTest> createState() => _BlueTickLoggingTestState();
}

class _BlueTickLoggingTestState extends State<BlueTickLoggingTest> {
  final SocketChatService _chatService = SocketChatService();
  List<ApiChatMessage> _messages = [];
  String _connectionStatus = 'Disconnected';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _setupChatService();
  }

  void _setupChatService() {
    _chatService.addListener(() {
      setState(() {
        _messages = _chatService.messages;
        _connectionStatus = _chatService.isConnected ? 'Connected' : 'Disconnected';
      });
      _addLog('🔄 Chat service updated - Messages: ${_messages.length}');
    });

    _chatService.readStatusStream.listen((readStatusData) {
      _addLog('🔵 Read status: ${readStatusData['type']} - Message: ${readStatusData['messageId']} - IsRead: ${readStatusData['isRead']}');
    });
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
      if (_logs.length > 30) {
        _logs = _logs.take(30).toList();
      }
    });
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blue Tick Logging Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Status: $_connectionStatus'),
            Text('Messages: ${_messages.length}'),
            Text('Blue Ticks: ${_messages.where((m) => m.isRead).length}'),
            
            ElevatedButton(
              onPressed: () async {
                _addLog('🔌 Connecting...');
                await _chatService.connect();
              },
              child: const Text('Connect'),
            ),
            
            ElevatedButton(
              onPressed: () {
                _addLog('👁️ Testing message seen');
                // _chatService.emitMessageSeen('test-message-123');
              },
              child: const Text('Test Message Seen'),
            ),
            
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Text(_logs[index], style: const TextStyle(fontSize: 12));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 