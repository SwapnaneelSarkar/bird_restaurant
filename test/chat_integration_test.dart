import 'package:flutter_test/flutter_test.dart';
import 'package:bird_restaurant/presentation/screens/chat/state.dart';

void main() {
  group('Chat Integration Tests', () {
    test('should handle order details with datetime and user details together', () {
      // Sample order details API response
      final orderApiResponse = {
        "order_id": "89cd7b45b5bc41c08190f0048c526f56",
        "user_id": "0a3e5b1435d849a5b79b0c18",
        "total_price": "62049.00",
        "delivery_fees": "1.00",
        "order_status": "PREPARING",
        "datetime": "2025-07-15T20:31:12.000Z",
        "user_name": "mohit latest",
        "delivery_address": "Shamshabad, tesg 1",
        "payment_mode": "cash",
        "items": [
          {
            "menu_id": "M437bb9990b",
            "quantity": 1,
            "attributes": {
              "c26b24b4-f1b7-42e6-b43c-4555f5831ae6": "046fedf5-8b84-444f-af6f-8533f13bc678"
            },
            "item_price": 62049
          }
        ]
      };

      // Sample user details API response
      final userApiResponse = {
        "username": "mohit latest",
        "email": "swapnaneelsarkar571@gmail.com",
        "mobile": "8967853031",
        "image": null,
        "address": "this is my art",
        "latitude": "26.97224000",
        "longitude": "75.78029600",
        "user_id": "0a3e5b1435d849a5b79b0c18",
      };

      // Create OrderDetails from API response
      final orderDetails = OrderDetails.fromJson(orderApiResponse);
      
      // Create UserDetails from API response
      final userDetails = UserDetails.fromJson(userApiResponse);

      // Verify order details
      expect(orderDetails.orderId, equals('89cd7b45b5bc41c08190f0048c526f56'));
      expect(orderDetails.userId, equals('0a3e5b1435d849a5b79b0c18'));
      expect(orderDetails.orderStatus, equals('PREPARING'));
      expect(orderDetails.datetime, isNotNull);
      expect(orderDetails.items.length, equals(1));

      // Verify user details
      expect(userDetails.userId, equals('0a3e5b1435d849a5b79b0c18'));
      expect(userDetails.username, equals('mohit latest'));
      expect(userDetails.mobile, equals('8967853031'));
      expect(userDetails.email, equals('swapnaneelsarkar571@gmail.com'));

      // Verify that userId matches between order and user
      expect(orderDetails.userId, equals(userDetails.userId));

      // Verify formatted order time is not empty
      expect(orderDetails.formattedOrderTime, isNotEmpty);
      expect(orderDetails.formattedOrderTime, isA<String>());
    });

    test('should handle missing datetime in order details gracefully', () {
      // Order details without datetime
      final orderApiResponseWithoutDatetime = {
        "order_id": "89cd7b45b5bc41c08190f0048c526f56",
        "user_id": "0a3e5b1435d849a5b79b0c18",
        "total_price": "62049.00",
        "delivery_fees": "1.00",
        "order_status": "PREPARING",
        "user_name": "mohit latest",
        "delivery_address": "Shamshabad, tesg 1",
        "items": []
      };

      final orderDetails = OrderDetails.fromJson(orderApiResponseWithoutDatetime);

      // Verify datetime is null
      expect(orderDetails.datetime, isNull);
      
      // Verify formatted order time returns "Now"
      expect(orderDetails.formattedOrderTime, equals('Now'));
    });

    test('should handle missing mobile in user details gracefully', () {
      // User details without mobile
      final userApiResponseWithoutMobile = {
        "username": "mohit latest",
        "email": "swapnaneelsarkar571@gmail.com",
        "mobile": "", // Empty mobile
        "user_id": "0a3e5b1435d849a5b79b0c18",
      };

      final userDetails = UserDetails.fromJson(userApiResponseWithoutMobile);

      // Verify mobile is empty
      expect(userDetails.mobile, equals(''));
      
      // This would affect the UI - call button should not be shown
      expect(userDetails.mobile.isEmpty, isTrue);
    });

    test('should handle copyWith for both OrderDetails and UserDetails', () {
      // Create original objects
      final originalOrder = OrderDetails(
        orderId: "test_order",
        userId: "test_user",
        userName: "Test User",
        partnerId: "test_partner",
        itemIds: [],
        items: [],
        totalAmount: "100.00",
        deliveryFees: "10.00",
        orderStatus: "PREPARING",
        datetime: DateTime(2025, 7, 15, 20, 31, 12),
      );

      final originalUser = UserDetails(
        userId: "test_user",
        username: "Test User",
        email: "test@example.com",
        mobile: "1234567890",
      );

      // Test copyWith
      final updatedOrder = originalOrder.copyWith(
        orderStatus: "READY",
        datetime: DateTime(2025, 7, 16, 10, 30, 0),
      );

      final updatedUser = originalUser.copyWith(
        username: "Updated User",
        mobile: "9876543210",
      );

      // Verify order updates
      expect(updatedOrder.orderStatus, equals("READY"));
      expect(updatedOrder.datetime, isNot(equals(originalOrder.datetime)));
      expect(updatedOrder.orderId, equals(originalOrder.orderId)); // Unchanged

      // Verify user updates
      expect(updatedUser.username, equals("Updated User"));
      expect(updatedUser.mobile, equals("9876543210"));
      expect(updatedUser.userId, equals(originalUser.userId)); // Unchanged
    });
  });
} 