import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/token_service.dart';
import '../models/plan_model.dart';
import 'api_exception.dart';

class SubscriptionPlansService {
  static const String _plansEndpoint = '/subscription/plans';
  static const String _vendorSubscriptionEndpoint = '/subscription/vendor';

  // Fetch all subscription plans
  static Future<List<PlanModel>> fetchSubscriptionPlans() async {
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        throw UnauthorizedException('No token found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_plansEndpoint');
      
      debugPrint('Fetching subscription plans from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Get Subscription Plans Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final List<dynamic> plansData = responseData['data'];
          return plansData.map((planData) => _parsePlanFromApi(planData)).toList();
        } else {
          throw ApiException(responseData['message'] ?? 'Failed to fetch subscription plans');
        }
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiException(responseData['message'] ?? 'Failed to fetch subscription plans');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ApiException) {
        rethrow;
      }
      debugPrint('Error fetching subscription plans: $e');
      throw ApiException('Failed to fetch subscription plans: $e');
    }
  }

  // Create vendor subscription
  static Future<Map<String, dynamic>> createVendorSubscription({
    required String partnerId,
    required String planId,
    required double amountPaid,
    required String paymentMethod,
  }) async {
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        throw UnauthorizedException('No token found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_vendorSubscriptionEndpoint');
      
      final requestBody = {
        'partner_id': partnerId,
        'plan_id': planId,
        'amount_paid': amountPaid,
        'payment_method': paymentMethod,
      };

      debugPrint('Creating vendor subscription at: $url');
      debugPrint('Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('Create Vendor Subscription Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS') {
          return responseData['data'] ?? {};
        } else {
          throw ApiException(responseData['message'] ?? 'Failed to create subscription');
        }
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiException(responseData['message'] ?? 'Failed to create subscription');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ApiException) {
        rethrow;
      }
      debugPrint('Error creating vendor subscription: $e');
      throw ApiException('Failed to create subscription: $e');
    }
  }

  // Parse plan data from API response to PlanModel
  static PlanModel _parsePlanFromApi(Map<String, dynamic> planData) {
    try {
      debugPrint('Parsing plan data: $planData');
      
      // Validate required fields
      if (planData['plan_id'] == null) {
        throw Exception('Plan ID is missing from API response');
      }
      if (planData['name'] == null) {
        throw Exception('Plan name is missing from API response');
      }
      if (planData['price'] == null) {
        throw Exception('Plan price is missing from API response');
      }
      
      final planId = planData['plan_id'].toString();
      final name = planData['name'].toString();
      final description = planData['description']?.toString() ?? '';
      final features = List<String>.from(planData['features'] ?? []);
      final price = double.tryParse(planData['price']?.toString() ?? '0') ?? 0.0;
      final isPopular = planData['is_popular'] == 1;
      final buttonText = 'Select $name';
      
      debugPrint('Successfully parsed plan: $name with ID: $planId');
      
      return PlanModel(
        id: planId,
        title: name,
        description: description,
        features: features,
        price: price,
        isPopular: isPopular,
        buttonText: buttonText,
      );
    } catch (e) {
      debugPrint('Error parsing plan data: $e');
      debugPrint('Plan data that caused error: $planData');
      rethrow;
    }
  }

  // Fetch vendor subscriptions
  static Future<List<Map<String, dynamic>>> fetchVendorSubscriptions(String partnerId) async {
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        throw UnauthorizedException('No token found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/subscription/vendor/$partnerId');
      
      debugPrint('Fetching vendor subscriptions from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Get Vendor Subscriptions Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final List<dynamic> subscriptionsData = responseData['data'];
          return subscriptionsData.cast<Map<String, dynamic>>();
        } else {
          throw ApiException(responseData['message'] ?? 'Failed to fetch vendor subscriptions');
        }
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access. Please login again.');
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiException(responseData['message'] ?? 'Failed to fetch vendor subscriptions');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ApiException) {
        rethrow;
      }
      debugPrint('Error fetching vendor subscriptions: $e');
      throw ApiException('Failed to fetch vendor subscriptions: $e');
    }
  }

  // Check if user has active subscription
  static Future<Map<String, dynamic>?> getActiveSubscription(String partnerId) async {
    try {
      final subscriptions = await fetchVendorSubscriptions(partnerId);
      
      if (subscriptions.isEmpty) {
        debugPrint('No subscriptions found for partner: $partnerId');
        return null;
      }

      final now = DateTime.now();
      Map<String, dynamic>? mostRecentActive = null;
      DateTime? mostRecentStartDate;
      DateTime? farthestEndDate;

      for (final subscription in subscriptions) {
        final status = subscription['status']?.toString().toUpperCase();
        final startDateStr = subscription['start_date']?.toString();
        final endDateStr = subscription['end_date']?.toString();

        // Check for both ACTIVE and PENDING subscriptions
        if ((status == 'ACTIVE' || status == 'PENDING') && startDateStr != null && endDateStr != null) {
          try {
            final startDate = DateTime.parse(startDateStr);
            final endDate = DateTime.parse(endDateStr);

            // For PENDING subscriptions, check if start date is in the future or today
            // For ACTIVE subscriptions, check if subscription is still valid (end date is in the future)
            bool isValid = false;
            if (status == 'PENDING') {
              // PENDING subscriptions are valid if start date is today or in the future
              isValid = startDate.isAfter(now.subtract(const Duration(days: 1)));
            } else {
              // ACTIVE subscriptions are valid if end date is in the future
              isValid = endDate.isAfter(now);
            }

            if (isValid) {
              // Check if this is the most recent subscription
              if (mostRecentActive == null || 
                  startDate.isAfter(mostRecentStartDate!) ||
                  (startDate.isAtSameMomentAs(mostRecentStartDate!) && endDate.isAfter(farthestEndDate!))) {
                mostRecentActive = subscription;
                mostRecentStartDate = startDate;
                farthestEndDate = endDate;
              }
            }
          } catch (e) {
            debugPrint('Error parsing dates for subscription ${subscription['subscription_id']}: $e');
          }
        }
      }

      if (mostRecentActive != null) {
        debugPrint('Found active/pending subscription: ${mostRecentActive['plan_name']} (ID: ${mostRecentActive['subscription_id']}) - Status: ${mostRecentActive['status']}');
        debugPrint('Start date: ${mostRecentActive['start_date']}, End date: ${mostRecentActive['end_date']}');
      } else {
        debugPrint('No active or pending subscription found for partner: $partnerId');
      }

      return mostRecentActive;
    } catch (e) {
      debugPrint('Error checking active subscription: $e');
      return null;
    }
  }

  // Check if user has valid subscription (active and not expired)
  static Future<bool> checkSubscriptionStatus() async {
    try {
      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        debugPrint('No partner ID found, considering no valid subscription');
        return false;
      }

      final activeSubscription = await getActiveSubscription(partnerId);
      return activeSubscription != null;
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  // Get subscription status for homepage reminder
  static Future<Map<String, dynamic>?> getSubscriptionStatusForReminder() async {
    try {
      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        return {'hasExpiredPlan': false, 'expiredPlanName': null, 'hasPendingSubscription': false};
      }

      final subscriptions = await fetchVendorSubscriptions(partnerId);
      
      if (subscriptions.isEmpty) {
        return {'hasExpiredPlan': false, 'expiredPlanName': null, 'hasPendingSubscription': false};
      }

      final now = DateTime.now();
      bool hasActiveSubscription = false;
      bool hasPendingSubscription = false;
      Map<String, dynamic>? mostRecentExpired = null;
      DateTime? mostRecentExpiredDate;
      Map<String, dynamic>? mostRecentPending = null;

      for (final subscription in subscriptions) {
        final status = subscription['status']?.toString().toUpperCase();
        final startDateStr = subscription['start_date']?.toString();
        final endDateStr = subscription['end_date']?.toString();

        if (status == 'PENDING' && startDateStr != null) {
          try {
            final startDate = DateTime.parse(startDateStr);
            // PENDING subscriptions are valid if start date is today or in the future
            if (startDate.isAfter(now.subtract(const Duration(days: 1)))) {
              hasPendingSubscription = true;
              // Keep track of the most recent pending subscription
              if (mostRecentPending == null || startDate.isAfter(DateTime.parse(mostRecentPending['start_date']!))) {
                mostRecentPending = subscription;
              }
            }
          } catch (e) {
            debugPrint('Error parsing start date for pending subscription ${subscription['subscription_id']}: $e');
          }
          continue; // Skip pending subscriptions for other logic
        }

        if (status == 'ACTIVE' && endDateStr != null) {
          try {
            final endDate = DateTime.parse(endDateStr);
            
            // Check if subscription is still valid (end date is in the future)
            if (endDate.isAfter(now)) {
              hasActiveSubscription = true;
              break; // Found an active subscription, no need to check further
            } else {
              // Check if this is the most recent expired subscription
              if (mostRecentExpired == null || endDate.isAfter(mostRecentExpiredDate!)) {
                mostRecentExpired = subscription;
                mostRecentExpiredDate = endDate;
              }
            }
          } catch (e) {
            debugPrint('Error parsing end date for subscription ${subscription['subscription_id']}: $e');
          }
        }
      }

      // If user has active subscription, don't show reminder
      if (hasActiveSubscription) {
        return {'hasExpiredPlan': false, 'expiredPlanName': null, 'hasPendingSubscription': false};
      }

      // If user has pending subscription, return pending status
      if (hasPendingSubscription) {
        return {
          'hasExpiredPlan': false, 
          'expiredPlanName': null, 
          'hasPendingSubscription': true,
          'pendingPlanName': mostRecentPending?['plan_name']?.toString(),
        };
      }

      // If user has expired plan, show reminder
      if (mostRecentExpired != null) {
        return {
          'hasExpiredPlan': true,
          'expiredPlanName': mostRecentExpired['plan_name']?.toString(),
          'hasPendingSubscription': false,
        };
      }

      // No active, pending, or expired plans found
      return {'hasExpiredPlan': false, 'expiredPlanName': null, 'hasPendingSubscription': false};
    } catch (e) {
      debugPrint('Error getting subscription status for reminder: $e');
      return null;
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  
  UnauthorizedException(this.message);
  
  @override
  String toString() => 'UnauthorizedException: $message';
} 