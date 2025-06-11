// lib/presentation/screens/reviews/event.dart

import 'package:equatable/equatable.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class LoadReviews extends ReviewEvent {
  final String partnerId;
  final int page;
  final int limit;
  final String sort;

  const LoadReviews({
    required this.partnerId,
    this.page = 1,
    this.limit = 10,
    this.sort = 'newest',
  });

  @override
  List<Object?> get props => [partnerId, page, limit, sort];
}

class LoadMoreReviews extends ReviewEvent {
  const LoadMoreReviews();
}

class RefreshReviews extends ReviewEvent {
  const RefreshReviews();
}

class ChangeSort extends ReviewEvent {
  final String sort;

  const ChangeSort(this.sort);

  @override
  List<Object?> get props => [sort];
}