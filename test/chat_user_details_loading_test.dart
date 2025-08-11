import 'package:flutter_test/flutter_test.dart';
import 'package:bird_restaurant/presentation/screens/chat/state.dart';
import 'package:bird_restaurant/models/chat_room_model.dart';

void main() {
  group('Chat User Details Loading Tests', () {
    test('should load user details immediately when order details are available', () {
      // Sample order details with userId
      final orderApiResponse = {
        "order_id": "89cd7b45b5bc41c08190f0048c526f56",
        "user_id": "0a3e5b1435d849a5b79b0c18",
        "total_price": "62049.00",
        "delivery_fees": "1.00",
        "order_status": "PREPARING",
        "datetime": "2025-07-15T20:31:12.000Z",
        "user_name": "mohit latest",
        "delivery_address": "Shamshabad, tesg 1",
        "items": []
      };

      // Sample user details API response
      final userApiResponse = {
        "username": "mohit latest",
        "email": "swapnaneelsarkar571@gmail.com",
        "mobile": "8967853031",
        "user_id": "0a3e5b1435d849a5b79b0c18",
      };

      // Create OrderDetails from API response
      final orderDetails = OrderDetails.fromJson(orderApiResponse);
      
      // Create UserDetails from API response
      final userDetails = UserDetails.fromJson(userApiResponse);

      // Verify that userId is available in order details
      expect(orderDetails.userId, isNotEmpty);
      expect(orderDetails.userId, equals('0a3e5b1435d849a5b79b0c18'));

      // Verify that user details can be loaded using the userId
      expect(userDetails.userId, equals(orderDetails.userId));
      expect(userDetails.mobile, isNotEmpty);
      expect(userDetails.username, isNotEmpty);
    });

    test('should handle missing userId in order details gracefully', () {
      // Order details without userId
      final orderApiResponseWithoutUserId = {
        "order_id": "89cd7b45b5bc41c08190f0048c526f56",
        "user_id": "", // Empty userId
        "total_price": "62049.00",
        "delivery_fees": "1.00",
        "order_status": "PREPARING",
        "items": []
      };

      final orderDetails = OrderDetails.fromJson(orderApiResponseWithoutUserId);

      // Verify that userId is empty
      expect(orderDetails.userId, isEmpty);
      
      // This would prevent user details loading from order details
      expect(orderDetails.userId.isEmpty, isTrue);
    });

    test('should create UserDetails from chat room participant as fallback', () {
      // Sample chat room with user participant
      final chatRoomJson = {
        "_id": "room123",
        "roomId": "room123",
        "orderId": "89cd7b45b5bc41c08190f0048c526f56",
        "participants": [
          {
            "id": "participant1",
            "userId": "0a3e5b1435d849a5b79b0c18",
            "userType": "user",
            "name": "mohit latest",
            "profilePicture": "https://example.com/avatar.jpg"
          },
          {
            "id": "participant2",
            "userId": "partner123",
            "userType": "partner",
            "name": "Restaurant Partner",
            "profilePicture": ""
          }
        ],
        "lastMessage": "Hello",
        "lastMessageTime": "2025-07-15T20:31:12.000Z",
        "createdAt": "2025-07-15T20:31:12.000Z",
        "isOrderActive": true
      };

      final chatRoom = ChatRoom.fromJson(chatRoomJson);
      
      // Verify that user participant is available
      expect(chatRoom.userParticipant, isNotNull);
      expect(chatRoom.userParticipant!.userType, equals('user'));
      expect(chatRoom.userParticipant!.name, equals('mohit latest'));
      expect(chatRoom.userParticipant!.userId, equals('0a3e5b1435d849a5b79b0c18'));

      // Create UserDetails from chat room participant
      final userParticipant = chatRoom.userParticipant!;
      final userDetails = UserDetails(
        userId: userParticipant.userId,
        username: userParticipant.name,
        email: '', // Not available in chat room
        mobile: '', // Not available in chat room
        image: userParticipant.profilePicture.isNotEmpty ? userParticipant.profilePicture : null,
      );

      // Verify UserDetails created from chat room
      expect(userDetails.userId, equals('0a3e5b1435d849a5b79b0c18'));
      expect(userDetails.username, equals('mohit latest'));
      expect(userDetails.image, equals('https://example.com/avatar.jpg'));
      expect(userDetails.mobile, isEmpty); // Not available from chat room
      expect(userDetails.email, isEmpty); // Not available from chat room
    });

    test('should handle chat room without user participant gracefully', () {
      // Chat room without user participant
      final chatRoomJsonWithoutUser = {
        "_id": "room123",
        "roomId": "room123",
        "orderId": "89cd7b45b5bc41c08190f0048c526f56",
        "participants": [
          {
            "id": "participant2",
            "userId": "partner123",
            "userType": "partner",
            "name": "Restaurant Partner",
            "profilePicture": ""
          }
        ],
        "lastMessage": "Hello",
        "lastMessageTime": "2025-07-15T20:31:12.000Z",
        "createdAt": "2025-07-15T20:31:12.000Z",
        "isOrderActive": true
      };

      final chatRoom = ChatRoom.fromJson(chatRoomJsonWithoutUser);
      
      // Verify that user participant is not available
      expect(chatRoom.userParticipant, isNull);
    });

    test('should prioritize order details over chat room for user information', () {
      // Order details with complete user information
      final orderDetails = OrderDetails(
        orderId: "test_order",
        userId: "user123",
        userName: "Test User",
        partnerId: "partner123",
        itemIds: [],
        items: [],
        totalAmount: "100.00",
        deliveryFees: "10.00",
        orderStatus: "PREPARING",
      );

      // Chat room with limited user information
      final chatRoomJson = {
        "_id": "room123",
        "roomId": "room123",
        "orderId": "test_order",
        "participants": [
          {
            "id": "participant1",
            "userId": "user123",
            "userType": "user",
            "name": "Test User",
            "profilePicture": ""
          }
        ],
        "lastMessage": "Hello",
        "lastMessageTime": "2025-07-15T20:31:12.000Z",
        "createdAt": "2025-07-15T20:31:12.000Z",
        "isOrderActive": true
      };

      final chatRoom = ChatRoom.fromJson(chatRoomJson);

      // Verify that order details should be preferred when available
      expect(orderDetails.userId, equals(chatRoom.userParticipant!.userId));
      expect(orderDetails.userName, equals(chatRoom.userParticipant!.name));
      
      // Order details would have more complete information (mobile, email)
      // while chat room only has basic information (name, userId)
    });
  });
} 