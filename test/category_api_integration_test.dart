import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bird_restaurant/services/token_service.dart';
import 'package:bird_restaurant/constants/api_constants.dart';

void main() {
  group('Category API Integration Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('should build correct API URL with supercategory parameter', () async {
      const testSupercategoryId = '7acc47a2fa5a4eeb906a753b3';
      
      // Save supercategory ID
      await TokenService.saveSupercategoryId(testSupercategoryId);
      
      // Simulate the URL building logic from the blocs
      final selectedSupercategoryId = await TokenService.getSupercategoryId();
      
      String urlString = '${ApiConstants.baseUrl}/partner/categories';
      if (selectedSupercategoryId != null && selectedSupercategoryId.isNotEmpty) {
        urlString += '?supercategory=$selectedSupercategoryId';
      }
      
      expect(urlString, equals('${ApiConstants.baseUrl}/partner/categories?supercategory=$testSupercategoryId'));
    });

    test('should build URL without supercategory parameter when not available', () async {
      // Don't save any supercategory ID
      
      // Simulate the URL building logic from the blocs
      final selectedSupercategoryId = await TokenService.getSupercategoryId();
      
      String urlString = '${ApiConstants.baseUrl}/partner/categories';
      if (selectedSupercategoryId != null && selectedSupercategoryId.isNotEmpty) {
        urlString += '?supercategory=$selectedSupercategoryId';
      }
      
      expect(urlString, equals('${ApiConstants.baseUrl}/partner/categories'));
    });

    test('should handle empty supercategory ID gracefully', () async {
      // Save empty supercategory ID
      await TokenService.saveSupercategoryId('');
      
      // Simulate the URL building logic from the blocs
      final selectedSupercategoryId = await TokenService.getSupercategoryId();
      
      String urlString = '${ApiConstants.baseUrl}/partner/categories';
      if (selectedSupercategoryId != null && selectedSupercategoryId.isNotEmpty) {
        urlString += '?supercategory=$selectedSupercategoryId';
      }
      
      expect(urlString, equals('${ApiConstants.baseUrl}/partner/categories'));
    });

    test('should handle null supercategory ID gracefully', () async {
      // Don't save any supercategory ID (will return null)
      
      // Simulate the URL building logic from the blocs
      final selectedSupercategoryId = await TokenService.getSupercategoryId();
      
      String urlString = '${ApiConstants.baseUrl}/partner/categories';
      if (selectedSupercategoryId != null && selectedSupercategoryId.isNotEmpty) {
        urlString += '?supercategory=$selectedSupercategoryId';
      }
      
      expect(urlString, equals('${ApiConstants.baseUrl}/partner/categories'));
    });

    test('should verify supercategory ID persistence across app sessions', () async {
      const testSupercategoryId = '7acc47a2fa5a4eeb906a753b3';
      
      // Save supercategory ID
      await TokenService.saveSupercategoryId(testSupercategoryId);
      
      // Verify it's saved
      final savedId = await TokenService.getSupercategoryId();
      expect(savedId, equals(testSupercategoryId));
      
      // Simulate app restart by clearing and reinitializing SharedPreferences
      SharedPreferences.setMockInitialValues({
        'supercategory_id': testSupercategoryId,
      });
      
      // Verify it's still available after "restart"
      final restartedId = await TokenService.getSupercategoryId();
      expect(restartedId, equals(testSupercategoryId));
    });

    test('should verify URL format matches expected API specification', () async {
      const testSupercategoryId = '7acc47a2fa5a4eeb906a753b3';
      
      // Save supercategory ID
      await TokenService.saveSupercategoryId(testSupercategoryId);
      
      // Build URL as done in the blocs
      final selectedSupercategoryId = await TokenService.getSupercategoryId();
      
      String urlString = '${ApiConstants.baseUrl}/partner/categories';
      if (selectedSupercategoryId != null && selectedSupercategoryId.isNotEmpty) {
        urlString += '?supercategory=$selectedSupercategoryId';
      }
      
      // Verify the URL format matches the expected specification
      expect(urlString, matches(RegExp(r'^https://.*/partner/categories\?supercategory=[a-zA-Z0-9]+$')));
      
      // Verify the supercategory ID is correctly appended
      expect(urlString, contains('supercategory=$testSupercategoryId'));
    });
  });
} 