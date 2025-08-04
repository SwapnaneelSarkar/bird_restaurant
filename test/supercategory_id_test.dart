import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bird_restaurant/services/token_service.dart';

void main() {
  group('Supercategory ID Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('should save and retrieve supercategory ID', () async {
      const testSupercategoryId = '7acc47a2fa5a4eeb906a753b3';
      
      // Save supercategory ID
      final saveResult = await TokenService.saveSupercategoryId(testSupercategoryId);
      expect(saveResult, isTrue);
      
      // Retrieve supercategory ID
      final retrievedId = await TokenService.getSupercategoryId();
      expect(retrievedId, equals(testSupercategoryId));
    });

    test('should handle empty supercategory ID', () async {
      // Try to save empty string
      final saveResult = await TokenService.saveSupercategoryId('');
      expect(saveResult, isFalse);
      
      // Should return null when no supercategory ID is saved
      final retrievedId = await TokenService.getSupercategoryId();
      expect(retrievedId, isNull);
    });

    test('should save supercategory ID with auth data', () async {
      const testToken = 'test_token_123';
      const testUserId = 'test_user_456';
      const testMobile = '1234567890';
      const testSupercategoryId = '7acc47a2fa5a4eeb906a753b3';
      
      // Save all auth data including supercategory ID
      final saveResult = await TokenService.saveAuthData(
        token: testToken,
        userId: testUserId,
        mobile: testMobile,
        supercategoryId: testSupercategoryId,
      );
      expect(saveResult, isTrue);
      
      // Verify supercategory ID was saved
      final retrievedId = await TokenService.getSupercategoryId();
      expect(retrievedId, equals(testSupercategoryId));
      
      // Verify other auth data was also saved
      final retrievedToken = await TokenService.getToken();
      final retrievedUserId = await TokenService.getUserId();
      final retrievedMobile = await TokenService.getMobile();
      
      expect(retrievedToken, equals(testToken));
      expect(retrievedUserId, equals(testUserId));
      expect(retrievedMobile, equals(testMobile));
    });

    test('should preserve supercategory ID during clearDataExceptEssentials', () async {
      const testSupercategoryId = '7acc47a2fa5a4eeb906a753b3';
      
      // Save supercategory ID
      await TokenService.saveSupercategoryId(testSupercategoryId);
      
      // Clear data except essentials
      await TokenService.clearDataExceptEssentials();
      
      // Verify supercategory ID is still there
      final retrievedId = await TokenService.getSupercategoryId();
      expect(retrievedId, equals(testSupercategoryId));
    });
  });
} 