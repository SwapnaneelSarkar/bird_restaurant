import 'dart:async';
import 'package:flutter/foundation.dart';
import 'restaurant_info_service.dart';

/// Service to handle real-time profile updates across the app
class ProfileUpdateService {
  static final ProfileUpdateService _instance = ProfileUpdateService._internal();
  factory ProfileUpdateService() => _instance;
  ProfileUpdateService._internal();

  // Stream controller for profile updates
  final StreamController<ProfileUpdateEvent> _profileUpdateController = 
      StreamController<ProfileUpdateEvent>.broadcast();

  // Stream for profile updates
  Stream<ProfileUpdateEvent> get profileUpdateStream => _profileUpdateController.stream;

  /// Notify that profile has been updated
  void notifyProfileUpdated({
    required String updateType,
    Map<String, dynamic>? updatedData,
  }) {
    debugPrint('🔄 ProfileUpdateService: Notifying profile update - $updateType');
    _profileUpdateController.add(ProfileUpdateEvent(
      type: updateType,
      data: updatedData,
      timestamp: DateTime.now(),
    ));
  }

  /// Notify that restaurant details have been updated
  void notifyRestaurantDetailsUpdated(Map<String, dynamic>? updatedData) {
    notifyProfileUpdated(
      updateType: 'restaurant_details',
      updatedData: updatedData,
    );
    
    // Also update restaurant info service
    if (updatedData != null) {
      RestaurantInfoService.updateRestaurantInfo(
        name: updatedData['restaurant_name'],
        slogan: updatedData['address'],
      );
    }
  }

  /// Notify that restaurant image has been updated
  void notifyRestaurantImageUpdated(String? imageUrl) {
    notifyProfileUpdated(
      updateType: 'restaurant_image',
      updatedData: {'imageUrl': imageUrl},
    );
    
    // Also update restaurant info service
    if (imageUrl != null) {
      RestaurantInfoService.updateRestaurantInfo(imageUrl: imageUrl);
    }
  }

  /// Notify that operational hours have been updated
  void notifyOperationalHoursUpdated(Map<String, dynamic>? hoursData) {
    notifyProfileUpdated(
      updateType: 'operational_hours',
      updatedData: hoursData,
    );
  }

  /// Notify that restaurant type has been updated
  void notifyRestaurantTypeUpdated(String? restaurantType) {
    notifyProfileUpdated(
      updateType: 'restaurant_type',
      updatedData: {'restaurantType': restaurantType},
    );
  }

  /// Dispose the service
  void dispose() {
    _profileUpdateController.close();
  }
}

/// Event class for profile updates
class ProfileUpdateEvent {
  final String type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  ProfileUpdateEvent({
    required this.type,
    this.data,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'ProfileUpdateEvent(type: $type, data: $data, timestamp: $timestamp)';
  }
} 