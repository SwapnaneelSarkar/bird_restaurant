abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final bool isAcceptingOrders;
  final int ordersCount;
  final int productsCount;
  final int tagsCount;
  final double rating;
  final List<Map<String, dynamic>> salesData;

  HomeLoaded({
    required this.isAcceptingOrders,
    required this.ordersCount,
    required this.productsCount,
    required this.tagsCount,
    required this.rating,
    required this.salesData,
  });

  HomeLoaded copyWith({
    bool? isAcceptingOrders,
    int? ordersCount,
    int? productsCount,
    int? tagsCount,
    double? rating,
    List<Map<String, dynamic>>? salesData,
  }) {
    return HomeLoaded(
      isAcceptingOrders: isAcceptingOrders ?? this.isAcceptingOrders,
      ordersCount: ordersCount ?? this.ordersCount,
      productsCount: productsCount ?? this.productsCount,
      tagsCount: tagsCount ?? this.tagsCount,
      rating: rating ?? this.rating,
      salesData: salesData ?? this.salesData,
    );
  }
}

class HomeError extends HomeState {
  final String message;

  HomeError({required this.message});
}