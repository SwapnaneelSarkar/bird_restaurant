import 'package:flutter_test/flutter_test.dart';
import 'package:bird_restaurant/presentation/screens/chat/state.dart';
import 'package:bird_restaurant/utils/time_utils.dart';

void main() {
  group('OrderDetails datetime field tests', () {
    test('should parse datetime from API response correctly', () {
      // Sample API response as provided by user
      final apiResponse = {
        "status": "SUCCESS",
        "message": "Order details fetched successfully",
        "data": {
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
        }
      };

      // Create OrderDetails from the API response
      final orderDetails = OrderDetails.fromJson(apiResponse['data'] as Map<String, dynamic>);

      // Verify that datetime is parsed correctly
      expect(orderDetails.datetime, isNotNull);
      expect(orderDetails.datetime, isA<DateTime>());
      
      // Verify the datetime value (converted to IST)
      final expectedDateTime = TimeUtils.parseToIST("2025-07-15T20:31:12.000Z");
      expect(orderDetails.datetime, equals(expectedDateTime));
    });

    test('should handle missing datetime field gracefully', () {
      // API response without datetime field
      final apiResponseWithoutDatetime = {
        "order_id": "89cd7b45b5bc41c08190f0048c526f56",
        "user_id": "0a3e5b1435d849a5b79b0c18",
        "total_price": "62049.00",
        "delivery_fees": "1.00",
        "order_status": "PREPARING",
        "user_name": "mohit latest",
        "delivery_address": "Shamshabad, tesg 1",
        "items": []
      };

      final orderDetails = OrderDetails.fromJson(apiResponseWithoutDatetime);

      // Verify that datetime is null when not provided
      expect(orderDetails.datetime, isNull);
    });

    test('should format order time correctly for display', () {
      // Create OrderDetails with a specific datetime
      final testDateTime = DateTime(2025, 7, 15, 20, 31, 12); // 8:31 PM
      final orderDetails = OrderDetails(
        orderId: "test_order",
        userId: "test_user",
        userName: "Test User",
        partnerId: "test_partner",
        itemIds: [],
        items: [],
        totalAmount: "100.00",
        deliveryFees: "10.00",
        orderStatus: "PREPARING",
        datetime: testDateTime,
      );

      // Test the formatted order time
      final formattedTime = orderDetails.formattedOrderTime;
      expect(formattedTime, isNotEmpty);
      expect(formattedTime, isA<String>());
      
      // The exact format depends on the current date relative to the test date
      // but it should contain time information
      expect(formattedTime.contains(':'), isTrue);
    });

    test('should return "Now" when datetime is null', () {
      final orderDetails = OrderDetails(
        orderId: "test_order",
        userId: "test_user",
        userName: "Test User",
        partnerId: "test_partner",
        itemIds: [],
        items: [],
        totalAmount: "100.00",
        deliveryFees: "10.00",
        orderStatus: "PREPARING",
        datetime: null,
      );

      expect(orderDetails.formattedOrderTime, equals('Now'));
    });

    test('should handle copyWith with datetime field', () {
      final originalDateTime = DateTime(2025, 7, 15, 20, 31, 12);
      final newDateTime = DateTime(2025, 7, 16, 10, 30, 0);
      
      final orderDetails = OrderDetails(
        orderId: "test_order",
        userId: "test_user",
        userName: "Test User",
        partnerId: "test_partner",
        itemIds: [],
        items: [],
        totalAmount: "100.00",
        deliveryFees: "10.00",
        orderStatus: "PREPARING",
        datetime: originalDateTime,
      );

      final updatedOrderDetails = orderDetails.copyWith(datetime: newDateTime);

      expect(updatedOrderDetails.datetime, equals(newDateTime));
      expect(updatedOrderDetails.orderId, equals(orderDetails.orderId)); // Other fields unchanged
    });
  });
} 