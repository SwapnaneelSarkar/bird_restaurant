import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bird_restaurant/services/token_service.dart';

void main() {
  group('Category Fetching Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('should build correct URL with supercategory parameter', () async {
      const testSupercategoryId = '7acc47a2fa5a4eeb906a753b3';
      
      // Save supercategory ID
      await TokenService.saveSupercategoryId(testSupercategoryId);
      
      // Simulate the URL building logic from the blocs
      final selectedSupercategoryId = await TokenService.getSupercategoryId();
      
      String urlString = 'https://api.bird.delivery/api/partner/categories';
      if (selectedSupercategoryId != null && selectedSupercategoryId.isNotEmpty) {
        urlString += '?supercategory=$selectedSupercategoryId';
      }
      
      expect(urlString, equals('https://api.bird.delivery/api/partner/categories?supercategory=$testSupercategoryId'));
    });

    test('should build URL without supercategory parameter when not available', () async {
      // Don't save any supercategory ID
      
      // Simulate the URL building logic from the blocs
      final selectedSupercategoryId = await TokenService.getSupercategoryId();
      
      String urlString = 'https://api.bird.delivery/api/partner/categories';
      if (selectedSupercategoryId != null && selectedSupercategoryId.isNotEmpty) {
        urlString += '?supercategory=$selectedSupercategoryId';
      }
      
      expect(urlString, equals('https://api.bird.delivery/api/partner/categories'));
    });

    test('should handle empty supercategory ID gracefully', () async {
      // Save empty supercategory ID
      await TokenService.saveSupercategoryId('');
      
      // Simulate the URL building logic from the blocs
      final selectedSupercategoryId = await TokenService.getSupercategoryId();
      
      String urlString = 'https://api.bird.delivery/api/partner/categories';
      if (selectedSupercategoryId != null && selectedSupercategoryId.isNotEmpty) {
        urlString += '?supercategory=$selectedSupercategoryId';
      }
      
      expect(urlString, equals('https://api.bird.delivery/api/partner/categories'));
    });
  });
} 