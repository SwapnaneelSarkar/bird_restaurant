// import 'dart:convert';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'token_service.dart';

class PartnerUpdateService {
  static Future<Map<String, dynamic>> updatePartnerDetails({
    String? restaurantName,
    String? address,
    double? latitude,
    double? longitude,
    String? email,
    String? phone,
    String? cuisineType,
    String? description,
    File? restaurantImage,
    // Add other fields as needed
  }) async {
    try {
      // Get token
      final token = await TokenService.getToken();
      
      if (token == null) {
        debugPrint('PartnerUpdateService: Token not found');
        return {
          'success': false,
          'message': 'Please login again'
        };
      }
      
      // Get partner ID if needed
      final partnerId = await TokenService.getUserId();
      debugPrint('PartnerUpdateService: Partner ID: $partnerId');
      
      // Create multipart request
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/updatePartner');
      
      debugPrint('PartnerUpdateService: Making request to: $url');
      
      var request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      // Add fields - only add non-null values
      if (restaurantName != null && restaurantName.isNotEmpty) {
        request.fields['restaurantName'] = restaurantName;
      }
      
      if (address != null && address.isNotEmpty) {
        request.fields['address'] = address;
      }
      
      // Add latitude and longitude - these are crucial
      if (latitude != null && !latitude.isNaN && !latitude.isInfinite) {
        request.fields['latitude'] = latitude.toString();
        debugPrint('PartnerUpdateService: Adding latitude: $latitude');
      }
      
      if (longitude != null && !longitude.isNaN && !longitude.isInfinite) {
        request.fields['longitude'] = longitude.toString();
        debugPrint('PartnerUpdateService: Adding longitude: $longitude');
      }
      
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }
      
      if (phone != null && phone.isNotEmpty) {
        request.fields['phone'] = phone;
      }
      
      if (cuisineType != null && cuisineType.isNotEmpty) {
        request.fields['cuisineType'] = cuisineType;
      }
      
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      
      // Add restaurant image if provided
      if (restaurantImage != null && await restaurantImage.exists()) {
        debugPrint('PartnerUpdateService: Adding restaurant image');
        var imageStream = http.ByteStream(restaurantImage.openRead());
        var imageLength = await restaurantImage.length();
        
        var multipartFile = http.MultipartFile(
          'restaurantImage',
          imageStream,
          imageLength,
          filename: 'restaurant_image${restaurantImage.path.substring(restaurantImage.path.lastIndexOf('.'))}',
        );
        
        request.files.add(multipartFile);
      }
      
      // Log the request fields and files
      debugPrint('PartnerUpdateService: Request fields: ${request.fields}');
      debugPrint('PartnerUpdateService: Request files: ${request.files.length}');
      
      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      // Log response
      debugPrint('PartnerUpdateService: Response status: ${response.statusCode}');
      debugPrint('PartnerUpdateService: Response body: ${response.body}');
      
      // Parse response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true || responseData['status'] == true) {
          debugPrint('PartnerUpdateService: Partner update successful');
          return {
            'success': true,
            'message': responseData['message'] ?? 'Partner details updated successfully',
            'data': responseData['data'],
          };
        } else {
          debugPrint('PartnerUpdateService: Partner update failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to update partner details',
          };
        }
      } else {
        debugPrint('PartnerUpdateService: HTTP error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('PartnerUpdateService: Exception: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }
  
  // Helper method to load saved restaurant details
  static Future<Map<String, dynamic>> getSavedRestaurantDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'restaurantName': prefs.getString('restaurant_name') ?? '',
        'address': prefs.getString('restaurant_address') ?? '',
        'phone': prefs.getString('restaurant_phone') ?? '',
        'email': prefs.getString('restaurant_email') ?? '',
        'latitude': prefs.getDouble('restaurant_latitude') ?? 0.0,
        'longitude': prefs.getDouble('restaurant_longitude') ?? 0.0,
        'cuisineType': prefs.getString('restaurant_cuisine_type') ?? '',
        'description': prefs.getString('restaurant_description') ?? '',
      };
    } catch (e) {
      debugPrint('PartnerUpdateService: Error getting saved restaurant details: $e');
      return {};
    }
  }
  
  // Helper method to clear saved restaurant details
  static Future<void> clearSavedRestaurantDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove('restaurant_name');
      await prefs.remove('restaurant_address');
      await prefs.remove('restaurant_phone');
      await prefs.remove('restaurant_email');
      await prefs.remove('restaurant_latitude');
      await prefs.remove('restaurant_longitude');
      await prefs.remove('restaurant_cuisine_type');
      await prefs.remove('restaurant_description');
      
      debugPrint('PartnerUpdateService: Cleared saved restaurant details');
    } catch (e) {
      debugPrint('PartnerUpdateService: Error clearing saved restaurant details: $e');
    }
  }
}