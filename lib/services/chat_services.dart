// lib/services/chat_services.dart - SIMPLE SENDER ID COMPARISON

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'token_service.dart';

class ApiChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderType;
  final String content;
  final String messageType;
  final List<String> readBy;
  final DateTime createdAt;

  ApiChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.messageType,
    required this.readBy,
    required this.createdAt,
  });

  factory ApiChatMessage.fromJson(Map<String, dynamic> json) {
    return ApiChatMessage(
      id: json['_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? '',
      content: json['content'] ?? json['message'] ?? '',
      messageType: json['messageType'] ?? 'text',
      readBy: List<String>.from(json['readBy'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  // SIMPLE: Check if this message is from current user by comparing sender IDs
  bool isFromCurrentUser(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return false;
    
    final isMatch = senderId == currentUserId;
    debugPrint('ChatService: 🔍 Comparing sender IDs:');
    debugPrint('  - Message sender ID: "$senderId"');
    debugPrint('  - Current user ID: "$currentUserId"');
    debugPrint('  - Match: $isMatch');
    debugPrint('  - Message: "${content.length > 20 ? content.substring(0, 20) + '...' : content}"');
    
    return isMatch;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderType': senderType,
      'content': content,
      'messageType': messageType,
      'readBy': readBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PollingChatService extends ChangeNotifier {
  List<ApiChatMessage> _messages = [];
  bool _isPolling = false;
  String? _currentRoomId;
  String? _currentUserId;
  Timer? _pollingTimer;
  Timer? _typingTimer;
  Timer? _frequencyResetTimer;
  bool _isDisposed = false;
  DateTime? _lastMessageTime;
  int _pollIntervalMs = 3000; // Start with 3 seconds
  int _consecutiveEmptyPolls = 0;
  bool _isLoadingHistory = false;

  // Stream controller for real-time message updates
  final StreamController<ApiChatMessage> _messageStreamController = 
      StreamController<ApiChatMessage>.broadcast();
  
  List<ApiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isPolling; // Use polling status as "connected"
  String? get currentUserId => _currentUserId;
  
  Stream<ApiChatMessage> get messageStream => _messageStreamController.stream;

  PollingChatService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      _currentUserId = await TokenService.getUserId();
      debugPrint('PollingChatService: 🆔 User ID retrieved: $_currentUserId');
    } catch (e) {
      debugPrint('PollingChatService: ❌ Error getting user ID: $e');
    }
  }

  Future<void> startPolling() async {
    if (_isDisposed || _isPolling) return;
    
    debugPrint('PollingChatService: 🔄 Starting polling with ${_pollIntervalMs}ms interval...');
    _isPolling = true;
    _consecutiveEmptyPolls = 0;
    notifyListeners();
    
    _pollingTimer = Timer.periodic(Duration(milliseconds: _pollIntervalMs), (timer) {
      if (!_isDisposed && _currentRoomId != null && !_isLoadingHistory) {
        _pollForNewMessages();
      }
    });
  }

  void stopPolling() {
    debugPrint('PollingChatService: ⏹️ Stopping polling...');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _frequencyResetTimer?.cancel();
    _frequencyResetTimer = null;
    _isPolling = false;
    _consecutiveEmptyPolls = 0;
    notifyListeners();
  }

  Future<void> _pollForNewMessages() async {
    if (_isDisposed || _currentRoomId == null || _isLoadingHistory) return;
    
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('PollingChatService: ❌ No token available for polling');
        return;
      }
      
      // Use a timestamp-based query to get only new messages
      String url = '${ApiConstants.baseUrl}/chat/history/$_currentRoomId';
      if (_lastMessageTime != null) {
        // Add timestamp filter to get only messages after the last known message
        final timestamp = _lastMessageTime!.millisecondsSinceEpoch;
        url += '?after=$timestamp&limit=50'; // Limit to prevent large responses
      } else {
        url += '?limit=50'; // Get recent messages if no timestamp
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> newMessagesData = jsonDecode(response.body);
        
        if (newMessagesData.isNotEmpty) {
          debugPrint('PollingChatService: 📥 Polling found ${newMessagesData.length} messages');
          
          final newMessages = newMessagesData
              .map((messageJson) => ApiChatMessage.fromJson(messageJson))
              .where((msg) => !_messages.any((existing) => existing.id == msg.id))
              .toList();
          
          if (newMessages.isNotEmpty) {
            // Sort by creation time
            newMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            
            bool hasNewIncomingMessages = false;
            for (var newMessage in newMessages) {
              _messages.add(newMessage);
              
              // Update last message time
              if (_lastMessageTime == null || newMessage.createdAt.isAfter(_lastMessageTime!)) {
                _lastMessageTime = newMessage.createdAt;
              }
              
              // Only emit to stream if it's not from current user (incoming message)
              if (!newMessage.isFromCurrentUser(_currentUserId)) {
                hasNewIncomingMessages = true;
                debugPrint('PollingChatService: ✨ New incoming message from ${newMessage.senderType}: "${newMessage.content}"');
                
                // Emit to stream for immediate UI updates
                if (!_messageStreamController.isClosed) {
                  _messageStreamController.add(newMessage);
                }
              }
            }
            
            // Re-sort all messages
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            notifyListeners();
            
            // Reset consecutive empty polls counter
            _consecutiveEmptyPolls = 0;
            
            // Increase polling frequency for active conversations
            if (hasNewIncomingMessages) {
              _adjustPollingFrequency(true);
            }
          } else {
            _consecutiveEmptyPolls++;
          }
        } else {
          _consecutiveEmptyPolls++;
        }
        
        // Gradually decrease polling frequency if no new messages
        _adjustPollingFrequencyForInactivity();
        
      } else if (response.statusCode == 404) {
        // No messages found, this is normal
        _consecutiveEmptyPolls++;
        _adjustPollingFrequencyForInactivity();
      } else {
        debugPrint('PollingChatService: ⚠️ Polling response ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('PollingChatService: ❌ Polling error: $e');
      // Don't stop polling on errors, just continue with next cycle
    }
  }

  void _adjustPollingFrequency(bool isActive) {
    if (isActive) {
      // Speed up polling during active conversations
      final oldInterval = _pollIntervalMs;
      _pollIntervalMs = 1500; // 1.5 seconds for active chats
      
      if (oldInterval != _pollIntervalMs) {
        debugPrint('PollingChatService: 📈 Increased polling frequency to ${_pollIntervalMs}ms');
        _restartPollingWithNewInterval();
      }
      
      // Reset to normal after 45 seconds of inactivity
      _frequencyResetTimer?.cancel();
      _frequencyResetTimer = Timer(const Duration(seconds: 45), () {
        if (!_isDisposed) {
          _pollIntervalMs = 3000; // Back to 3 seconds
          debugPrint('PollingChatService: 📉 Reset polling frequency to ${_pollIntervalMs}ms');
          _restartPollingWithNewInterval();
        }
      });
    }
  }

  void _adjustPollingFrequencyForInactivity() {
    // Gradually slow down polling if no new messages
    if (_consecutiveEmptyPolls >= 10) {
      final oldInterval = _pollIntervalMs;
      if (_pollIntervalMs == 1500) {
        _pollIntervalMs = 3000; // Slow to 3 seconds
      } else if (_pollIntervalMs == 3000 && _consecutiveEmptyPolls >= 20) {
        _pollIntervalMs = 5000; // Very slow after 20 empty polls
      }
      
      if (oldInterval != _pollIntervalMs) {
        debugPrint('PollingChatService: 🐌 Decreased polling frequency to ${_pollIntervalMs}ms (${_consecutiveEmptyPolls} empty polls)');
        _restartPollingWithNewInterval();
      }
    }
  }

  void _restartPollingWithNewInterval() {
    if (_isPolling && !_isDisposed) {
      stopPolling();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_isDisposed) {
          startPolling();
        }
      });
    }
  }

  Future<void> joinRoom(String roomId) async {
    if (_isDisposed) return;
    
    try {
      debugPrint('PollingChatService: 🏠 Joining room: $roomId');
      
      // Ensure we have current user ID
      if (_currentUserId == null) {
        _currentUserId = await TokenService.getUserId();
        debugPrint('PollingChatService: 🆔 Retrieved user ID: $_currentUserId');
      }
      
      // Stop any existing polling
      if (_currentRoomId != null) {
        leaveRoom(_currentRoomId!);
      }
      
      _currentRoomId = roomId;
      _lastMessageTime = null;
      _consecutiveEmptyPolls = 0;
      
      // Load initial chat history
      await loadChatHistory(roomId);
      
      // Start polling for new messages
      await startPolling();
      
      debugPrint('PollingChatService: ✅ Successfully joined room and started polling');
      
    } catch (e) {
      debugPrint('PollingChatService: ❌ Error joining room: $e');
    }
  }

  void leaveRoom(String roomId) {
    debugPrint('PollingChatService: 👋 Leaving room: $roomId');
    stopPolling();
    _currentRoomId = null;
    _lastMessageTime = null;
    _consecutiveEmptyPolls = 0;
  }

  Future<bool> sendMessage(String roomId, String content, {String messageType = 'text'}) async {
    if (_isDisposed) return false;
    
    try {
      final token = await TokenService.getToken();
      final userId = _currentUserId ?? await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('PollingChatService: ❌ No token or user ID found');
        return false;
      }

      final messageData = {
        'roomId': roomId,
        'senderId': userId,
        'senderType': 'partner',
        'content': content,
        'messageType': messageType,
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint('PollingChatService: 📤 Sending message: "$content"');
      debugPrint('PollingChatService: 🆔 Using sender ID: $userId');

      final url = Uri.parse('${ApiConstants.baseUrl}/chat/message');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(messageData),
      ).timeout(const Duration(seconds: 10));

      debugPrint('PollingChatService: 📨 Send response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          // Try to parse the response and add the sent message locally
          final responseData = jsonDecode(response.body);
          
          // Handle different response formats
          ApiChatMessage sentMessage;
          if (responseData is Map<String, dynamic>) {
            if (responseData.containsKey('data') && responseData['data'] != null) {
              sentMessage = ApiChatMessage.fromJson(responseData['data']);
            } else {
              sentMessage = ApiChatMessage.fromJson(responseData);
            }
          } else {
            // Create message from sent data if response parsing fails
            sentMessage = ApiChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              roomId: roomId,
              senderId: userId,
              senderType: 'partner',
              content: content,
              messageType: messageType,
              readBy: [],
              createdAt: DateTime.now(),
            );
          }
          
          // Add to local messages if not already present
          if (!_messages.any((msg) => msg.id == sentMessage.id)) {
            _messages.add(sentMessage);
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            
            // Update last message time
            if (_lastMessageTime == null || sentMessage.createdAt.isAfter(_lastMessageTime!)) {
              _lastMessageTime = sentMessage.createdAt;
            }
            
            notifyListeners();
          }
          
        } catch (parseError) {
          debugPrint('PollingChatService: ⚠️ Response parsing error: $parseError');
          // Still consider the send successful since we got 200/201
        }
        
        // Speed up polling temporarily after sending
        _adjustPollingFrequency(true);
        
        // Reset empty polls counter since we just sent a message
        _consecutiveEmptyPolls = 0;
        
        debugPrint('PollingChatService: ✅ Message sent successfully');
        return true;
      } else {
        debugPrint('PollingChatService: ❌ Send failed: ${response.statusCode} - ${response.body}');
        return false;
      }
      
    } catch (e) {
      debugPrint('PollingChatService: ❌ Error sending message: $e');
      return false;
    }
  }

  Future<void> loadChatHistory(String roomId) async {
    if (_isDisposed || _isLoadingHistory) return;
    
    _isLoadingHistory = true;
    
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        debugPrint('PollingChatService: ❌ No token found for loading chat history');
        return;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/chat/history/$roomId?limit=100');
      
      debugPrint('PollingChatService: 📚 Loading chat history from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('PollingChatService: 📊 Chat history response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> historyData = jsonDecode(response.body);
        
        _messages = historyData
            .map((messageJson) => ApiChatMessage.fromJson(messageJson))
            .toList();
        
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        // Set the last message time to the most recent message
        if (_messages.isNotEmpty) {
          _lastMessageTime = _messages.last.createdAt;
        }
        
        debugPrint('PollingChatService: ✅ Loaded ${_messages.length} messages from history');
        
        // Debug: Print all messages with sender comparison
        for (int i = 0; i < _messages.length; i++) {
          final msg = _messages[i];
          final isFromCurrentUser = msg.isFromCurrentUser(_currentUserId);
          debugPrint('PollingChatService: Message $i - "${msg.content}" - From current user: $isFromCurrentUser');
        }
        
        if (!_isDisposed) {
          notifyListeners();
        }
      } else if (response.statusCode == 404) {
        // No chat history exists yet, start with empty list
        _messages = [];
        _lastMessageTime = null;
        debugPrint('PollingChatService: 📝 No chat history found, starting fresh');
        if (!_isDisposed) {
          notifyListeners();
        }
      } else {
        debugPrint('PollingChatService: ❌ Failed to load chat history: ${response.statusCode}');
        throw Exception('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PollingChatService: ❌ Error loading chat history: $e');
      // Don't rethrow, just log the error
    } finally {
      _isLoadingHistory = false;
    }
  }

  // Typing indicators (mock implementation since polling doesn't support real-time)
  void sendTyping(String roomId) {
    // Could implement by sending a special API call if needed
    debugPrint('PollingChatService: ⌨️ Typing indicator sent (mock)');
  }

  void sendStopTyping(String roomId) {
    // Could implement by sending a special API call if needed
    debugPrint('PollingChatService: ⌨️ Stop typing indicator sent (mock)');
  }

  void clearMessages() {
    if (_isDisposed) return;
    
    _messages.clear();
    _lastMessageTime = null;
    _consecutiveEmptyPolls = 0;
    notifyListeners();
  }

  // Force refresh messages manually
  Future<void> refreshMessages() async {
    if (_currentRoomId != null) {
      debugPrint('PollingChatService: 🔄 Force refreshing messages...');
      await _pollForNewMessages();
    }
  }

  // Get polling status info for debugging
  Map<String, dynamic> getPollingInfo() {
    return {
      'isPolling': _isPolling,
      'currentRoomId': _currentRoomId,
      'currentUserId': _currentUserId,
      'pollIntervalMs': _pollIntervalMs,
      'consecutiveEmptyPolls': _consecutiveEmptyPolls,
      'messageCount': _messages.length,
      'lastMessageTime': _lastMessageTime?.toIso8601String(),
      'isLoadingHistory': _isLoadingHistory,
    };
  }

  @override
  void dispose() {
    debugPrint('PollingChatService: 🗑️ Disposing service');
    _isDisposed = true;
    stopPolling();
    _typingTimer?.cancel();
    _frequencyResetTimer?.cancel();
    _messageStreamController.close();
    super.dispose();
  }
}