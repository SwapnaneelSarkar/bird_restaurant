// lib/services/token_service.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'token';
  static const String _userIdKey = 'user_id';
  static const String _mobileKey = 'mobile';
  static const String _supercategoryIdKey = 'supercategory_id';

  // Save token with forced persistence check
  static Future<bool> saveToken(String token) async {
    try {
      // Don't save empty tokens
      if (token.isEmpty) {
        debugPrint('WARNING: Attempted to save empty token');
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_tokenKey, token);
      
      // Verify the token was saved correctly
      final savedToken = prefs.getString(_tokenKey);
      if (savedToken != token) {
        debugPrint('ERROR: Token verification failed after save');
        return false;
      }
      
      debugPrint('Token saved successfully: ${token.substring(0, min(20, token.length))}...');
      return result;
    } catch (e) {
      debugPrint('ERROR saving token: $e');
      return false;
    }
  }

  // Get token with additional logging
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      
      if (token == null) {
        debugPrint('No token found in shared preferences');
        return null;
      }
      
      if (token.isEmpty) {
        debugPrint('Empty token found in shared preferences');
        return null;
      }
      
      debugPrint('Token retrieved successfully: ${token.substring(0, min(20, token.length))}...');
      return token;
    } catch (e) {
      debugPrint('ERROR retrieving token: $e');
      return null;
    }
  }

  // Save user ID with verification and multiple storage options
  static Future<bool> saveUserId(dynamic userId) async {
    try {
      if (userId == null) {
        debugPrint('WARNING: Attempted to save null user ID');
        return false;
      }
      
      final userIdStr = userId.toString();
      final prefs = await SharedPreferences.getInstance();
      
      // Save as string 
      final result = await prefs.setString(_userIdKey, userIdStr);
      
      // Also save as int for backward compatibility if possible
      if (int.tryParse(userIdStr) != null) {
        await prefs.setInt('${_userIdKey}_int', int.parse(userIdStr));
      }
      
      // Verify the user ID was saved correctly
      final savedUserId = prefs.getString(_userIdKey);
      if (savedUserId != userIdStr) {
        debugPrint('ERROR: User ID verification failed after save');
        return false;
      }
      
      debugPrint('User ID saved successfully: $userIdStr');
      return result;
    } catch (e) {
      debugPrint('ERROR saving user ID: $e');
      return false;
    }
  }

  // Get user ID with multiple retrieval attempts
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try string first
      String? userId = prefs.getString(_userIdKey);
      
      // If not found, try int as fallback
      if (userId == null) {
        final userIdInt = prefs.getInt('${_userIdKey}_int');
        if (userIdInt != null) {
          userId = userIdInt.toString();
          debugPrint('User ID retrieved from int backup: $userId');
          
          // Also save it back as string for next time
          await prefs.setString(_userIdKey, userId);
        }
      }
      
      if (userId == null) {
        debugPrint('No user ID found in shared preferences');
      } else {
        debugPrint('User ID retrieved successfully: $userId');
      }
      
      return userId;
    } catch (e) {
      debugPrint('ERROR retrieving user ID: $e');
      return null;
    }
  }

  // Get user ID as int with improved error handling
  static Future<int?> getUserIdAsInt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try getting direct int first
      final userIdInt = prefs.getInt('${_userIdKey}_int');
      if (userIdInt != null) {
        return userIdInt;
      }
      
      // Fall back to string
      final userIdString = prefs.getString(_userIdKey);
      if (userIdString == null) {
        return null;
      }
      
      final parsedId = int.tryParse(userIdString);
      if (parsedId == null) {
        debugPrint('WARNING: User ID exists but cannot be converted to int: $userIdString');
      }
      return parsedId;
    } catch (e) {
      debugPrint('ERROR retrieving user ID as int: $e');
      return null;
    }
  }

  // Save mobile with verification
  static Future<bool> saveMobile(String mobile) async {
    try {
      if (mobile.isEmpty) {
        debugPrint('WARNING: Attempted to save empty mobile number');
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_mobileKey, mobile);
      
      // Verify the mobile was saved correctly
      final savedMobile = prefs.getString(_mobileKey);
      if (savedMobile != mobile) {
        debugPrint('ERROR: Mobile verification failed after save');
        return false;
      }
      
      debugPrint('Mobile saved successfully: $mobile');
      return result;
    } catch (e) {
      debugPrint('ERROR saving mobile: $e');
      return false;
    }
  }

  // Get mobile with additional logging
  static Future<String?> getMobile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString(_mobileKey);
      
      if (mobile == null || mobile.isEmpty) {
        debugPrint('No mobile number found in shared preferences');
        return null;
      }
      
      debugPrint('Mobile retrieved successfully: $mobile');
      return mobile;
    } catch (e) {
      debugPrint('ERROR retrieving mobile: $e');
      return null;
    }
  }

  // Save supercategory ID with verification
  static Future<bool> saveSupercategoryId(String supercategoryId) async {
    try {
      if (supercategoryId.isEmpty) {
        debugPrint('WARNING: Attempted to save empty supercategory ID');
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_supercategoryIdKey, supercategoryId);
      
      // Verify the supercategory ID was saved correctly
      final savedSupercategoryId = prefs.getString(_supercategoryIdKey);
      if (savedSupercategoryId != supercategoryId) {
        debugPrint('ERROR: Supercategory ID verification failed after save');
        return false;
      }
      
      debugPrint('Supercategory ID saved successfully: $supercategoryId');
      return result;
    } catch (e) {
      debugPrint('ERROR saving supercategory ID: $e');
      return false;
    }
  }

  // Get supercategory ID with additional logging
  static Future<String?> getSupercategoryId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final supercategoryId = prefs.getString(_supercategoryIdKey);
      
      if (supercategoryId == null || supercategoryId.isEmpty) {
        debugPrint('No supercategory ID found in shared preferences');
        return null;
      }
      
      debugPrint('Supercategory ID retrieved successfully: $supercategoryId');
      return supercategoryId;
    } catch (e) {
      debugPrint('ERROR retrieving supercategory ID: $e');
      return null;
    }
  }

  // Save all authentication data in one transaction
  static Future<bool> saveAuthData({
    required String token,
    required dynamic userId,
    required String mobile,
    String? supercategoryId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save all at once for atomicity
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userIdKey, userId.toString());
      await prefs.setString(_mobileKey, mobile);
      
      // Save supercategory ID if provided
      if (supercategoryId != null && supercategoryId.isNotEmpty) {
        await prefs.setString(_supercategoryIdKey, supercategoryId);
      }
      
      // Also save userId as int if possible
      if (int.tryParse(userId.toString()) != null) {
        await prefs.setInt('${_userIdKey}_int', int.parse(userId.toString()));
      }
      
      // Verify all saved correctly
      final savedToken = prefs.getString(_tokenKey);
      final savedUserId = prefs.getString(_userIdKey);
      final savedMobile = prefs.getString(_mobileKey);
      final savedSupercategoryId = prefs.getString(_supercategoryIdKey);
      
      final allSaved = savedToken == token && 
                        savedUserId == userId.toString() && 
                        savedMobile == mobile &&
                        (supercategoryId == null || savedSupercategoryId == supercategoryId);
      
      if (allSaved) {
        debugPrint('All auth data saved successfully');
      } else {
        debugPrint('WARNING: Some auth data may not have saved correctly');
        debugPrint('Token match: ${savedToken == token}');
        debugPrint('User ID match: ${savedUserId == userId.toString()}');
        debugPrint('Mobile match: ${savedMobile == mobile}');
        debugPrint('Supercategory ID match: ${savedSupercategoryId == supercategoryId}');
      }
      
      return allSaved;
    } catch (e) {
      debugPrint('ERROR saving auth data: $e');
      return false;
    }
  }

  // Clear data except essential fields with improved reliability
  static Future<void> clearDataExceptEssentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get the values we want to keep
      final mobile = prefs.getString(_mobileKey);
      final token = prefs.getString(_tokenKey);
      final userId = prefs.getString(_userIdKey);
      final userIdInt = prefs.getInt('${_userIdKey}_int');
      final supercategoryId = prefs.getString(_supercategoryIdKey);
      
      debugPrint('Before clearing - mobile: $mobile');
      if (token != null && token.isNotEmpty) {
        debugPrint('Before clearing - token: ${token.substring(0, min(20, token.length))}...');
      } else {
        debugPrint('Before clearing - token: null or empty');
      }
      debugPrint('Before clearing - user_id: $userId');
      debugPrint('Before clearing - user_id_int: $userIdInt');
      debugPrint('Before clearing - supercategory_id: $supercategoryId');
      
      // Clear everything
      await prefs.clear();
      
      // Restore the essential values
      if (mobile != null && mobile.isNotEmpty) {
        await prefs.setString(_mobileKey, mobile);
        debugPrint('Restored mobile: $mobile');
      }
      
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_tokenKey, token);
        debugPrint('Restored token');
      }
      
      if (userId != null && userId.isNotEmpty) {
        await prefs.setString(_userIdKey, userId);
        debugPrint('Restored user_id: $userId');
      }
      
      if (userIdInt != null) {
        await prefs.setInt('${_userIdKey}_int', userIdInt);
        debugPrint('Restored user_id_int: $userIdInt');
      }
      
      if (supercategoryId != null && supercategoryId.isNotEmpty) {
        await prefs.setString(_supercategoryIdKey, supercategoryId);
        debugPrint('Restored supercategory_id: $supercategoryId');
      }
      
      // Verify restoration
      final restoredMobile = prefs.getString(_mobileKey);
      final restoredToken = prefs.getString(_tokenKey);
      final restoredUserId = prefs.getString(_userIdKey);
      final restoredSupercategoryId = prefs.getString(_supercategoryIdKey);
      
      debugPrint('Verification - Mobile restored: ${restoredMobile == mobile}');
      debugPrint('Verification - Token restored: ${restoredToken == token}');
      debugPrint('Verification - User ID restored: ${restoredUserId == userId}');
      debugPrint('Verification - Supercategory ID restored: ${restoredSupercategoryId == supercategoryId}');
      
      debugPrint('Cleared all saved data except token, user ID, mobile, and supercategory ID');
    } catch (e) {
      debugPrint('ERROR during clearDataExceptEssentials: $e');
    }
  }
  
  // Add a method to check if all auth data exists
  static Future<bool> isAuthDataComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final token = prefs.getString(_tokenKey);
      final userId = prefs.getString(_userIdKey);
      final mobile = prefs.getString(_mobileKey);
      final supercategoryId = prefs.getString(_supercategoryIdKey);
      
      final isComplete = token != null && token.isNotEmpty &&
                         userId != null && userId.isNotEmpty &&
                         mobile != null && mobile.isNotEmpty;
      
      debugPrint('Auth data check - Token: ${token != null && token.isNotEmpty}');
      debugPrint('Auth data check - User ID: ${userId != null && userId.isNotEmpty}');
      debugPrint('Auth data check - Mobile: ${mobile != null && mobile.isNotEmpty}');
      debugPrint('Auth data check - Supercategory ID: ${supercategoryId != null && supercategoryId.isNotEmpty}');
      debugPrint('Auth data is complete: $isComplete');
      
      return isComplete;
    } catch (e) {
      debugPrint('ERROR checking auth data: $e');
      return false;
    }
  }
}