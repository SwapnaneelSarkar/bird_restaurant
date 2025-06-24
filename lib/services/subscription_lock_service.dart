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

  // Check if user has any plan or a pending plan (lock if no plan or pending, allow otherwise)
  static Future<bool> hasValidSubscription() async {
    try {
      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        debugPrint('No partner ID found, considering no valid subscription');
        return false;
      }

      final subscriptions = await SubscriptionPlansService.fetchVendorSubscriptions(partnerId);
      if (subscriptions.isEmpty) {
        debugPrint('No subscriptions found, lock the page');
        return false;
      }

      // Find the most recent subscription by start_date
      subscriptions.sort((a, b) {
        final aDate = a['start_date'] != null ? DateTime.parse(a['start_date']) : DateTime(1970);
        final bDate = b['start_date'] != null ? DateTime.parse(b['start_date']) : DateTime(1970);
        return bDate.compareTo(aDate); // descending
      });
      final mostRecent = subscriptions.first;
      final status = mostRecent['status']?.toString().toUpperCase() ?? 'UNKNOWN';
      debugPrint('hasValidSubscription: Most recent subscription status: $status');
      final result = status != 'PENDING';
      debugPrint('hasValidSubscription: returning $result');
      // Only lock if most recent is PENDING
      return result;
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

      final subscriptions = await SubscriptionPlansService.fetchVendorSubscriptions(partnerId);
      if (subscriptions.isEmpty) {
        return {
          'hasSubscription': false,
          'status': 'NO_SUBSCRIPTION',
          'message': 'No subscription found',
        };
      }
      subscriptions.sort((a, b) {
        final aDate = a['start_date'] != null ? DateTime.parse(a['start_date']) : DateTime(1970);
        final bDate = b['start_date'] != null ? DateTime.parse(b['start_date']) : DateTime(1970);
        return bDate.compareTo(aDate); // descending
      });
      final mostRecent = subscriptions.first;
      final status = mostRecent['status']?.toString().toUpperCase() ?? 'UNKNOWN';
      final planName = mostRecent['plan_name']?.toString() ?? 'Unknown Plan';
      final endDate = mostRecent['end_date']?.toString() ?? 'Unknown';
      if (status == 'PENDING') {
        return {
          'hasSubscription': true,
          'status': 'PENDING',
          'message': 'Subscription is pending approval',
          'planName': planName,
          'endDate': endDate,
        };
      } else {
        return {
          'hasSubscription': true,
          'status': status,
          'message': 'Subscription is $status',
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