import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/token_service.dart';
import '../../../services/profile_update_service.dart';
import '../../../models/partner_summary_model.dart';
import '../../../utils/time_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'event.dart';
import 'state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiServices _apiServices = ApiServices();
  final ProfileUpdateService _profileUpdateService = ProfileUpdateService();
  PartnerSummaryModel? partnerSummary;
  bool _isLoading = false;
  StreamSubscription<ProfileUpdateEvent>? _profileUpdateSubscription;
  
  HomeBloc() : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<ToggleOrderAcceptance>(_onToggleOrderAcceptance);
    on<RefreshHomeData>(_onRefreshHomeData);
    
    // Listen for profile updates
    _profileUpdateSubscription = _profileUpdateService.profileUpdateStream.listen(
      (event) {
        debugPrint('🔄 HomeBloc: Received profile update - ${event.type}');
        add(RefreshHomeData());
      },
    );
  }

  @override
  Future<void> close() {
    _profileUpdateSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    if (_isLoading) {
      debugPrint('⚠️ LoadHomeData already in progress, skipping...');
      return;
    }
    
    _isLoading = true;
    emit(HomeLoading());
    
    try {
      Map<String, dynamic>? restaurantData;
      final mobile = await TokenService.getMobile();
      
      if (mobile != null) {
        try {
          final response = await _apiServices.getDetailsByMobile(mobile);
          if (response.success && response.data != null) {
            restaurantData = response.data;
            debugPrint('Restaurant data fetched successfully');
          }
        } catch (e) {
          debugPrint('Error fetching restaurant details: $e');
        }
      }

      final summaryResponse = await _apiServices.getPartnerSummary();
      if (summaryResponse.success && summaryResponse.data != null) {
        partnerSummary = summaryResponse.data!;
      }

      final ordersCount = partnerSummary?.ordersCount ?? 0;
      final productsCount = partnerSummary?.productsCount ?? 0;
      final tagsCount = partnerSummary?.tagsCount ?? 0;
      final rating = partnerSummary?.rating ?? 0.0;
      final isAcceptingOrders = partnerSummary?.acceptingOrders ?? false;
      
      List<Map<String, dynamic>> salesData = [];
      if (partnerSummary?.salesData != null && partnerSummary?.salesData.isNotEmpty == true) {
        // Convert sales data to list with proper date formatting and sort by date
        final sortedSalesData = List<SalesDataPoint>.from(partnerSummary!.salesData);
        sortedSalesData.sort((a, b) => _parseDate(a.date).compareTo(_parseDate(b.date)));
        
        salesData = sortedSalesData.map<Map<String, dynamic>>((salesPoint) {
          // Format date as MM/DD for better readability on graph
          final date = _parseDate(salesPoint.date);
          final formattedDate = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
          return {
            'day': formattedDate,
            'sales': salesPoint.sales,
          };
        }).toList();
        
        // Debug logging for sales data
        debugPrint('📊 Processed sales data for graph:');
        for (final data in salesData) {
          debugPrint('  - ${data['day']}: ${data['sales']} sales');
        }
      } else {
        salesData = [
          {'day': 'Mon', 'sales': 0},
          {'day': 'Tue', 'sales': 0},
          {'day': 'Wed', 'sales': 0},
          {'day': 'Thu', 'sales': 0},
          {'day': 'Fri', 'sales': 0},
          {'day': 'Sat', 'sales': 0},
          {'day': 'Sun', 'sales': 0},
        ];
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
    } catch (e) {
      debugPrint('Error in _onLoadHomeData: $e');
      emit(HomeError(message: 'Failed to load dashboard data'));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _onRefreshHomeData(RefreshHomeData event, Emitter<HomeState> emit) async {
    debugPrint('🔄 HomeBloc: Refreshing home data due to profile update');
    add(LoadHomeData());
  }

  void _onToggleOrderAcceptance(ToggleOrderAcceptance event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final partnerId = currentState.restaurantData?['partner_id'] as String?;
      
      if (partnerId == null || partnerId.isEmpty) {
        debugPrint('Error: Partner ID not found in restaurant data');
        return;
      }

      try {
        final response = await _apiServices.updateOrderAcceptance(
          partnerId: partnerId,
          acceptingOrders: event.isAccepting,
        );

        if (response.success) {
          emit(currentState.copyWith(isAcceptingOrders: event.isAccepting));
        } else {
          emit(currentState.copyWith(isAcceptingOrders: !event.isAccepting));
        }
      } catch (e) {
        emit(currentState.copyWith(isAcceptingOrders: !event.isAccepting));
      }
    }
  }

  String _formatDateToDay(String dateString) {
    return TimeUtils.formatDateToDay(dateString);
  }

  DateTime _parseDate(String dateString) {
    return TimeUtils.parseToIST(dateString);
  }
} 