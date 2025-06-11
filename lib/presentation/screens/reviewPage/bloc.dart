// lib/presentation/screens/reviews/bloc.dart

import 'dart:async';
import 'dart:convert';
import 'package:bird_restaurant/constants/api_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../services/token_service.dart';
import 'event.dart';
import 'state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  String? _currentPartnerId;
  List<Review> _allReviews = [];
  
  // API Constants - following your project's pattern
  static const String baseUrl = ApiConstants.baseUrl;
  
  ReviewBloc() : super(ReviewInitial()) {
    on<LoadReviews>(_onLoadReviews);
    on<LoadMoreReviews>(_onLoadMoreReviews);
    on<RefreshReviews>(_onRefreshReviews);
    on<ChangeSort>(_onChangeSort);
  }

  Future<void> _onLoadReviews(LoadReviews event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    
    try {
      _currentPartnerId = event.partnerId;
      
      // Debug: Check if partnerId is provided
      if (event.partnerId.isEmpty) {
        debugPrint('ReviewBloc: ❌ ERROR - Partner ID is empty!');
        emit(const ReviewError('Partner ID is required to load reviews'));
        return;
      }
      
      debugPrint('ReviewBloc: 📋 Loading reviews for partner: ${event.partnerId}');
      
      final response = await _fetchReviews(
        partnerId: event.partnerId,
        page: event.page,
        limit: event.limit,
        sort: event.sort,
      );

      if (response != null) {
        _allReviews = response['reviews'];
        
        emit(ReviewLoaded(
          reviews: response['reviews'],
          averageRating: response['averageRating'],
          totalReviews: response['total'],
          currentPage: response['currentPage'],
          totalPages: response['totalPages'],
          hasMore: response['currentPage'] < response['totalPages'],
          currentSort: event.sort,
        ));
        
        debugPrint('ReviewBloc: ✅ Reviews loaded successfully');
        debugPrint('  - Total reviews: ${response['total']}');
        debugPrint('  - Average rating: ${response['averageRating']}');
        debugPrint('  - Current page: ${response['currentPage']}/${response['totalPages']}');
      } else {
        emit(const ReviewError('Failed to load reviews'));
      }
    } catch (e) {
      debugPrint('ReviewBloc: ❌ Error loading reviews: $e');
      emit(const ReviewError('Failed to load reviews. Please try again.'));
    }
  }

  Future<void> _onLoadMoreReviews(LoadMoreReviews event, Emitter<ReviewState> emit) async {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      
      if (!currentState.hasMore || currentState.isLoadingMore) {
        return; // No more data to load or already loading
      }

      emit(currentState.copyWith(isLoadingMore: true));

      try {
        final response = await _fetchReviews(
          partnerId: _currentPartnerId!,
          page: currentState.currentPage + 1,
          limit: 10,
          sort: currentState.currentSort,
        );

        if (response != null) {
          final List<Review> newReviews = [..._allReviews, ...response['reviews']];
          _allReviews = newReviews;

          emit(currentState.copyWith(
            reviews: newReviews,
            currentPage: response['currentPage'],
            hasMore: response['currentPage'] < response['totalPages'],
            isLoadingMore: false,
          ));
          
          debugPrint('ReviewBloc: ✅ More reviews loaded');
          debugPrint('  - New page: ${response['currentPage']}/${response['totalPages']}');
          debugPrint('  - Total reviews in list: ${newReviews.length}');
        } else {
          emit(currentState.copyWith(isLoadingMore: false));
          // Could show a snackbar here for load more error
        }
      } catch (e) {
        debugPrint('ReviewBloc: ❌ Error loading more reviews: $e');
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _onRefreshReviews(RefreshReviews event, Emitter<ReviewState> emit) async {
    if (state is ReviewLoaded && _currentPartnerId != null) {
      final currentState = state as ReviewLoaded;
      emit(currentState.copyWith(isRefreshing: true));

      try {
        final response = await _fetchReviews(
          partnerId: _currentPartnerId!,
          page: 1,
          limit: 10,
          sort: currentState.currentSort,
        );

        if (response != null) {
          _allReviews = response['reviews'];

          emit(currentState.copyWith(
            reviews: response['reviews'],
            averageRating: response['averageRating'],
            totalReviews: response['total'],
            currentPage: response['currentPage'],
            totalPages: response['totalPages'],
            hasMore: response['currentPage'] < response['totalPages'],
            isRefreshing: false,
          ));
          
          debugPrint('ReviewBloc: ✅ Reviews refreshed successfully');
        } else {
          emit(currentState.copyWith(isRefreshing: false));
        }
      } catch (e) {
        debugPrint('ReviewBloc: ❌ Error refreshing reviews: $e');
        emit(currentState.copyWith(isRefreshing: false));
      }
    }
  }

  Future<void> _onChangeSort(ChangeSort event, Emitter<ReviewState> emit) async {
    if (state is ReviewLoaded && _currentPartnerId != null) {
      final currentState = state as ReviewLoaded;
      
      if (currentState.currentSort == event.sort) {
        return; // Same sort, no need to reload
      }

      emit(ReviewLoading());

      try {
        final response = await _fetchReviews(
          partnerId: _currentPartnerId!,
          page: 1,
          limit: 10,
          sort: event.sort,
        );

        if (response != null) {
          _allReviews = response['reviews'];

          emit(ReviewLoaded(
            reviews: response['reviews'],
            averageRating: response['averageRating'],
            totalReviews: response['total'],
            currentPage: response['currentPage'],
            totalPages: response['totalPages'],
            hasMore: response['currentPage'] < response['totalPages'],
            currentSort: event.sort,
          ));
          
          debugPrint('ReviewBloc: ✅ Reviews sorted by ${event.sort}');
        } else {
          emit(const ReviewError('Failed to sort reviews'));
        }
      } catch (e) {
        debugPrint('ReviewBloc: ❌ Error sorting reviews: $e');
        emit(const ReviewError('Failed to sort reviews. Please try again.'));
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchReviews({
    required String partnerId,
    required int page,
    required int limit,
    required String sort,
  }) async {
    try {
      // Get auth token
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Construct API URL - using ApiConstant pattern from your project
      final url = Uri.parse('$baseUrl/user/reviews/partner/$partnerId?page=$page&limit=$limit&sort=$sort');
      
      debugPrint('ReviewBloc: 🌐 Fetching reviews from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('ReviewBloc: 📡 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Parse the response according to the provided API structure
        final List<dynamic> reviewsJson = data['reviews'] ?? [];
        final List<Review> reviews = reviewsJson
            .map((review) => Review.fromJson(review))
            .toList();

        return {
          'reviews': reviews,
          'total': data['total'] ?? 0,
          'averageRating': double.tryParse(data['average_rating']?.toString() ?? '0') ?? 0.0,
          'currentPage': data['current_page'] ?? page,
          'totalPages': data['total_pages'] ?? 1,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Partner not found.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ReviewBloc: ❌ Network error: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() {
    debugPrint('ReviewBloc: 🗑️ Closing and cleaning up resources');
    return super.close();
  }
}