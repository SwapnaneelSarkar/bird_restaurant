// lib/constants/enums.dart

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

  // Convert string from API to enum
  static OrderStatus fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY_FOR_DELIVERY':
        return OrderStatus.readyForDelivery;
      case 'OUT_FOR_DELIVERY':
        return OrderStatus.outForDelivery;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending; // Default fallback
    }
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