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
enum OrderStatus {
  all,
  pending,
  confirmed,
  preparing,
  delivery,
  delivered,
  cancelled,
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