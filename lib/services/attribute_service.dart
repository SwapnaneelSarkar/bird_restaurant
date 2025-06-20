// lib/services/attribute_service.dart
import 'dart:convert';
import 'package:bird_restaurant/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/attribute_model.dart';
import '../services/api_exception.dart';

class AttributeService {
  static const String _attributesEndpoint = '/partner/menu_item';

  // Get all attributes for a menu item
  static Future<AttributeResponse> getAttributes(String menuId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw UnauthorizedException('No token found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_attributesEndpoint/$menuId/attributes');
      
      debugPrint('Fetching attributes from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Get Attributes Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return AttributeResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiException(responseData['message'] ?? 'Failed to fetch attributes');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ApiException) {
        rethrow;
      }
      debugPrint('Error fetching attributes: $e');
      throw ApiException('Failed to fetch attributes: $e');
    }
  }

  // Create a new attribute group
  static Future<CreateAttributeResponse> createAttribute({
    required String menuId,
    required String name,
    required String type,
    required bool isRequired,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw UnauthorizedException('No token found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_attributesEndpoint/$menuId/attributes');
      
      final requestBody = CreateAttributeRequest(
        name: name,
        type: type,
        isRequired: isRequired,
      ).toJson();

      debugPrint('Creating attribute at: $url');
      debugPrint('Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('Create Attribute Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return CreateAttributeResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiException(responseData['message'] ?? 'Failed to create attribute');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ApiException) {
        rethrow;
      }
      debugPrint('Error creating attribute: $e');
      throw ApiException('Failed to create attribute: $e');
    }
  }

  // Add values to an attribute
  static Future<CreateAttributeValueResponse> addAttributeValue({
    required String menuId,
    required String attributeId,
    required String name,
    required int priceAdjustment,
    required bool isDefault,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw UnauthorizedException('No token found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_attributesEndpoint/$menuId/attributes/$attributeId/values');
      
      final requestBody = CreateAttributeValueRequest(
        name: name,
        priceAdjustment: priceAdjustment,
        isDefault: isDefault,
      ).toJson();

      debugPrint('Adding attribute value at: $url');
      debugPrint('Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('Add Attribute Value Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return CreateAttributeValueResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiException(responseData['message'] ?? 'Failed to add attribute value');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ApiException) {
        rethrow;
      }
      debugPrint('Error adding attribute value: $e');
      throw ApiException('Failed to add attribute value: $e');
    }
  }

  // Update attribute status (activate/deactivate)
  static Future<bool> updateAttributeStatus({
    required String menuId,
    required String attributeId,
    required String name,
    required String type,
    required bool isRequired,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw UnauthorizedException('No token found. Please login again.');
      }
      final url = Uri.parse('${ApiConstants.baseUrl}$_attributesEndpoint/$menuId/attributes/$attributeId');
      final requestBody = {
        'name': name,
        'type': type,
        'is_required': isRequired,
      };
      debugPrint('Updating attribute status at: $url');
      debugPrint('Request body: ${jsonEncode(requestBody)}');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      debugPrint('Update Attribute Status Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiException(responseData['message'] ?? 'Failed to update attribute status');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ApiException) {
        rethrow;
      }
      debugPrint('Error updating attribute status: $e');
      throw ApiException('Failed to update attribute status: $e');
    }
  }

  // Delete attribute value
  static Future<bool> deleteAttributeValue({
    required String menuId,
    required String attributeId,
    required String valueId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw UnauthorizedException('No token found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_attributesEndpoint/$menuId/attributes/$attributeId/values/$valueId');
      
      debugPrint('Deleting attribute value at: $url');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Delete Attribute Value Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiException(responseData['message'] ?? 'Failed to delete attribute value');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ApiException) {
        rethrow;
      }
      debugPrint('Error deleting attribute value: $e');
      throw ApiException('Failed to delete attribute value: $e');
    }
  }

  // Delete entire attribute group
  static Future<bool> deleteAttribute({
    required String menuId,
    required String attributeId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw UnauthorizedException('No token found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_attributesEndpoint/$menuId/attributes/$attributeId');
      
      debugPrint('Deleting attribute at: $url');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Delete Attribute Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiException(responseData['message'] ?? 'Failed to delete attribute');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ApiException) {
        rethrow;
      }
      debugPrint('Error deleting attribute: $e');
      throw ApiException('Failed to delete attribute: $e');
    }
  }

  // Update attribute value
  static Future<bool> updateAttributeValue({
    required String menuId,
    required String attributeId,
    required String valueId,
    required String name,
    required int priceAdjustment,
    required bool isDefault,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw UnauthorizedException('No token found. Please login again.');
      }
      final url = Uri.parse('${ApiConstants.baseUrl}$_attributesEndpoint/$menuId/attributes/$attributeId/values/$valueId');
      final requestBody = {
        'name': name,
        'price_adjustment': priceAdjustment,
        'is_default': isDefault,
      };
      debugPrint('Updating attribute value at: $url');
      debugPrint('Request body: \\${jsonEncode(requestBody)}');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      debugPrint('Update Attribute Value Response:');
      debugPrint('Status Code: \\${response.statusCode}');
      debugPrint('Body: \\${response.body}');
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiException(responseData['message'] ?? 'Failed to update attribute value');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ApiException) {
        rethrow;
      }
      debugPrint('Error updating attribute value: $e');
      throw ApiException('Failed to update attribute value: $e');
    }
  }
}