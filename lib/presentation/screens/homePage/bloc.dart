// lib/presentation/screens/homePage/bloc.dart - Final version with model integration
// Add this import at the top:
// import '../../../models/partner_summary_model.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/token_service.dart';
import '../../../models/partner_summary_model.dart';

import 'event.dart';
import 'state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiServices _apiServices = ApiServices();
  
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
      PartnerSummaryModel? summaryData;
      try {
        debugPrint('Fetching partner summary data...');
        final summaryResponse = await _apiServices.getPartnerSummary();
        if (summaryResponse.success && summaryResponse.data != null) {
          summaryData = summaryResponse.data!;
          debugPrint('Partner summary data fetched successfully: $summaryData');
        } else {
          debugPrint('Failed to fetch partner summary: ${summaryResponse.message}');
        }
      } catch (summaryError) {
        debugPrint('Error fetching partner summary: $summaryError');
        // Will fall back to default values below
      }

      // Use API data if available, otherwise use default values
      final ordersCount = summaryData?.ordersCount ?? 0;
      final productsCount = summaryData?.productsCount ?? 0;
      final tagsCount = summaryData?.tagsCount ?? 0;
      final rating = summaryData?.rating ?? 0.0;
      final isAcceptingOrders = summaryData?.acceptingOrders ?? false;
      
      // Convert API sales data to the format expected by the UI
      List<Map<String, dynamic>> salesData = [];
      if (summaryData?.salesData != null && summaryData!.salesData.isNotEmpty) {
        // Transform the API format to UI format
        salesData = summaryData.salesData.map<Map<String, dynamic>>((salesPoint) {
          // Convert date to day name for chart display
          final dayName = _formatDateToDay(salesPoint.date);
          
          return {
            'day': dayName,
            'sales': salesPoint.sales,
          };
        }).toList();
        
        debugPrint('Converted ${salesData.length} sales data points for chart');
        
        // Sort by date to ensure proper order
        salesData.sort((a, b) {
          final dateA = _parseDate(summaryData!.salesData.firstWhere(
            (sp) => _formatDateToDay(sp.date) == a['day']
          ).date);
          final dateB = _parseDate(summaryData.salesData.firstWhere(
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

  void _onToggleOrderAcceptance(ToggleOrderAcceptance event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(isAcceptingOrders: event.isAccepting));
      
      // Note: In a real implementation, you might want to call an API here
      // to persist the order acceptance status change
      debugPrint('Order acceptance toggled to: ${event.isAccepting}');
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