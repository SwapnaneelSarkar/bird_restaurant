class DeliveryPartner {
  final String deliveryPartnerId;
  final String name;
  final String phone;
  final String? email;
  final String? password;
  final String status;
  final String? vehicleType;
  final String? vehicleNumber;
  final double? currentLatitude;
  final double? currentLongitude;
  final int isAvailable;
  final String createdAt;
  final String updatedAt;
  final String? licensePhoto;
  final String? vehicleDocument;
  final String partnerId;

  DeliveryPartner({
    required this.deliveryPartnerId,
    required this.name,
    required this.phone,
    this.email,
    this.password,
    required this.status,
    this.vehicleType,
    this.vehicleNumber,
    this.currentLatitude,
    this.currentLongitude,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.licensePhoto,
    this.vehicleDocument,
    required this.partnerId,
  });

  factory DeliveryPartner.fromJson(Map<String, dynamic> json) {
    return DeliveryPartner(
      deliveryPartnerId: json['delivery_partner_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      password: json['password'],
      status: json['status'] ?? '',
      vehicleType: json['vehicle_type'],
      vehicleNumber: json['vehicle_number'],
      currentLatitude: json['current_latitude'] != null 
          ? double.tryParse(json['current_latitude'].toString()) 
          : null,
      currentLongitude: json['current_longitude'] != null 
          ? double.tryParse(json['current_longitude'].toString()) 
          : null,
      isAvailable: _convertToInt(json['is_available'] ?? 0),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      licensePhoto: json['license_photo'],
      vehicleDocument: json['vehicle_document'],
      partnerId: json['partner_id'] ?? '',
    );
  }

  // Helper method to safely convert various types to int
  static int _convertToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is String) {
      // Try parsing as int first
      final intValue = int.tryParse(value);
      if (intValue != null) return intValue;
      
      // Try parsing as bool string
      final lowerValue = value.toLowerCase().trim();
      return (lowerValue == 'true' || lowerValue == '1') ? 1 : 0;
    }
    return 0; // Default to 0 for unexpected types
  }

  Map<String, dynamic> toJson() {
    return {
      'delivery_partner_id': deliveryPartnerId,
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'status': status,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'is_available': isAvailable,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'license_photo': licensePhoto,
      'vehicle_document': vehicleDocument,
      'partner_id': partnerId,
    };
  }
}

class DeliveryPartnersResponse {
  final String status;
  final String message;
  final List<DeliveryPartner>? data;

  DeliveryPartnersResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory DeliveryPartnersResponse.fromJson(Map<String, dynamic> json) {
    List<DeliveryPartner>? partners;
    if (json['data'] != null) {
      partners = (json['data'] as List)
          .map((partner) => DeliveryPartner.fromJson(partner))
          .toList();
    }

    return DeliveryPartnersResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: partners,
    );
  }

  bool get success => status == 'SUCCESS';
} 