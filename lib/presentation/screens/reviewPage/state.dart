// lib/presentation/screens/reviews/state.dart

import 'package:equatable/equatable.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewLoaded extends ReviewState {
  final List<Review> reviews;
  final double averageRating;
  final int totalReviews;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String currentSort;

  const ReviewLoaded({
    required this.reviews,
    required this.averageRating,
    required this.totalReviews,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.currentSort = 'newest',
  });

  ReviewLoaded copyWith({
    List<Review>? reviews,
    double? averageRating,
    int? totalReviews,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? currentSort,
  }) {
    return ReviewLoaded(
      reviews: reviews ?? this.reviews,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      currentSort: currentSort ?? this.currentSort,
    );
  }

  @override
  List<Object?> get props => [
        reviews,
        averageRating,
        totalReviews,
        currentPage,
        totalPages,
        hasMore,
        isLoadingMore,
        isRefreshing,
        currentSort,
      ];
}

class ReviewError extends ReviewState {
  final String message;

  const ReviewError(this.message);

  @override
  List<Object?> get props => [message];
}

// Review model
class Review {
  final String reviewId;
  final int rating;
  final String reviewText;
  final DateTime createdAt;
  final String orderId;
  final String userName;
  final String userId;

  Review({
    required this.reviewId,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    required this.orderId,
    required this.userName,
    required this.userId,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['review_id'] ?? '',
      rating: json['rating'] ?? 0,
      reviewText: json['review_text'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      orderId: json['order_id'] ?? '',
      userName: json['user_name'] ?? 'Anonymous',
      userId: json['user_id'] ?? '',
    );
  }

  // Helper method to get time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method for formatted date
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }
}