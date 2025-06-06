// lib/presentation/screens/orders/state.dart
import '../../../constants/enums.dart';
import '../../../models/order_model.dart';

abstract class OrdersState {}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  final OrderStats stats;
  final OrderStatus filterStatus;

  OrdersLoaded({
    required this.orders,
    required this.stats,
    this.filterStatus = OrderStatus.all,
  });

  List<Order> get filteredOrders {
    if (filterStatus == OrderStatus.all) return orders;
    return orders.where((order) => order.orderStatus == filterStatus).toList();
  }

  OrdersLoaded copyWith({
    List<Order>? orders,
    OrderStats? stats,
    OrderStatus? filterStatus,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      stats: stats ?? this.stats,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }
}

class OrdersError extends OrdersState {
  final String message;
  OrdersError(this.message);
}

class OrderStatusUpdating extends OrdersState {
  final String orderId;
  final OrderStatus newStatus;
  
  OrderStatusUpdating({
    required this.orderId,
    required this.newStatus,
  });
}

class OrderStats {
  final int total;
  final int pending;
  final int confirmed;
  final int preparing;
  final int delivery;
  final int delivered;
  final int cancelled;

  const OrderStats({
    required this.total,
    required this.pending,
    required this.confirmed,
    required this.preparing,
    required this.delivery,
    required this.delivered,
    required this.cancelled,
  });
}