// ENHANCED DEBUG VERSION: lib/constants/enums.dart
import 'package:flutter/foundation.dart';

enum OtpStatus { initial, validating, success, failure, unauthorized }

enum CuisineType {
  bakery,
  italian,
  chinese,
  indian,
  mexican,
  japanese,
  thai,
  american,
  french,
  mediterranean,
  korean,
  vietnamese,
}

// Updated OrderStatus enum with restricted statuses only
enum OrderStatus {
  all, // For filtering purposes only
  pending,
  confirmed,
  preparing,
  readyForDelivery,
  outForDelivery,
  delivered,
  cancelled,
}

// Extension to convert enum to string for API calls
extension OrderStatusExtension on OrderStatus {
  String get apiValue {
    switch (this) {
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.confirmed:
        return 'CONFIRMED';
      case OrderStatus.preparing:
        return 'PREPARING';
      case OrderStatus.readyForDelivery:
        return 'READY_FOR_DELIVERY';
      case OrderStatus.outForDelivery:
        return 'OUT_FOR_DELIVERY';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
      case OrderStatus.all:
        return 'ALL';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyForDelivery:
        return 'Ready for Delivery';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.all:
        return 'All Orders';
    }
  }

  // ENHANCED DEBUG: Convert string from API to enum with detailed logging
  static OrderStatus fromApiValue(String value) {
    debugPrint('OrderStatusExtension.fromApiValue: 🔍 Converting "$value" to enum');
    
    final upperValue = value.toUpperCase().trim();
    debugPrint('OrderStatusExtension.fromApiValue: 🔍 Cleaned value: "$upperValue"');
    
    switch (upperValue) {
      case 'PENDING':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched PENDING');
        return OrderStatus.pending;
      case 'CONFIRMED':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched CONFIRMED');
        return OrderStatus.confirmed;
      case 'PREPARING':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched PREPARING');
        return OrderStatus.preparing;
      case 'READY_FOR_DELIVERY':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched READY_FOR_DELIVERY');
        return OrderStatus.readyForDelivery;
      case 'OUT_FOR_DELIVERY':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched OUT_FOR_DELIVERY');
        return OrderStatus.outForDelivery;
      case 'DELIVERED':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched DELIVERED');
        return OrderStatus.delivered;
      case 'CANCELLED':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched CANCELLED');
        return OrderStatus.cancelled;
      
      // Add some common variations that might be in your API
      case 'CONFIRM':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched CONFIRM -> converting to CONFIRMED');
        return OrderStatus.confirmed;
      case 'PREPARE':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched PREPARE -> converting to PREPARING');
        return OrderStatus.preparing;
      case 'READY':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched READY -> converting to READY_FOR_DELIVERY');
        return OrderStatus.readyForDelivery;
      case 'OUT':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched OUT -> converting to OUT_FOR_DELIVERY');
        return OrderStatus.outForDelivery;
      case 'DELIVER':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched DELIVER -> converting to DELIVERED');
        return OrderStatus.delivered;
      case 'CANCEL':
        debugPrint('OrderStatusExtension.fromApiValue: ✅ Matched CANCEL -> converting to CANCELLED');
        return OrderStatus.cancelled;
      
      // Handle empty or null values
      case '':
      case 'NULL':
        debugPrint('OrderStatusExtension.fromApiValue: ⚠️ Empty or null value, defaulting to PENDING');
        return OrderStatus.pending;
        
      default:
        debugPrint('OrderStatusExtension.fromApiValue: ❌ UNRECOGNIZED STATUS: "$upperValue" - defaulting to PENDING');
        debugPrint('OrderStatusExtension.fromApiValue: ❌ This is likely the cause of all orders showing as PENDING!');
        debugPrint('OrderStatusExtension.fromApiValue: ❌ Please check your API response format');
        return OrderStatus.pending; // Default fallback
    }
  }
  
  // Helper method to get all possible status values (for debugging)
  static List<String> getAllValidApiValues() {
    return [
      'PENDING',
      'CONFIRMED', 
      'PREPARING',
      'READY_FOR_DELIVERY',
      'OUT_FOR_DELIVERY',
      'DELIVERED',
      'CANCELLED'
    ];
  }
  
  // Helper method to suggest what the API status might be
  static String suggestCorrectStatus(String apiStatus) {
    final upper = apiStatus.toUpperCase().trim();
    
    if (upper.contains('PEND')) return 'PENDING';
    if (upper.contains('CONF')) return 'CONFIRMED';
    if (upper.contains('PREP')) return 'PREPARING';
    if (upper.contains('READY')) return 'READY_FOR_DELIVERY';
    if (upper.contains('OUT') || upper.contains('DELIVERY')) return 'OUT_FOR_DELIVERY';
    if (upper.contains('DELIVER')) return 'DELIVERED';
    if (upper.contains('CANCEL')) return 'CANCELLED';
    
    return 'PENDING'; // Default
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

// Payment method enum
enum PaymentMethod {
  cash,
  card,
  upi,
  netBanking,
  wallet,
}

// Order type enum
enum OrderType {
  delivery,
  pickup,
  dineIn,
}