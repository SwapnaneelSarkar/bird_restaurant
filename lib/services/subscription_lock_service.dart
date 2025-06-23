import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'subscription_plans_service.dart';
import 'token_service.dart';

class SubscriptionLockService {
  // Define which pages require subscription
  static const Map<String, bool> _pageSubscriptionRequirements = {
    '/orders': true,
    '/editMenu': true,
    '/addProduct': true,
    '/attributes': true,
    '/chat': true,
    '/chatList': true,
    '/reviews': true,
    '/home': false, // Home page doesn't require subscription
    '/profile': false, // Profile page doesn't require subscription
    '/plan': false, // Plans page doesn't require subscription
    '/privacy': false, // Legal pages don't require subscription
    '/terms': false,
    '/contact': false,
  };

  // Check if a page requires subscription
  static bool requiresSubscription(String routeName) {
    return _pageSubscriptionRequirements[routeName] ?? false;
  }

  // Check if user has valid subscription (ONLY ACTIVE, not PENDING)
  static Future<bool> hasValidSubscription() async {
    try {
      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        debugPrint('No partner ID found, considering no valid subscription');
        return false;
      }

      final activeSubscription = await SubscriptionPlansService.getActiveSubscription(partnerId);
      
      // Only ACTIVE subscriptions are considered valid for access
      if (activeSubscription != null) {
        final status = activeSubscription['status']?.toString().toUpperCase() ?? 'UNKNOWN';
        debugPrint('Subscription status: $status');
        
        // Only ACTIVE subscriptions allow access
        return status == 'ACTIVE';
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  // Check if user can access a specific page
  static Future<bool> canAccessPage(String routeName) async {
    if (!requiresSubscription(routeName)) {
      return true; // Page doesn't require subscription
    }

    return await hasValidSubscription();
  }

  // Get subscription status for UI display
  static Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        return {
          'hasSubscription': false,
          'status': 'NO_PARTNER_ID',
          'message': 'Please login again',
        };
      }

      final activeSubscription = await SubscriptionPlansService.getActiveSubscription(partnerId);
      
      if (activeSubscription == null) {
        return {
          'hasSubscription': false,
          'status': 'NO_SUBSCRIPTION',
          'message': 'No active subscription found',
        };
      }

      final status = activeSubscription['status']?.toString().toUpperCase() ?? 'UNKNOWN';
      final planName = activeSubscription['plan_name']?.toString() ?? 'Unknown Plan';
      final endDate = activeSubscription['end_date']?.toString() ?? 'Unknown';

      if (status == 'PENDING') {
        return {
          'hasSubscription': true,
          'status': 'PENDING',
          'message': 'Subscription is pending approval',
          'planName': planName,
          'endDate': endDate,
        };
      } else if (status == 'ACTIVE') {
        return {
          'hasSubscription': true,
          'status': 'ACTIVE',
          'message': 'Subscription is active',
          'planName': planName,
          'endDate': endDate,
        };
      } else {
        return {
          'hasSubscription': false,
          'status': 'INACTIVE',
          'message': 'Subscription is not active',
          'planName': planName,
          'endDate': endDate,
        };
      }
    } catch (e) {
      debugPrint('Error getting subscription status: $e');
      return {
        'hasSubscription': false,
        'status': 'ERROR',
        'message': 'Error checking subscription status',
      };
    }
  }
} 