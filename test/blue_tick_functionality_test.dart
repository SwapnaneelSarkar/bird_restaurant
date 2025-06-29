import 'package:flutter_test/flutter_test.dart';
import 'package:bird_restaurant/services/chat_services.dart';

void main() {
  group('Blue Tick Functionality Tests', () {
    test('ApiChatMessage should correctly identify read status', () {
      // Create a message that is read by someone other than sender
      final readByEntry = ReadByEntry(
        userId: 'other_user_id',
        readAt: DateTime.now(),
        id: 'read_entry_id',
      );
      
      final message = ApiChatMessage(
        id: 'message_id',
        roomId: 'room_id',
        senderId: 'sender_id',
        senderType: 'partner',
        content: 'Test message',
        messageType: 'text',
        readBy: [readByEntry],
        createdAt: DateTime.now(),
      );
      
      // Test that message is marked as read
      expect(message.isRead, true);
      expect(message.isReadByUser('other_user_id'), true);
      expect(message.isReadByUser('sender_id'), false);
    });

    test('ApiChatMessage should correctly identify unread status', () {
      // Create a message that is not read by anyone
      final message = ApiChatMessage(
        id: 'message_id',
        roomId: 'room_id',
        senderId: 'sender_id',
        senderType: 'partner',
        content: 'Test message',
        messageType: 'text',
        readBy: [],
        createdAt: DateTime.now(),
      );
      
      // Test that message is marked as unread
      expect(message.isRead, false);
      expect(message.isReadByUser('other_user_id'), false);
    });

    test('ApiChatMessage should handle sender reading their own message', () {
      // Create a message that is read by the sender (should not count as "read" for blue tick)
      final readByEntry = ReadByEntry(
        userId: 'sender_id', // Same as sender
        readAt: DateTime.now(),
        id: 'read_entry_id',
      );
      
      final message = ApiChatMessage(
        id: 'message_id',
        roomId: 'room_id',
        senderId: 'sender_id',
        senderType: 'partner',
        content: 'Test message',
        messageType: 'text',
        readBy: [readByEntry],
        createdAt: DateTime.now(),
      );
      
      // Test that message is NOT marked as read (sender reading their own message doesn't count)
      expect(message.isRead, false);
      expect(message.isReadByUser('sender_id'), true);
    });

    test('ApiChatMessage should handle multiple readers', () {
      // Create a message that is read by multiple users
      final readByEntry1 = ReadByEntry(
        userId: 'user1',
        readAt: DateTime.now(),
        id: 'read_entry_1',
      );
      
      final readByEntry2 = ReadByEntry(
        userId: 'user2',
        readAt: DateTime.now(),
        id: 'read_entry_2',
      );
      
      final message = ApiChatMessage(
        id: 'message_id',
        roomId: 'room_id',
        senderId: 'sender_id',
        senderType: 'partner',
        content: 'Test message',
        messageType: 'text',
        readBy: [readByEntry1, readByEntry2],
        createdAt: DateTime.now(),
      );
      
      // Test that message is marked as read
      expect(message.isRead, true);
      expect(message.isReadByUser('user1'), true);
      expect(message.isReadByUser('user2'), true);
      expect(message.isReadByUser('sender_id'), false);
    });

    test('ReadByEntry should correctly parse from JSON', () {
      final json = {
        'userId': 'test_user_id',
        'readAt': '2024-01-01T12:00:00.000Z',
        '_id': 'read_entry_id',
      };
      
      final readByEntry = ReadByEntry.fromJson(json);
      
      expect(readByEntry.userId, 'test_user_id');
      expect(readByEntry.id, 'read_entry_id');
      expect(readByEntry.readAt, DateTime.parse('2024-01-01T12:00:00.000Z'));
    });

    test('ApiChatMessage should correctly parse from JSON with readBy', () {
      final json = {
        '_id': 'message_id',
        'roomId': 'room_id',
        'senderId': 'sender_id',
        'senderType': 'partner',
        'content': 'Test message',
        'messageType': 'text',
        'readBy': [
          {
            'userId': 'reader_id',
            'readAt': '2024-01-01T12:00:00.000Z',
            '_id': 'read_entry_id',
          }
        ],
        'createdAt': '2024-01-01T12:00:00.000Z',
      };
      
      final message = ApiChatMessage.fromJson(json);
      
      expect(message.id, 'message_id');
      expect(message.content, 'Test message');
      expect(message.readBy.length, 1);
      expect(message.readBy.first.userId, 'reader_id');
      expect(message.isRead, true);
    });
  });
} 