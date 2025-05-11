import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../constants/api_constants.dart';
import 'api_responses.dart';
import 'api_exception.dart';
import 'token_service.dart';

class ApiServices {
  late final http.Client _client;

  ApiServices({http.Client? client}) {
    if (client != null) {
      _client = client;
    } else {
      // Create a client that bypasses SSL verification for development
      _client = _createHttpClient();
    }
  }
  
  // Create HTTP client that bypasses SSL verification (for development only)
  http.Client _createHttpClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Accept all certificates in development mode
        debugPrint('Accepting certificate for host: $host');
        return true;
      }
      ..connectionTimeout = const Duration(seconds: 30);
    
    return IOClient(httpClient);
  }

  // Update Partner method that includes latitude and longitude
  Future<ApiResponse> updatePartner({
    required String restaurantName,
    required String address,
    required String email,
    required String category,
    required String operationalHours,
    double? latitude,
    double? longitude,
    File? fssaiLicense,
    File? gstCertificate,
    File? panCard,
    List<File>? restaurantPhotos,
  }) async {
    try {
      // Get token and user ID directly from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final partnerId = prefs.getString('user_id');
      
      if (token == null || partnerId == null) {
        throw UnauthorizedException('No token or user ID found. Please login again.');
      }

      debugPrint('Token: $token');
      debugPrint('Partner ID: $partnerId');

      final url = Uri.parse('${ApiConstants.baseUrl}/partner/updatePartner');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      // Add text fields
      request.fields['partnerId'] = partnerId.toString();
      request.fields['restaurant_name'] = restaurantName;
      request.fields['address'] = address;
      request.fields['email'] = email;
      request.fields['category'] = category;
      request.fields['operational_hours'] = operationalHours;
      
      // Add latitude and longitude if available
      if (latitude != null && !latitude.isNaN && !latitude.isInfinite) {
        request.fields['latitude'] = latitude.toString();
        debugPrint('Adding latitude to API request: $latitude');
      }
      
      if (longitude != null && !longitude.isNaN && !longitude.isInfinite) {
        request.fields['longitude'] = longitude.toString();
        debugPrint('Adding longitude to API request: $longitude');
      }
      
      // Add files if they exist
      if (fssaiLicense != null) {
        request.files.add(await _createMultipartFile(
          'fssai_license_doc',
          fssaiLicense,
        ));
      }
      
      if (gstCertificate != null) {
        request.files.add(await _createMultipartFile(
          'gst_certificate_doc',
          gstCertificate,
        ));
      }
      
      if (panCard != null) {
        request.files.add(await _createMultipartFile(
          'pan_card_doc',
          panCard,
        ));
      }
      
      if (restaurantPhotos != null && restaurantPhotos.isNotEmpty) {
        for (var i = 0; i < restaurantPhotos.length; i++) {
          request.files.add(await _createMultipartFile(
            'restaurant_photos',
            restaurantPhotos[i],
          ));
        }
      }
      
      // Debug print request
      debugPrint('Update Partner Request:');
      debugPrint('URL: $url');
      debugPrint('Headers: ${request.headers}');
      debugPrint('Fields: ${request.fields}');
      debugPrint('Files: ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}');
      
      // Send request using the client that bypasses SSL verification
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      // Debug print response
      debugPrint('Update Partner Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      
      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 413) {
        throw ApiException('The total size of files is too large. Please compress your images or reduce the number of files.');
      }

      // Update the error handling for HTML responses:
      if (response.body.trim().startsWith('<') || 
          response.body.contains('<!DOCTYPE') || 
          response.body.contains('<html')) {
        if (response.statusCode == 413) {
          throw ApiException('Request too large. Please reduce the file sizes.');
        }
        throw ApiException('Server returned HTML instead of JSON. Status: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        final status = responseBody['status'];
        final message = responseBody['message'] ?? '';
        final data = responseBody['data'];
        
        return ApiResponse(
          success: status == 'SUCCESS',
          data: data,
          message: message,
          status: status,
        );
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        return ApiResponse(
          success: false,
          message: responseBody['message'] ?? 'Update failed',
          status: responseBody['status'] ?? 'ERROR',
        );
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      debugPrint('Error updating partner: $e');
      throw ApiException('Failed to update partner: $e');
    }
  }

  // Comprehensive updatePartnerWithAllFields method that includes all possible fields
  Future<ApiResponse> updatePartnerWithAllFields({
    required String restaurantName,
    required String address,
    required String email,
    required String category,
    required String operationalHours,
    required String ownerName,
    required String latitude,
    required String longitude,
    required String vegNonveg,
    required String cookingTime,
    File? fssaiLicense,
    File? gstCertificate,
    File? panCard,
    List<File>? restaurantPhotos,
  }) async {
    try {
      final token = await TokenService.getToken();
      final partnerId = await TokenService.getUserId();
      
      if (token == null || partnerId == null) {
        throw UnauthorizedException('No token or user ID found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/partner/updatePartner');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      // Add all form fields as shown in the screenshot
      request.fields['partnerId'] = partnerId.toString();
      request.fields['restaurant_name'] = restaurantName;
      request.fields['address'] = address;
      request.fields['email'] = email;
      request.fields['category'] = category;
      request.fields['operational_hours'] = operationalHours;
      request.fields['owner_name'] = ownerName;
      
      // Ensure coordinates are included
      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;
      debugPrint('Adding coordinates to API request - Latitude: $latitude, Longitude: $longitude');
      
      request.fields['veg-nonveg'] = vegNonveg;
      request.fields['cooking_time'] = cookingTime;
      
      // Add files if they exist
      if (fssaiLicense != null) {
        request.files.add(await _createMultipartFile(
          'fssai_license_doc',
          fssaiLicense,
        ));
      }
      
      if (gstCertificate != null) {
        request.files.add(await _createMultipartFile(
          'gst_certificate_doc',
          gstCertificate,
        ));
      }
      
      if (panCard != null) {
        request.files.add(await _createMultipartFile(
          'pan_card_doc',
          panCard,
        ));
      }
      
      if (restaurantPhotos != null && restaurantPhotos.isNotEmpty) {
        for (var i = 0; i < restaurantPhotos.length; i++) {
          request.files.add(await _createMultipartFile(
            'restaurant_photos',
            restaurantPhotos[i],
          ));
        }
      }
      
      // Debug print request
      debugPrint('Update Partner With All Fields Request:');
      debugPrint('URL: $url');
      debugPrint('Headers: ${request.headers}');
      debugPrint('Fields: ${request.fields}');
      debugPrint('Files: ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}');
      
      // Send request using the client that bypasses SSL verification
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      // Debug print response
      debugPrint('Update Partner Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      
      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 413) {
        throw ApiException('The total size of files is too large. Please compress your images or reduce the number of files.');
      }

      // Update the error handling for HTML responses:
      if (response.body.trim().startsWith('<') || 
          response.body.contains('<!DOCTYPE') || 
          response.body.contains('<html')) {
        if (response.statusCode == 413) {
          throw ApiException('Request too large. Please reduce the file sizes.');
        }
        throw ApiException('Server returned HTML instead of JSON. Status: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        final status = responseBody['status'];
        final message = responseBody['message'] ?? '';
        final data = responseBody['data'];
        
        return ApiResponse(
          success: status == 'SUCCESS',
          data: data,
          message: message,
          status: status,
        );
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        return ApiResponse(
          success: false,
          message: responseBody['message'] ?? 'Update failed',
          status: responseBody['status'] ?? 'ERROR',
        );
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      debugPrint('Error updating partner: $e');
      throw ApiException('Failed to update partner: $e');
    }
  }

  // Helper method to create multipart file with proper content type
  Future<http.MultipartFile> _createMultipartFile(String field, File file) async {
    String? mimeType = lookupMimeType(file.path);
    MediaType? contentType;
    
    if (mimeType != null) {
      var mimeTypeData = mimeType.split('/');
      if (mimeTypeData.length == 2) {
        contentType = MediaType(mimeTypeData[0], mimeTypeData[1]);
      }
    }
    
    // If MIME type couldn't be determined, use a default based on extension
    if (contentType == null) {
      String ext = path.extension(file.path).toLowerCase();
      switch (ext) {
        case '.pdf':
          contentType = MediaType('application', 'pdf');
          break;
        case '.doc':
          contentType = MediaType('application', 'msword');
          break;
        case '.docx':
          contentType = MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
          break;
        case '.png':
          contentType = MediaType('image', 'png');
          break;
        case '.jpg':
        case '.jpeg':
          contentType = MediaType('image', 'jpeg');
          break;
        default:
          contentType = MediaType('application', 'octet-stream');
      }
    }
    
    return await http.MultipartFile.fromPath(
      field,
      file.path,
      contentType: contentType,
      filename: path.basename(file.path),
    );
  }

  static Future<void> clearSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // First, save the essential values we want to keep
      final token = prefs.getString('token');
      final userId = prefs.getString('user_id');
      final mobile = prefs.getString('mobile');
      
      debugPrint('Preserving auth data during clearSavedData:');
      debugPrint('- Token: ${token != null ? 'exists' : 'null'}');
      debugPrint('- User ID: $userId');
      debugPrint('- Mobile: $mobile');
      
      // Get all keys except the ones we want to keep
      final keysToRemove = prefs.getKeys().where(
        (key) => key != 'token' && key != 'user_id' && key != 'mobile'
      ).toList();
      
      // Remove each key individually (safer than clear)
      for (var key in keysToRemove) {
        await prefs.remove(key);
        debugPrint('Removed key: $key');
      }
      
      // Verify that essential data is still there
      final afterToken = prefs.getString('token');
      final afterUserId = prefs.getString('user_id');
      final afterMobile = prefs.getString('mobile');
      
      debugPrint('Auth data after clearSavedData:');
      debugPrint('- Token: ${afterToken != null ? 'exists' : 'null'}');
      debugPrint('- User ID: $afterUserId');
      debugPrint('- Mobile: $afterMobile');
      
      debugPrint('Cleared all saved data except token, user ID, and mobile');
    } catch (e) {
      debugPrint('Error in clearSavedData: $e');
    }
  }

  // Update this method in your ApiServices class
Future<ApiResponse> registerPartner(String mobile) async {
  try {
    final url = Uri.parse('${ApiConstants.baseUrl}/partner/registerPartner');
    
    final payload = jsonEncode({
      "mobile": mobile,
    });
    
    debugPrint('Register Partner Request: $payload');
    
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: payload,
    );
    
    final rawResponseBody = response.body;
    debugPrint('Register Partner Raw Response: $rawResponseBody');
    
    // Directly extract from the raw response body using regex
    if (rawResponseBody.contains('token')) {
      final tokenRegex = RegExp(r'"token":"([^"]+)"');
      final match = tokenRegex.firstMatch(rawResponseBody);
      if (match != null && match.groupCount >= 1) {
        final token = match.group(1);
        if (token != null) {
          // Store token directly in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          debugPrint('Token extracted and saved to SharedPreferences: ${token.substring(0, 20)}...');
        }
      }
    }
    
    if (rawResponseBody.contains('id')) {
      final idRegex = RegExp(r'"id":(\d+)');
      final match = idRegex.firstMatch(rawResponseBody);
      if (match != null && match.groupCount >= 1) {
        final userId = match.group(1);
        if (userId != null) {
          // Store user ID directly in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', userId);
          debugPrint('User ID extracted and saved to SharedPreferences: $userId');
        }
      }
    }
    
    // Save mobile number
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobile', mobile);
    debugPrint('Mobile saved to SharedPreferences: $mobile');
    
    // Now try to decode the JSON
    Map<String, dynamic> responseData;
    try {
      responseData = jsonDecode(rawResponseBody);
    } catch (e) {
      debugPrint('Error decoding response JSON: $e');
      throw ApiException('Invalid response format from server');
    }
    
    if (response.statusCode == 200) {
      // Extract status, message, and data from response
      final status = responseData['status'];
      final message = responseData['message'] ?? '';
      final data = responseData['data'];
      
      // Return API response
      return ApiResponse(
        success: true,
        data: data,
        message: message,
        status: status,
      );
    } else if (response.statusCode == 401) {
      // Handle unauthorized error
      throw UnauthorizedException('Unauthorized access. Please login again.');
    } else {
      return ApiResponse(
        success: false,
        message: responseData['message'] ?? 'Registration failed',
        status: responseData['status'] ?? 'ERROR',
      );
    }
  } on UnauthorizedException {
    rethrow;
  } catch (e) {
    throw ApiException('Failed to register partner: $e');
  }
}
  

  
  Future<bool> isTokenValid() async {
    final token = await TokenService.getToken();
    return token != null && token.isNotEmpty;
  }
 // Enhanced getDetailsByMobile method for your ApiServices class

Future<ApiResponse> getDetailsByMobile(String mobile) async {
  try {
    final token = await TokenService.getToken();
    
    if (token == null) {
      throw UnauthorizedException('No token found. Please login again.');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/partner/getDetailsByMobile?mobile=$mobile');
    debugPrint('Calling API: $url');
    
    final response = await _client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    debugPrint('Get Details Response: ${response.body}');
    
    final responseBody = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      final status = responseBody['status'];
      final message = responseBody['message'] ?? '';
      final data = responseBody['data'];
      
      // Add logging for debugging
      if (data != null) {
        debugPrint('Fetched restaurant data:');
        debugPrint('- Name: ${data['restaurant_name']}');
        debugPrint('- Email: ${data['email']}');
        debugPrint('- Address: ${data['address']}');
        debugPrint('- Category: ${data['category']}');
        debugPrint('- Operational Hours: ${data['operational_hours']}');
      }
      
      return ApiResponse(
        success: status == 'SUCCESS',
        data: data,
        message: message,
        status: status,
      );
    } else if (response.statusCode == 401) {
      throw UnauthorizedException('Unauthorized access. Please login again.');
    } else {
      return ApiResponse(
        success: false,
        message: responseBody['message'] ?? 'Failed to get details',
        status: responseBody['status'] ?? 'ERROR',
      );
    }
  } on UnauthorizedException {
    rethrow;
  } catch (e) {
    debugPrint('Error getting partner details: $e');
    throw ApiException('Failed to get partner details: $e');
  }
}


}

// Special exception for unauthorized errors
class UnauthorizedException implements Exception {
  final String message;
  
  UnauthorizedException(this.message);
  
  @override
  String toString() => 'UnauthorizedException: $message';
}