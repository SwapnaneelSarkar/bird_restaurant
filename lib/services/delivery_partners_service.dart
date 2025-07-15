import 'dart:convert';
import 'dart:io';
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
      
      if (licensePhotoPath != null && licensePhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('license_photo', licensePhotoPath));
      }
      if (vehicleDocumentPath != null && vehicleDocumentPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('vehicle_document', vehicleDocumentPath));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('Onboard Delivery Partner Response: ${response.statusCode} ${response.body}');
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
          message: responseBody['message'] ?? 'Failed to onboard delivery partner',
          status: responseBody['status'] ?? 'ERROR',
        );
      }
    } catch (e) {
      debugPrint('Error onboarding delivery partner: $e');
      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to onboard delivery partner. Please try again.',
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