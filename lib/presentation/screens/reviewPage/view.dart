// lib/presentation/screens/reviews/view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../../resources/router/router.dart';
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
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: ColorManager.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorManager.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.partnerName != null 
              ? '${widget.partnerName} Reviews' 
              : 'Reviews & Ratings',
          style: TextStyle(
            color: ColorManager.black,
            fontSize: FontSize.s18,
            fontWeight: FontWeightManager.semiBold,
            fontFamily: FontConstants.fontFamily,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: ColorManager.black),
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: _onSortChanged,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: _currentSort == 'newest' ? ColorManager.primary : ColorManager.textGrey,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Newest First',
                      style: TextStyle(
                        color: _currentSort == 'newest' ? ColorManager.primary : ColorManager.black,
                        fontWeight: _currentSort == 'newest' ? FontWeightManager.semiBold : FontWeightManager.medium,
                        fontSize: FontSize.s14,
                        fontFamily: FontFamily.Montserrat,
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
                      color: _currentSort == 'oldest' ? ColorManager.primary : ColorManager.textGrey,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Oldest First',
                      style: TextStyle(
                        color: _currentSort == 'oldest' ? ColorManager.primary : ColorManager.black,
                        fontWeight: _currentSort == 'oldest' ? FontWeightManager.semiBold : FontWeightManager.medium,
                        fontSize: FontSize.s14,
                        fontFamily: FontFamily.Montserrat,
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
                      color: _currentSort == 'highest' ? ColorManager.primary : ColorManager.textGrey,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Highest Rated',
                      style: TextStyle(
                        color: _currentSort == 'highest' ? ColorManager.primary : ColorManager.black,
                        fontWeight: _currentSort == 'highest' ? FontWeightManager.semiBold : FontWeightManager.medium,
                        fontSize: FontSize.s14,
                        fontFamily: FontFamily.Montserrat,
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
                      color: _currentSort == 'lowest' ? ColorManager.primary : ColorManager.textGrey,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Lowest Rated',
                      style: TextStyle(
                        color: _currentSort == 'lowest' ? ColorManager.primary : ColorManager.black,
                        fontWeight: _currentSort == 'lowest' ? FontWeightManager.semiBold : FontWeightManager.medium,
                        fontSize: FontSize.s14,
                        fontFamily: FontFamily.Montserrat,
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
            return Center(
              child: CircularProgressIndicator(
                color: ColorManager.primary,
                strokeWidth: 2.5,
              ),
            );
          } else if (state is ReviewError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ColorManager.signUpRed,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: ColorManager.textgrey2,
                        fontSize: FontSize.s16,
                        fontFamily: FontFamily.Montserrat,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 2,
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: FontSize.s14,
                        fontWeight: FontWeightManager.semiBold,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (state is ReviewLoaded) {
            return RefreshIndicator(
              onRefresh: () async => _onRefresh(),
              backgroundColor: Colors.white,
              color: ColorManager.primary,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Average Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorManager.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: ColorManager.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        color: ColorManager.primary,
                        fontSize: FontSize.s18,
                        fontWeight: FontWeightManager.bold,
                        fontFamily: FontConstants.fontFamily,
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
                      style: TextStyle(
                        color: ColorManager.black,
                        fontSize: FontSize.s16,
                        fontWeight: FontWeightManager.semiBold,
                        fontFamily: FontConstants.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on customer feedback',
                      style: TextStyle(
                        color: ColorManager.textGrey,
                        fontSize: FontSize.s12,
                        fontFamily: FontFamily.Montserrat,
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
          color: isFilled || isHalfFilled 
              ? const Color(0xFFFFC107) 
              : ColorManager.grey,
          size: 18,
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
            color: ColorManager.textGrey,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'No Reviews Yet',
            style: TextStyle(
              color: ColorManager.black,
              fontSize: FontSize.s20,
              fontWeight: FontWeightManager.semiBold,
              fontFamily: FontConstants.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to leave a review for this partner',
            style: TextStyle(
              color: ColorManager.textGrey,
              fontSize: FontSize.s14,
              fontFamily: FontFamily.Montserrat,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return GestureDetector(
      onTap: () {
        if (review.orderId.isNotEmpty) {
          Navigator.pushNamed(
            context, 
            Routes.restaurantOrderDetails, 
            arguments: review.orderId
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
          border: review.orderId.isNotEmpty 
              ? Border.all(
                  color: ColorManager.primary.withOpacity(0.1),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user name, rating, and date
            Row(
              children: [
                // User avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: ColorManager.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      review.userName.isNotEmpty 
                          ? review.userName[0].toUpperCase()
                          : 'A',
                      style: TextStyle(
                        color: ColorManager.primary,
                        fontSize: FontSize.s16,
                        fontWeight: FontWeightManager.bold,
                        fontFamily: FontConstants.fontFamily,
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
                        style: TextStyle(
                          color: ColorManager.black,
                          fontSize: FontSize.s16,
                          fontWeight: FontWeightManager.semiBold,
                          fontFamily: FontConstants.fontFamily,
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
                                    ? const Color(0xFFFFC107)
                                    : ColorManager.grey,
                                size: 16,
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${review.rating}/5',
                            style: TextStyle(
                              color: ColorManager.textGrey,
                              fontSize: FontSize.s12,
                              fontWeight: FontWeightManager.medium,
                              fontFamily: FontFamily.Montserrat,
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
                    color: ColorManager.textGrey,
                    fontSize: FontSize.s12,
                    fontFamily: FontFamily.Montserrat,
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
                  color: ColorManager.textgrey2,
                  fontSize: FontSize.s14,
                  height: 1.5,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Order ID (if available) with clickable indicator
            if (review.orderId.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ColorManager.cardGrey,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ColorManager.grey,
                        width: 1,
                      ),
                    ),
                    child:SizedBox(
  width: MediaQuery.of(context).size.width * 0.4,
  child: Text(
    'Order #${review.orderId}',
    style: TextStyle(
      color: ColorManager.textgrey2,
      fontSize: FontSize.s12,
      fontWeight: FontWeightManager.medium,
      fontFamily: FontFamily.Montserrat,
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
    softWrap: false,
  ),
)

                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: ColorManager.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'View Order',
                    style: TextStyle(
                      color: ColorManager.primary,
                      fontSize: FontSize.s12,
                      fontWeight: FontWeightManager.medium,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(bool isLoadingMore) {
    if (!isLoadingMore) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          color: ColorManager.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}