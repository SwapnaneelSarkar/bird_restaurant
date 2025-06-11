// lib/presentation/screens/reviews/view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class ReviewsView extends StatefulWidget {
  final String partnerId;
  final String? partnerName;

  const ReviewsView({
    super.key,
    required this.partnerId,
    this.partnerName,
  });

  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  late ScrollController _scrollController;
  String _currentSort = 'newest';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Load initial reviews
    context.read<ReviewBloc>().add(LoadReviews(
      partnerId: widget.partnerId,
      sort: _currentSort,
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      context.read<ReviewBloc>().add(const LoadMoreReviews());
    }
  }

  void _onRefresh() {
    context.read<ReviewBloc>().add(const RefreshReviews());
  }

  void _onSortChanged(String sort) {
    if (sort != _currentSort) {
      setState(() {
        _currentSort = sort;
      });
      context.read<ReviewBloc>().add(ChangeSort(sort));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.partnerName != null 
              ? '${widget.partnerName} Reviews' 
              : 'Reviews & Ratings',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            onSelected: _onSortChanged,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: _currentSort == 'newest' ? Colors.green : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Newest First',
                      style: TextStyle(
                        color: _currentSort == 'newest' ? Colors.green : Colors.white70,
                        fontWeight: _currentSort == 'newest' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: _currentSort == 'oldest' ? Colors.green : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Oldest First',
                      style: TextStyle(
                        color: _currentSort == 'oldest' ? Colors.green : Colors.white70,
                        fontWeight: _currentSort == 'oldest' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'highest',
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: _currentSort == 'highest' ? Colors.green : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Highest Rated',
                      style: TextStyle(
                        color: _currentSort == 'highest' ? Colors.green : Colors.white70,
                        fontWeight: _currentSort == 'highest' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'lowest',
                child: Row(
                  children: [
                    Icon(
                      Icons.star_border,
                      color: _currentSort == 'lowest' ? Colors.green : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Lowest Rated',
                      style: TextStyle(
                        color: _currentSort == 'lowest' ? Colors.green : Colors.white70,
                        fontWeight: _currentSort == 'lowest' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<ReviewBloc, ReviewState>(
        builder: (context, state) {
          if (state is ReviewLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
                strokeWidth: 2,
              ),
            );
          } else if (state is ReviewError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ReviewBloc>().add(LoadReviews(
                        partnerId: widget.partnerId,
                        sort: _currentSort,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is ReviewLoaded) {
            return RefreshIndicator(
              onRefresh: () async => _onRefresh(),
              backgroundColor: const Color(0xFF1A1A1A),
              color: Colors.green,
              child: Column(
                children: [
                  // Rating Summary Header
                  _buildRatingSummary(state),
                  
                  // Reviews List
                  Expanded(
                    child: state.reviews.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: state.reviews.length + (state.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= state.reviews.length) {
                                return _buildLoadingMoreIndicator(state.isLoadingMore);
                              }
                              return _buildReviewCard(state.reviews[index]);
                            },
                          ),
                  ),
                ],
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRatingSummary(ReviewLoaded state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Average Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Total Reviews
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.totalReviews} ${state.totalReviews == 1 ? 'Review' : 'Reviews'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on customer feedback',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (state.averageRating > 0) ...[
            const SizedBox(height: 16),
            _buildRatingBreakdown(state.averageRating),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingBreakdown(double averageRating) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= averageRating;
        final isHalfFilled = starValue > averageRating && starValue - 1 < averageRating;
        
        return Icon(
          isHalfFilled ? Icons.star_half : Icons.star,
          color: isFilled || isHalfFilled ? Colors.amber : Colors.white.withOpacity(0.3),
          size: 16,
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: Colors.white.withOpacity(0.3),
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'No Reviews Yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to leave a review for this partner',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user name, rating, and date
          Row(
            children: [
              // User avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    review.userName.isNotEmpty 
                        ? review.userName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // User name and rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Star rating
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star,
                              color: index < review.rating 
                                  ? Colors.amber 
                                  : Colors.white.withOpacity(0.3),
                              size: 14,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${review.rating}/5',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Time ago
              Text(
                review.timeAgo,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Review text
          if (review.reviewText.isNotEmpty) ...[
            Text(
              review.reviewText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Order ID (if available)
          if (review.orderId.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Order #${review.orderId.length > 8 ? review.orderId.substring(review.orderId.length - 8) : review.orderId}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(bool isLoadingMore) {
    if (!isLoadingMore) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.green,
          strokeWidth: 2,
        ),
      ),
    );
  }
}