// lib/test/delivery_partner_chat_test.dart - Test delivery partner chat functionality

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../services/chat_services.dart';
import '../services/delivery_partner_services/delivery_partner_auth_service.dart';
import '../presentation/screens/delivery_partner_pages/chat/view.dart';

class DeliveryPartnerChatTest extends StatefulWidget {
  const DeliveryPartnerChatTest({super.key});

  @override
  State<DeliveryPartnerChatTest> createState() => _DeliveryPartnerChatTestState();
}

class _DeliveryPartnerChatTestState extends State<DeliveryPartnerChatTest> {
  final SocketChatService _socketChatService = SocketChatService();
  String _connectionStatus = 'Not connected';
  String _testOrderId = 'test_order_123';
  List<String> _logMessages = [];

  @override
  void initState() {
    super.initState();
    _testSocketConnection();
  }

  Future<void> _testSocketConnection() async {
    try {
      _addLog('🔌 Testing delivery partner chat socket connection...');
      
      // Test 1: Check if delivery partner is authenticated
      final deliveryPartnerId = await DeliveryPartnerAuthService.getDeliveryPartnerId();
      final partnerId = await DeliveryPartnerAuthService.getDeliveryPartnerPartnerId();
      
      _addLog('🆔 Delivery Partner ID: $deliveryPartnerId');
      _addLog('🏪 Partner ID: $partnerId');
      
      if (deliveryPartnerId == null) {
        _addLog('❌ Delivery partner not authenticated');
        setState(() {
          _connectionStatus = 'Not authenticated';
        });
        return;
      }

      // Test 2: Connect to socket
      _addLog('🔌 Connecting to socket...');
      await _socketChatService.connect();
      
      setState(() {
        _connectionStatus = _socketChatService.isConnected ? 'Connected' : 'Failed to connect';
      });
      
      if (_socketChatService.isConnected) {
        _addLog('✅ Socket connected successfully');
        
        // Test 3: Join chat room
        _addLog('🚪 Joining chat room: $_testOrderId');
        await _socketChatService.joinRoom(_testOrderId);
        _addLog('✅ Joined chat room successfully');
        
        // Test 4: Load chat history
        _addLog('📚 Loading chat history...');
        await _socketChatService.loadChatHistory(_testOrderId);
        final messages = _socketChatService.messages;
        _addLog('📨 Loaded ${messages.length} messages');
        
        // Test 5: Listen for new messages
        _addLog('👂 Setting up message listener...');
        _socketChatService.messageStream.listen((message) {
          _addLog('📨 New message received: ${message.content}');
        });
        
        _addLog('✅ All tests completed successfully!');
        
      } else {
        _addLog('❌ Failed to connect to socket');
      }
      
    } catch (e) {
      _addLog('❌ Error during testing: $e');
      setState(() {
        _connectionStatus = 'Error: $e';
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logMessages.add('${DateTime.now().toString().substring(11, 19)} $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner Chat Test'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _connectionStatus.contains('Connected') ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _connectionStatus.contains('Connected') ? Colors.green : Colors.red,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connection Status:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _connectionStatus.contains('Connected') ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _connectionStatus,
                    style: TextStyle(
                      color: _connectionStatus.contains('Connected') ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Order Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Order Info:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Order ID: $_testOrderId'),
                  Text('Socket Connected: ${_socketChatService.isConnected}'),
                  Text('Messages Loaded: ${_socketChatService.messages.length}'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Log Messages
            const Text(
              'Test Log:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.builder(
                  itemCount: _logMessages.length,
                  itemBuilder: (context, index) {
                    final message = _logMessages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        message,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _logMessages.clear();
                        _connectionStatus = 'Not connected';
                      });
                      _testSocketConnection();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Re-run Test'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeliveryPartnerChatView(
                            orderId: _testOrderId,
                            isOrderActive: true,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Open Chat View'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 