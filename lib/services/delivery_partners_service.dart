import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/delivery_partner_model.dart';
import 'api_responses.dart';
import 'api_exception.dart';
import 'api_service.dart';
import 'token_service.dart';

class DeliveryPartnersService {
  late final http.Client _client;

  DeliveryPartnersService({http.Client? client}) {
    _client = client ?? http.Client();
  }

  Future<DeliveryPartnersResponse> getDeliveryPartners() async {
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        throw UnauthorizedException('No token found. Please login again.');
      }

      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        throw UnauthorizedException('Partner ID not found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/partner/delivery-partners/$partnerId');
      debugPrint('Calling Delivery Partners API: $url');
      
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('Delivery Partners Response Status: ${response.statusCode}');
      debugPrint('Delivery Partners Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final partnersResponse = DeliveryPartnersResponse.fromJson(responseBody);
        
        if (partnersResponse.data != null) {
          debugPrint('Delivery Partners Data:');
          debugPrint('- Partners Count: ${partnersResponse.data!.length}');
          
          for (final partner in partnersResponse.data!) {
            debugPrint('  - ${partner.name}: ${partner.status} (${partner.phone})');
          }
        }
        
        return partnersResponse;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        final responseBody = jsonDecode(response.body);
        return DeliveryPartnersResponse(
          status: responseBody['status'] ?? 'ERROR',
          message: responseBody['message'] ?? 'Failed to get delivery partners',
          data: null,
        );
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      debugPrint('Error getting delivery partners: $e');
      
      return DeliveryPartnersResponse(
        status: 'ERROR',
        message: 'Failed to fetch delivery partners. Please check your connection.',
        data: null,
      );
    }
  }

  // Helper method for backward compatibility with existing ApiResponse pattern
  Future<ApiResponse> getDeliveryPartnersLegacy() async {
    try {
      final partnersResponse = await getDeliveryPartners();
      
      return ApiResponse(
        success: partnersResponse.success,
        data: partnersResponse.data?.map((partner) => partner.toJson()).toList(),
        message: partnersResponse.message,
        status: partnersResponse.status,
      );
    } catch (e) {
      debugPrint('Error in getDeliveryPartnersLegacy: $e');
      throw ApiException('Failed to get delivery partners: $e');
    }
  }

  Future<ApiResponse> onboardDeliveryPartner({
    required String partnerId,
    required String phone,
    required String name,
    required String email,
    required String username,
    required String password,
    String? licensePhotoPath,
    String? vehicleDocumentPath,
    required String token,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/delivery-partner/onboard');
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['partner_id'] = partnerId;
      request.fields['phone'] = phone;
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['username'] = username;
      request.fields['password'] = password;
      
      // Add files with timeout and error handling
      if (licensePhotoPath != null && licensePhotoPath.isNotEmpty) {
        try {
          debugPrint('Onboard Delivery Partner: Adding license photo file...');
          final licenseFile = await http.MultipartFile.fromPath('license_photo', licensePhotoPath).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('License photo file processing timed out.');
            },
          );
          request.files.add(licenseFile);
          debugPrint('Onboard Delivery Partner: License photo file added successfully');
        } catch (e) {
          debugPrint('Onboard Delivery Partner: Error adding license photo file: $e');
          return ApiResponse(
            success: false,
            data: null,
            message: 'Error processing license photo. Please try again.',
            status: 'ERROR',
          );
        }
      }
      
      if (vehicleDocumentPath != null && vehicleDocumentPath.isNotEmpty) {
        try {
          debugPrint('Onboard Delivery Partner: Adding vehicle document file...');
          final vehicleFile = await http.MultipartFile.fromPath('vehicle_document', vehicleDocumentPath).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Vehicle document file processing timed out.');
            },
          );
          request.files.add(vehicleFile);
          debugPrint('Onboard Delivery Partner: Vehicle document file added successfully');
        } catch (e) {
          debugPrint('Onboard Delivery Partner: Error adding vehicle document file: $e');
          return ApiResponse(
            success: false,
            data: null,
            message: 'Error processing vehicle document. Please try again.',
            status: 'ERROR',
          );
        }
      }
      
      debugPrint('Onboard Delivery Partner Request:');
      debugPrint('URL: $url');
      debugPrint('Partner ID: $partnerId');
      debugPrint('Phone: $phone');
      debugPrint('Name: $name');
      debugPrint('Email: $email');
      debugPrint('Username: $username');
      debugPrint('License Photo: ${licensePhotoPath ?? 'Not provided'}');
      debugPrint('Vehicle Document: ${vehicleDocumentPath ?? 'Not provided'}');
      
      // Add timeout to the entire request process
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30), // 30 second timeout
        onTimeout: () {
          throw TimeoutException('Request timed out. Please try again.');
        },
      );
      
      debugPrint('Onboard Delivery Partner: Streamed response received, converting to response...');
      
      final response = await http.Response.fromStream(streamedResponse).timeout(
        const Duration(seconds: 10), // 10 second timeout for response conversion
        onTimeout: () {
          throw TimeoutException('Response conversion timed out. Please try again.');
        },
      );
      
      debugPrint('Onboard Delivery Partner Response: ${response.statusCode} ${response.body}');
      
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return ApiResponse(
          success: responseBody['status'] == 'SUCCESS',
          data: responseBody['data'],
          message: responseBody['message'] ?? '',
          status: responseBody['status'] ?? '',
        );
      } else if (response.statusCode == 504) {
        debugPrint('Gateway Timeout Error (504) - Server is taking too long to respond');
        return ApiResponse(
          success: false,
          data: null,
          message: 'Server is taking too long to respond. Please try again in a few moments.',
          status: 'TIMEOUT',
        );
      } else if (response.statusCode == 408) {
        debugPrint('Request Timeout Error (408)');
        return ApiResponse(
          success: false,
          data: null,
          message: 'Request timed out. Please check your connection and try again.',
          status: 'TIMEOUT',
        );
      } else if (response.statusCode == 413) {
        debugPrint('Payload Too Large Error (413) - File size too large');
        return ApiResponse(
          success: false,
          data: null,
          message: 'File size too large. Please compress your images and try again.',
          status: 'ERROR',
        );
      } else {
        try {
          final responseBody = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            data: null,
            message: responseBody['message'] ?? 'Failed to onboard delivery partner (HTTP ${response.statusCode})',
            status: responseBody['status'] ?? 'ERROR',
          );
        } catch (parseError) {
          debugPrint('Failed to parse error response: $parseError');
          return ApiResponse(
            success: false,
            data: null,
            message: 'Server error (HTTP ${response.statusCode}). Please try again.',
            status: 'ERROR',
          );
        }
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout error onboarding delivery partner: $e');
      return ApiResponse(
        success: false,
        data: null,
        message: 'Request timed out. Please check your connection and try again.',
        status: 'TIMEOUT',
      );
    } on FormatException catch (e) {
      debugPrint('Format error onboarding delivery partner: $e');
      return ApiResponse(
        success: false,
        data: null,
        message: 'Invalid response from server. Please try again.',
        status: 'ERROR',
      );
    } catch (e) {
      debugPrint('Error onboarding delivery partner: $e');
      
      // If the error is related to file upload or timeout, try without files as fallback
      if ((e.toString().contains('TimeoutException') || e.toString().contains('504')) && 
          (licensePhotoPath != null || vehicleDocumentPath != null)) {
        debugPrint('Onboard Delivery Partner: Trying fallback without files...');
        
        try {
          final fallbackUrl = Uri.parse('${ApiConstants.baseUrl}/partner/delivery-partner/onboard');
          var fallbackRequest = http.MultipartRequest('POST', fallbackUrl);
          fallbackRequest.headers['Authorization'] = 'Bearer $token';
          fallbackRequest.fields['partner_id'] = partnerId;
          fallbackRequest.fields['phone'] = phone;
          fallbackRequest.fields['name'] = name;
          fallbackRequest.fields['email'] = email;
          fallbackRequest.fields['username'] = username;
          fallbackRequest.fields['password'] = password;
          
          debugPrint('Onboard Delivery Partner: Fallback request without files...');
          
          final fallbackStreamedResponse = await fallbackRequest.send().timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Fallback request timed out.');
            },
          );
          
          final fallbackResponse = await http.Response.fromStream(fallbackStreamedResponse).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Fallback response conversion timed out.');
            },
          );
          
          debugPrint('Onboard Delivery Partner Fallback Response: ${fallbackResponse.statusCode} ${fallbackResponse.body}');
          
          if (fallbackResponse.statusCode == 200) {
            final responseBody = jsonDecode(fallbackResponse.body);
            return ApiResponse(
              success: responseBody['status'] == 'SUCCESS',
              data: responseBody['data'],
              message: 'Delivery partner added successfully (without documents). You can add documents later.',
              status: responseBody['status'] ?? '',
            );
          }
        } catch (fallbackError) {
          debugPrint('Onboard Delivery Partner: Fallback also failed: $fallbackError');
        }
      }
      
      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to onboard delivery partner. Please try again.',
        status: 'ERROR',
      );
    }
  }

  Future<ApiResponse> updateDeliveryPartner({
    required String deliveryPartnerId,
    required String name,
    required String phone,
    String? email,
    String? vehicleType,
    String? vehicleNumber,
    String? licensePhotoPath,
    String? vehicleDocumentPath,
    required String token,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/delivery-partner/$deliveryPartnerId');
      debugPrint('[API] UPDATE Delivery Partner');
      debugPrint('URL: ' + url.toString());
      debugPrint('Method: PUT');
      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = name;
      request.fields['phone'] = phone;
      if (email != null) request.fields['email'] = email;
      if (vehicleType != null) request.fields['vehicle_type'] = vehicleType;
      if (vehicleNumber != null) request.fields['vehicle_number'] = vehicleNumber;
      if (licensePhotoPath != null && licensePhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('license_photo', licensePhotoPath));
      }
      if (vehicleDocumentPath != null && vehicleDocumentPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('vehicle_document', vehicleDocumentPath));
      }
      debugPrint('Headers: ' + request.headers.toString());
      debugPrint('Fields: ' + request.fields.toString());
      debugPrint('Files: ' + request.files.map((f) => f.field + ': ' + f.filename.toString()).toList().toString());
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('Status Code: ' + response.statusCode.toString());
      debugPrint('Raw Response Body: ' + response.body);
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return ApiResponse(
          success: responseBody['status'] == 'SUCCESS',
          data: responseBody['data'],
          message: responseBody['message'] ?? '',
          status: responseBody['status'] ?? '',
        );
      } else {
        final responseBody = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          data: null,
          message: responseBody['message'] ?? 'Failed to update delivery partner',
          status: responseBody['status'] ?? 'ERROR',
        );
      }
    } catch (e) {
      debugPrint('Error updating delivery partner: $e');
      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to update delivery partner. Please try again.',
        status: 'ERROR',
      );
    }
  }

  Future<ApiResponse> deleteDeliveryPartner(String deliveryPartnerId, String token) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/delivery-partner/$deliveryPartnerId');
      final response = await _client.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('Delete Delivery Partner Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return ApiResponse(
          success: responseBody['status'] == 'SUCCESS',
          data: responseBody['data'],
          message: responseBody['message'] ?? '',
          status: responseBody['status'] ?? '',
        );
      } else {
        final responseBody = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          data: null,
          message: responseBody['message'] ?? 'Failed to delete delivery partner',
          status: responseBody['status'] ?? 'ERROR',
        );
      }
    } catch (e) {
      debugPrint('Error deleting delivery partner: $e');
      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to delete delivery partner. Please try again.',
        status: 'ERROR',
      );
    }
  }
} 