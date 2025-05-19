import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/token_service.dart';

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
      
      // Get mobile number from TokenService
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
      
      // Mock data that would normally come from an API
      emit(HomeLoaded(
        isAcceptingOrders: false,
        ordersCount: 248,
        productsCount: 86,
        tagsCount: 12,
        rating: 4.8,
        salesData: [
          {'day': 'Mon', 'sales': 800},
          {'day': 'Tue', 'sales': 920},
          {'day': 'Wed', 'sales': 900},
          {'day': 'Thu', 'sales': 950},
          {'day': 'Fri', 'sales': 1250},
          {'day': 'Sat', 'sales': 1300},
          {'day': 'Sun', 'sales': 1290},
        ],
        restaurantData: restaurantData,
      ));
    } catch (e) {
      debugPrint('Error in _onLoadHomeData: $e');
      emit(HomeError(message: 'Failed to load dashboard data'));
    }
  }

  void _onToggleOrderAcceptance(ToggleOrderAcceptance event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(isAcceptingOrders: event.isAccepting));
    }
  }
}