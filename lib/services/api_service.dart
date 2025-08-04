import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../constants/api_constants.dart';
import '../models/partner_summary_model.dart';
import '../models/food_type_model.dart';
import 'api_responses.dart';
import 'api_exception.dart';
import 'token_service.dart';

class ApiServices {
  late final http.Client _client;

  ApiServices({http.Client? client}) {
    if (client != null) {
      _client = client;
    } else {
      _client = _createHttpClient();
    }
  }
  
  http.Client _createHttpClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        debugPrint('Accepting certificate for host: $host');
        return true;
      }
      ..connectionTimeout = const Duration(seconds: 30);
    
    return IOClient(httpClient);
  }
Future<PartnerSummaryResponse> getPartnerSummary() async {
  try {
    final token = await TokenService.getToken();
    
    if (token == null) {
      throw UnauthorizedException('No token found. Please login again.');
    }

    final partnerId = await TokenService.getUserId();
    if (partnerId == null) {
      throw UnauthorizedException('Partner ID not found. Please login again.');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/partner/summary/$partnerId');
    debugPrint('Calling Partner Summary API: $url');
    
    final response = await _client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    debugPrint('Partner Summary Response Status: ${response.statusCode}');
    debugPrint('Partner Summary Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final summaryResponse = PartnerSummaryResponse.fromJson(responseBody);
      
      if (summaryResponse.data != null) {
        debugPrint('Partner Summary Data:');
        debugPrint('- Orders Count: ${summaryResponse.data!.ordersCount}');
        debugPrint('- Products Count: ${summaryResponse.data!.productsCount}');
        debugPrint('- Tags Count: ${summaryResponse.data!.tagsCount}');
        debugPrint('- Rating: ${summaryResponse.data!.rating}');
        debugPrint('- Accepting Orders: ${summaryResponse.data!.acceptingOrders}');
        debugPrint('- Sales Data Points: ${summaryResponse.data!.salesData.length}');
        
        // Log sales data for debugging
        for (final salesPoint in summaryResponse.data!.salesData) {
          debugPrint('  - ${salesPoint.date}: ${salesPoint.sales} sales');
        }
      }
      
      return summaryResponse;
    } else if (response.statusCode == 401) {
      throw UnauthorizedException('Unauthorized access. Please login again.');
    } else {
      final responseBody = jsonDecode(response.body);
      return PartnerSummaryResponse(
        status: responseBody['status'] ?? 'ERROR',
        message: responseBody['message'] ?? 'Failed to get partner summary',
        data: null,
      );
    }
  } on UnauthorizedException {
    rethrow;
  } catch (e) {
    debugPrint('Error getting partner summary: $e');
    
    // Return error response instead of throwing exception
    return const PartnerSummaryResponse(
      status: 'ERROR',
      message: 'Failed to fetch partner summary. Please check your connection.',
      data: null,
    );
  }
}

// Also add this helper method for backward compatibility with existing ApiResponse pattern:

Future<ApiResponse> getPartnerSummaryLegacy() async {
  try {
    final summaryResponse = await getPartnerSummary();
    
    return ApiResponse(
      success: summaryResponse.success,
      data: summaryResponse.data?.toJson(),
      message: summaryResponse.message,
      status: summaryResponse.status,
    );
  } catch (e) {
    debugPrint('Error in getPartnerSummaryLegacy: $e');
    throw ApiException('Failed to get partner summary: $e');
  }
}

  Future<ApiResponse> updatePartner({
    required String restaurantName,
    required String address,
    required String email,
    required String category,
    required String operationalHours,
    double? latitude,
    double? longitude,
    String? supercategory,
    File? fssaiLicense,
    File? gstCertificate,
    File? panCard,
    List<File>? restaurantPhotos,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final partnerId = prefs.getString('user_id');
      
      if (token == null || partnerId == null) {
        throw UnauthorizedException('No token or user ID found. Please login again.');
      }

      debugPrint('Token: $token');
      debugPrint('Partner ID: $partnerId');

      final url = Uri.parse('${ApiConstants.baseUrl}/partner/updatePartner');
      
      var request = http.MultipartRequest('POST', url);
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      request.fields['partnerId'] = partnerId.toString();
      request.fields['restaurant_name'] = restaurantName;
      request.fields['address'] = address;
      request.fields['email'] = email;
      request.fields['category'] = category;
      request.fields['operational_hours'] = operationalHours;
      
      if (supercategory != null && supercategory.isNotEmpty) {
        request.fields['supercategory'] = supercategory;
      }
      
      if (latitude != null && !latitude.isNaN && !latitude.isInfinite) {
        request.fields['latitude'] = latitude.toString();
        debugPrint('Adding latitude to API request: $latitude');
      }
      
      if (longitude != null && !longitude.isNaN && !longitude.isInfinite) {
        request.fields['longitude'] = longitude.toString();
        debugPrint('Adding longitude to API request: $longitude');
      }
      
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
      
      debugPrint('Update Partner Request:');
      debugPrint('URL: $url');
      debugPrint('Headers: ${request.headers}');
      debugPrint('Fields: ${request.fields}');
      debugPrint('Files: ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}');
      
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Update Partner Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      
      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 413) {
        throw ApiException('The total size of files is too large. Please compress your images or reduce the number of files.');
      }

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
  String? restaurantType,
  String? restaurantFoodType,
  String? supercategory,
  File? fssaiLicense,
  File? gstCertificate,
  File? panCard,
  List<File>? restaurantPhotos,
  int retryCount = 0,
}) async {
  try {
    if (retryCount >= 3) {
      return ApiResponse(
        success: false,
        message: "Failed after multiple attempts. Please try again later.",
        status: "ERROR",
      );
    }

    final token = await TokenService.getToken();
    final partnerId = await TokenService.getUserId();
    
    if (token == null || partnerId == null) {
      throw UnauthorizedException('No token or user ID found. Please login again.');
    }

    debugPrint('Token retrieved successfully: ${token.substring(0, min(20, token.length))}...');
    debugPrint('User ID retrieved successfully: $partnerId');

    final url = Uri.parse('${ApiConstants.baseUrl}/partner/updatePartner');
    
    var request = http.MultipartRequest('POST', url);
    
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });
    
    request.fields['partnerId'] = partnerId.toString();
    request.fields['restaurant_name'] = restaurantName;
    request.fields['address'] = address;
    request.fields['email'] = email;
    request.fields['category'] = category;
    request.fields['operational_hours'] = operationalHours;
    request.fields['owner_name'] = ownerName;
    
    request.fields['latitude'] = latitude;
    request.fields['longitude'] = longitude;
    debugPrint('Adding coordinates to API request - Latitude: $latitude, Longitude: $longitude');
    
    request.fields['veg_nonveg'] = vegNonveg;
    request.fields['cooking_time'] = cookingTime;
    
    if (restaurantType != null && restaurantType.isNotEmpty) {
      request.fields['restaurant_type'] = restaurantType;
      debugPrint('Adding restaurant_type to API request: $restaurantType');
    }
    
    if (restaurantFoodType != null && restaurantFoodType.isNotEmpty) {
      request.fields['restaurantFoodType'] = restaurantFoodType;
      debugPrint('Adding restaurantFoodType to API request: $restaurantFoodType');
    }
    
    if (supercategory != null && supercategory.isNotEmpty) {
      request.fields['supercategory'] = supercategory;
      debugPrint('Adding supercategory to API request: $supercategory');
    }
    
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobile');
    if (mobile != null && mobile.isNotEmpty) {
      request.fields['mobile'] = mobile;
      request.fields['partner_id'] = partnerId;
    }
    
    try {
      if (fssaiLicense != null && await fssaiLicense.exists()) {
        request.files.add(await _createMultipartFile(
          'fssai_license_doc',
          fssaiLicense,
        ));
      }
      
      if (gstCertificate != null && await gstCertificate.exists()) {
        request.files.add(await _createMultipartFile(
          'gst_certificate_doc',
          gstCertificate,
        ));
      }
      
      if (panCard != null && await panCard.exists()) {
        request.files.add(await _createMultipartFile(
          'pan_card_doc',
          panCard,
        ));
      }
      
      if (restaurantPhotos != null && restaurantPhotos.isNotEmpty) {
        for (var i = 0; i < restaurantPhotos.length; i++) {
          if (await restaurantPhotos[i].exists()) {
            request.files.add(await _createMultipartFile(
              'restaurant_photos',
              restaurantPhotos[i],
            ));
          }
        }
      }
    } catch (fileError) {
      debugPrint('Error adding files to request: $fileError');
      debugPrint('Continuing with request without missing files');
    }
    
    debugPrint('Update Partner With All Fields Request:');
    debugPrint('URL: $url');
    debugPrint('Headers: ${request.headers}');
    debugPrint('Fields: ${request.fields}');
    debugPrint('Files: ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}');
    
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    
    debugPrint('Update Partner Response:');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    
    if (response.body.trim().startsWith('<') || 
        response.body.contains('<!DOCTYPE') || 
        response.body.contains('<html')) {
      if (response.statusCode == 413) {
        throw ApiException('Request too large. Please reduce the file sizes.');
      }
      throw ApiException('Server returned HTML instead of JSON. Status: ${response.statusCode}');
    }
    
    Map<String, dynamic> responseBody;
    try {
      responseBody = jsonDecode(response.body);
    } catch (e) {
      throw ApiException('Invalid response format: ${response.body}');
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
    } else if (response.statusCode == 400 && 
               responseBody['message']?.toString().contains('Partner ID is missing') == true) {
      debugPrint('Partner ID missing error detected. Attempting to refresh token...');
      
      final mobileNumber = prefs.getString('mobile');
      if (mobileNumber != null && mobileNumber.isNotEmpty) {
        final refreshResponse = await registerPartner(mobileNumber);
        if (refreshResponse.success) {
          debugPrint('Token refreshed successfully. Retrying update...');
          return updatePartnerWithAllFields(
            restaurantName: restaurantName,
            address: address,
            email: email,
            category: category,
            operationalHours: operationalHours,
            ownerName: ownerName,
            latitude: latitude,
            longitude: longitude,
            vegNonveg: vegNonveg,
            cookingTime: cookingTime,
            restaurantType: restaurantType,
            restaurantFoodType: restaurantFoodType,
            fssaiLicense: fssaiLicense,
            gstCertificate: gstCertificate,
            panCard: panCard,
            restaurantPhotos: restaurantPhotos,
            retryCount: retryCount + 1,
          );
        }
      }
      
      if (retryCount < 1) {
        debugPrint('Trying submission without files...');
        return updatePartnerWithAllFields(
          restaurantName: restaurantName,
          address: address,
          email: email,
          category: category,
          operationalHours: operationalHours,
          ownerName: ownerName,
          latitude: latitude,
          longitude: longitude,
          vegNonveg: vegNonveg,
          cookingTime: cookingTime,
          restaurantType: restaurantType,
          restaurantFoodType: restaurantFoodType,
          fssaiLicense: null,
          gstCertificate: null,
          panCard: null,
          restaurantPhotos: null,
          retryCount: retryCount + 1,
        );
      }
      
      return ApiResponse(
        success: false,
        message: responseBody['message'] ?? 'Update failed',
        status: responseBody['status'] ?? 'ERROR',
      );
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
    if ((e.toString().contains('PathNotFoundException') || 
         e.toString().contains('No such file or directory')) && 
        retryCount < 1) {
      debugPrint('File access error detected. Retrying without files...');
      return updatePartnerWithAllFields(
        restaurantName: restaurantName,
        address: address,
        email: email,
        category: category,
        operationalHours: operationalHours,
        ownerName: ownerName,
        latitude: latitude,
        longitude: longitude,
        vegNonveg: vegNonveg,
        cookingTime: cookingTime,
        restaurantType: restaurantType,
        fssaiLicense: null,
        gstCertificate: null,
        panCard: null,
        restaurantPhotos: null,
        retryCount: retryCount + 1,
      );
    }
    
    debugPrint('Error updating partner: $e');
    throw ApiException('Failed to update partner: $e');
  }
}
  Future<http.MultipartFile> _createMultipartFile(String field, File file) async {
    String? mimeType = lookupMimeType(file.path);
    MediaType? contentType;
    
    if (mimeType != null) {
      var mimeTypeData = mimeType.split('/');
      if (mimeTypeData.length == 2) {
        contentType = MediaType(mimeTypeData[0], mimeTypeData[1]);
      }
    }
    
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
      
      final token = prefs.getString('token');
      final userId = prefs.getString('user_id');
      final mobile = prefs.getString('mobile');
      
      debugPrint('Preserving auth data during clearSavedData:');
      debugPrint('- Token: ${token != null ? 'exists' : 'null'}');
      debugPrint('- User ID: $userId');
      debugPrint('- Mobile: $mobile');
      
      final keysToRemove = prefs.getKeys().where(
        (key) => key != 'token' && key != 'user_id' && key != 'mobile'
      ).toList();
      
      for (var key in keysToRemove) {
        await prefs.remove(key);
        debugPrint('Removed key: $key');
      }
      
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
    
    Map<String, dynamic> responseData;
    try {
      responseData = jsonDecode(rawResponseBody);
    } catch (e) {
      debugPrint('Error decoding response JSON: $e');
      throw ApiException('Invalid response format from server');
    }
    
    final data = responseData['data'] as Map<String, dynamic>?;
    if (data != null) {
      if (data['token'] != null) {
        final token = data['token'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await TokenService.saveToken(token);
        debugPrint('Token extracted and saved to SharedPreferences: ${token.substring(0, 20)}...');
      }
      
      if (data['partner_id'] != null) {
        final partnerId = data['partner_id'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', partnerId);
        await TokenService.saveUserId(partnerId);
        debugPrint('Partner ID extracted and saved to SharedPreferences: $partnerId');
      }
      else if (data['id'] != null) {
        final userId = data['id'].toString();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
        await TokenService.saveUserId(userId);
        debugPrint('User ID extracted and saved to SharedPreferences: $userId');
      }
      
      if (data['mobile'] != null) {
        final savedMobile = data['mobile'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mobile', savedMobile);
        await TokenService.saveMobile(savedMobile);
        debugPrint('Mobile saved to SharedPreferences: $savedMobile');
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mobile', mobile);
        await TokenService.saveMobile(mobile);
        debugPrint('Mobile saved to SharedPreferences: $mobile');
      }
      
      // NEW: Save supercategory ID if present in the response
      if (data['supercategory'] != null) {
        final supercategory = data['supercategory'] as Map<String, dynamic>;
        if (supercategory['id'] != null) {
          final supercategoryId = supercategory['id'] as String;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('supercategory_id', supercategoryId);
          await TokenService.saveSupercategoryId(supercategoryId);
          debugPrint('Supercategory ID extracted and saved to SharedPreferences: $supercategoryId');
        }
      }
    } else {
      if (rawResponseBody.contains('token')) {
        final tokenRegex = RegExp(r'"token":"([^"]+)"');
        final match = tokenRegex.firstMatch(rawResponseBody);
        if (match != null && match.groupCount >= 1) {
          final token = match.group(1);
          if (token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', token);
            await TokenService.saveToken(token);
            debugPrint('Token extracted and saved to SharedPreferences using regex: ${token.substring(0, 20)}...');
          }
        }
      }
      
      if (rawResponseBody.contains('partner_id')) {
        final partnerIdRegex = RegExp(r'"partner_id":"([^"]+)"');
        final match = partnerIdRegex.firstMatch(rawResponseBody);
        if (match != null && match.groupCount >= 1) {
          final partnerId = match.group(1);
          if (partnerId != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', partnerId);
            await TokenService.saveUserId(partnerId);
            debugPrint('Partner ID extracted and saved to SharedPreferences using regex: $partnerId');
          }
        }
      } 
      else if (rawResponseBody.contains('"id":')) {
        final idRegex = RegExp(r'"id":(\d+)');
        final match = idRegex.firstMatch(rawResponseBody);
        if (match != null && match.groupCount >= 1) {
          final userId = match.group(1);
          if (userId != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', userId);
            await TokenService.saveUserId(userId);
            debugPrint('User ID extracted and saved to SharedPreferences using regex: $userId');
          }
        }
      }
      
      // NEW: Extract supercategory ID using regex if data is null
      if (rawResponseBody.contains('"supercategory"')) {
        final supercategoryIdRegex = RegExp(r'"supercategory":\s*\{[^}]*"id":\s*"([^"]+)"');
        final match = supercategoryIdRegex.firstMatch(rawResponseBody);
        if (match != null && match.groupCount >= 1) {
          final supercategoryId = match.group(1);
          if (supercategoryId != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('supercategory_id', supercategoryId);
            await TokenService.saveSupercategoryId(supercategoryId);
            debugPrint('Supercategory ID extracted and saved to SharedPreferences using regex: $supercategoryId');
          }
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mobile', mobile);
      await TokenService.saveMobile(mobile);
      debugPrint('Mobile saved to SharedPreferences: $mobile');
    }
    
    if (response.statusCode == 200) {
      final status = responseData['status'];
      final message = responseData['message'] ?? '';
      
      return ApiResponse(
        success: true,
        data: data,
        message: message,
        status: status,
      );
    } else if (response.statusCode == 401) {
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

Future<ApiResponse> getRestaurantDetails(String partnerId) async {
  try {
    final token = await TokenService.getToken();
    
    if (token == null) {
      throw UnauthorizedException('No token found. Please login again.');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/partner/restaurant/$partnerId');
    debugPrint('Calling Restaurant API: $url');
    
    final response = await _client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    debugPrint('Get Restaurant Details Response: ${response.body}');
    
    final responseBody = jsonDecode(response.body);
    
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
        message: responseBody['message'] ?? 'Failed to get restaurant details',
        status: responseBody['status'] ?? 'ERROR',
      );
    }
  } on UnauthorizedException {
    rethrow;
  } catch (e) {
    debugPrint('Error getting restaurant details: $e');
    throw ApiException('Failed to get restaurant details: $e');
  }
}

Future<ApiResponse> updateOrderAcceptance({
  required String partnerId,
  required bool acceptingOrders,
}) async {
  try {
    final token = await TokenService.getToken();
    
    if (token == null) {
      throw UnauthorizedException('No token found. Please login again.');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/partner/updateAccepting');
    debugPrint('Updating order acceptance status: $url');
    
    final response = await _client.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'partner_id': partnerId,
        'accepting_orders': acceptingOrders,
      }),
    );
    
    debugPrint('Update Order Acceptance Response: ${response.body}');
    
    final responseBody = jsonDecode(response.body);
    
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
        message: responseBody['message'] ?? 'Failed to update order acceptance status',
        status: responseBody['status'] ?? 'ERROR',
      );
    }
  } on UnauthorizedException {
    rethrow;
  } catch (e) {
    debugPrint('Error updating order acceptance status: $e');
    throw ApiException('Failed to update order acceptance status: $e');
  }
}

  // Get restaurant food types
  Future<FoodTypesResponse> getRestaurantFoodTypes() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/admin/restaurantFoodTypes');
      debugPrint('Calling Restaurant Food Types API: $url');
      
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('Restaurant Food Types Response Status: ${response.statusCode}');
      debugPrint('Restaurant Food Types Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return FoodTypesResponse.fromJson(responseBody);
      } else {
        throw ApiException('Failed to fetch food types. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching restaurant food types: $e');
      throw ApiException('Failed to fetch restaurant food types: $e');
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  
  UnauthorizedException(this.message);
  
  @override
  String toString() => 'UnauthorizedException: $message';
}
