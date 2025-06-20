// lib/presentation/screens/homePage/bloc.dart - Final version with model integration
// Add this import at the top:
// import '../../../models/partner_summary_model.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/token_service.dart';
import '../../../models/partner_summary_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'event.dart';
import 'state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiServices _apiServices = ApiServices();
  PartnerSummaryModel? partnerSummary;
  
  HomeBloc() : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<ToggleOrderAcceptance>(_onToggleOrderAcceptance);
  }

  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    
    try {
      // Initialize restaurant data as null
      Map<String, dynamic>? restaurantData;
      
      // Get mobile number from TokenService for restaurant details
      final mobile = await TokenService.getMobile();
      
      if (mobile != null) {
        try {
          debugPrint('Fetching restaurant details for mobile: $mobile');
          final response = await _apiServices.getDetailsByMobile(mobile);
          if (response.success && response.data != null) {
            restaurantData = response.data;
            debugPrint('Restaurant data fetched successfully from mobile API');
            debugPrint('Restaurant name: ${restaurantData?['restaurant_name']}');
            if (restaurantData?['restaurant_photos'] != null) {
              debugPrint('Restaurant photos available: ${restaurantData?['restaurant_photos']}');
              // Save restaurant image URL to SharedPreferences
              var photos = restaurantData?['restaurant_photos'];
              String? imageUrl;
              if (photos is List && photos.isNotEmpty) {
                var photoUrl = photos[0];
                if (photoUrl is String) {
                  imageUrl = photoUrl;
                }
              } else if (photos is String && photos.isNotEmpty) {
                try {
                  // Try to parse as JSON array
                  final parsed = (photos.startsWith('[')) ? List<String>.from((photos as String).isNotEmpty ? (photos as String).contains('[') ? (photos as String).contains(']') ? List<String>.from((photos as String).replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',')) : [photos as String] : [photos as String] : []) : [photos as String];
                  if (parsed.isNotEmpty) {
                    imageUrl = parsed[0].trim();
                  }
                } catch (e) {
                  debugPrint('Error parsing restaurant_photos string: $e');
                  imageUrl = photos;
                }
              }
              if (imageUrl != null && imageUrl.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('restaurant_image_url', imageUrl);
                debugPrint('Saved restaurant_image_url to SharedPreferences: $imageUrl');
                // Also cache name and slogan/address
                if (restaurantData?['restaurant_name'] != null) {
                  await prefs.setString('restaurant_name', restaurantData?['restaurant_name']?.toString() ?? '');
                  debugPrint('Saved restaurant_name to SharedPreferences: \\${restaurantData?['restaurant_name']}');
                }
                if (restaurantData?['address'] != null) {
                  await prefs.setString('restaurant_address', restaurantData?['address']?.toString() ?? '');
                  debugPrint('Saved restaurant_address to SharedPreferences: \\${restaurantData?['address']}');
                }
              }
            } else {
              debugPrint('No restaurant photos available in response');
            }
          } else {
            debugPrint('Failed to fetch restaurant data: ${response.message}');
          }
        } catch (apiError) {
          debugPrint('Error fetching restaurant data: $apiError');
          // Continue with null restaurant data if API call fails
        }
      } else {
        debugPrint('Mobile number is null, cannot fetch restaurant details');
      }

      // Fetch partner summary from the new API using the model
      try {
        debugPrint('Fetching partner summary data...');
        final summaryResponse = await _apiServices.getPartnerSummary();
        if (summaryResponse.success && summaryResponse.data != null) {
          partnerSummary = summaryResponse.data!;
          debugPrint('Partner summary data fetched successfully: $partnerSummary');
        } else {
          debugPrint('Failed to fetch partner summary: ${summaryResponse.message}');
        }
      } catch (summaryError) {
        debugPrint('Error fetching partner summary: $summaryError');
        // Will fall back to default values below
      }

      // Use API data if available, otherwise use default values
      final ordersCount = partnerSummary?.ordersCount ?? 0;
      final productsCount = partnerSummary?.productsCount ?? 0;
      final tagsCount = partnerSummary?.tagsCount ?? 0;
      final rating = partnerSummary?.rating ?? 0.0;
      final isAcceptingOrders = partnerSummary?.acceptingOrders ?? false;
      
      // Convert API sales data to the format expected by the UI
      List<Map<String, dynamic>> salesData = [];
      if (partnerSummary?.salesData != null && partnerSummary?.salesData.isNotEmpty == true) {
        salesData = partnerSummary!.salesData.map<Map<String, dynamic>>((salesPoint) {
          final dayName = _formatDateToDay(salesPoint.date);
          return {
            'day': dayName,
            'sales': salesPoint.sales,
          };
        }).toList();
        salesData.sort((a, b) {
          final dateA = _parseDate(partnerSummary!.salesData.firstWhere(
            (sp) => _formatDateToDay(sp.date) == a['day']
          ).date);
          final dateB = _parseDate(partnerSummary!.salesData.firstWhere(
            (sp) => _formatDateToDay(sp.date) == b['day']
          ).date);
          return dateA.compareTo(dateB);
        });
      } else {
        // Fallback sales data if API doesn't provide it
        salesData = [
          {'day': 'Mon', 'sales': 0},
          {'day': 'Tue', 'sales': 0},
          {'day': 'Wed', 'sales': 0},
          {'day': 'Thu', 'sales': 0},
          {'day': 'Fri', 'sales': 0},
          {'day': 'Sat', 'sales': 0},
          {'day': 'Sun', 'sales': 0},
        ];
        debugPrint('Using fallback sales data');
      }
      
      emit(HomeLoaded(
        isAcceptingOrders: isAcceptingOrders,
        ordersCount: ordersCount,
        productsCount: productsCount,
        tagsCount: tagsCount,
        rating: rating,
        salesData: salesData,
        restaurantData: restaurantData,
        partnerSummary: partnerSummary,
      ));
      
      debugPrint('Home data loaded successfully with API data:');
      debugPrint('- Orders: $ordersCount');
      debugPrint('- Products: $productsCount');
      debugPrint('- Tags: $tagsCount');
      debugPrint('- Rating: $rating');
      debugPrint('- Accepting Orders: $isAcceptingOrders');
      debugPrint('- Sales Data Points: ${salesData.length}');
    } catch (e) {
      debugPrint('Error in _onLoadHomeData: $e');
      emit(HomeError(message: 'Failed to load dashboard data'));
    }
  }

  void _onToggleOrderAcceptance(ToggleOrderAcceptance event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      
      // Get partner ID from restaurant data
      final partnerId = currentState.restaurantData?['partner_id'] as String?;
      
      if (partnerId == null || partnerId.isEmpty) {
        debugPrint('Error: Partner ID not found in restaurant data');
        return;
      }

      debugPrint('Updating order acceptance status:');
      debugPrint('Partner ID: $partnerId');
      debugPrint('Accepting Orders: ${event.isAccepting}');

      try {
        // Make API call to update order acceptance status
        final response = await _apiServices.updateOrderAcceptance(
          partnerId: partnerId,
          acceptingOrders: event.isAccepting,
        );

        if (response.success) {
          debugPrint('Successfully updated order acceptance status');
          emit(currentState.copyWith(isAcceptingOrders: event.isAccepting));
        } else {
          debugPrint('Failed to update order acceptance status: ${response.message}');
          // Revert the toggle if API call fails
          emit(currentState.copyWith(isAcceptingOrders: !event.isAccepting));
        }
      } catch (e) {
        debugPrint('Error updating order acceptance status: $e');
        // Revert the toggle if API call fails
        emit(currentState.copyWith(isAcceptingOrders: !event.isAccepting));
      }
    }
  }

  // Helper method to convert date string to day name
  String _formatDateToDay(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } catch (e) {
      debugPrint('Error parsing date $dateString: $e');
      return 'Day';
    }
  }

  // Helper method to parse date for sorting
  DateTime _parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      debugPrint('Error parsing date $dateString for sorting: $e');
      return DateTime.now();
    }
  }
}