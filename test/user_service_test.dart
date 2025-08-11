import 'package:flutter_test/flutter_test.dart';
import 'package:bird_restaurant/services/user_service.dart';
import 'package:bird_restaurant/presentation/screens/chat/state.dart';

void main() {
  group('UserService tests', () {
    test('should parse user details from API response correctly', () {
      // Sample API response as provided by user
      final apiResponse = {
        "status": true,
        "message": "User fetched successfully",
        "data": {
          "username": "mohit latest",
          "password": "\$2b\$10\$88OLGdPMsD52ne/f9/uif.XTDN3ZJhVHQMGKSfBf7V3FZiqWYG2SO",
          "email": "swapnaneelsarkar571@gmail.com",
          "mobile": "8967853031",
          "image": null,
          "last_login": null,
          "address": "this is my art",
          "latitude": "26.97224000",
          "longitude": "75.78029600",
          "created_at": "2025-05-19T06:00:20.000Z",
          "user_id": "0a3e5b1435d849a5b79b0c18",
          "updated_at": "2025-08-02T15:23:14.000Z",
          "firebase_token": "c_sZG8rmQNKVtYxszrMFic:APA91bErnjbRUnegzkbOEyCEcRbL2tYtG9GbbeA7nTaK4893XEYQslPNQa786O6tcKKv7V_cLPKtOc_KTCqGEjrqi7eUoFQiYiJ42ymTVjxfd3oPyxpRXXI",
          "email_verified": 1,
          "email_verification_sent_at": "2025-07-31T01:57:10.000Z"
        }
      };

      // Create UserDetails from the API response
      final userDetails = UserDetails.fromJson(apiResponse['data'] as Map<String, dynamic>);

      // Verify that all fields are parsed correctly
      expect(userDetails.userId, equals('0a3e5b1435d849a5b79b0c18'));
      expect(userDetails.username, equals('mohit latest'));
      expect(userDetails.email, equals('swapnaneelsarkar571@gmail.com'));
      expect(userDetails.mobile, equals('8967853031'));
      expect(userDetails.address, equals('this is my art'));
      expect(userDetails.latitude, equals('26.97224000'));
      expect(userDetails.longitude, equals('75.78029600'));
      expect(userDetails.image, isNull);
    });

    test('should handle missing optional fields gracefully', () {
      // API response with missing optional fields
      final apiResponseWithMissingFields = {
        "user_id": "0a3e5b1435d849a5b79b0c18",
        "username": "mohit latest",
        "email": "swapnaneelsarkar571@gmail.com",
        "mobile": "8967853031",
        // Missing: image, address, latitude, longitude
      };

      final userDetails = UserDetails.fromJson(apiResponseWithMissingFields);

      // Verify required fields are present
      expect(userDetails.userId, equals('0a3e5b1435d849a5b79b0c18'));
      expect(userDetails.username, equals('mohit latest'));
      expect(userDetails.email, equals('swapnaneelsarkar571@gmail.com'));
      expect(userDetails.mobile, equals('8967853031'));

      // Verify optional fields are null
      expect(userDetails.image, isNull);
      expect(userDetails.address, isNull);
      expect(userDetails.latitude, isNull);
      expect(userDetails.longitude, isNull);
    });

    test('should handle copyWith method correctly', () {
      final originalUser = UserDetails(
        userId: "0a3e5b1435d849a5b79b0c18",
        username: "mohit latest",
        email: "swapnaneelsarkar571@gmail.com",
        mobile: "8967853031",
        address: "this is my art",
      );

      final updatedUser = originalUser.copyWith(
        username: "mohit updated",
        mobile: "9876543210",
      );

      // Verify updated fields
      expect(updatedUser.username, equals("mohit updated"));
      expect(updatedUser.mobile, equals("9876543210"));

      // Verify unchanged fields
      expect(updatedUser.userId, equals(originalUser.userId));
      expect(updatedUser.email, equals(originalUser.email));
      expect(updatedUser.address, equals(originalUser.address));
    });

    test('should handle empty or null values in API response', () {
      final apiResponseWithEmptyValues = {
        "user_id": "",
        "username": "",
        "email": "",
        "mobile": "",
        "image": null,
        "address": null,
        "latitude": null,
        "longitude": null,
      };

      final userDetails = UserDetails.fromJson(apiResponseWithEmptyValues);

      // Verify empty strings are handled
      expect(userDetails.userId, equals(''));
      expect(userDetails.username, equals(''));
      expect(userDetails.email, equals(''));
      expect(userDetails.mobile, equals(''));

      // Verify null values are handled
      expect(userDetails.image, isNull);
      expect(userDetails.address, isNull);
      expect(userDetails.latitude, isNull);
      expect(userDetails.longitude, isNull);
    });
  });
} 