// lib/presentation/screens/orders/state.dart
import 'package:equatable/equatable.dart';

enum OrderStatus {
  all,
  pending,
  confirmed,
  delivery,
  delivered,
  cancelled,
  preparing
}

class Order {
  final String id;
  final String customerName;
  final double amount;
  final DateTime date;
  final OrderStatus status;

  const Order({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.status,
  });
}

class OrderStats {
  final int total;
  final int pending;
  final int confirmed;
  final int delivery;
  final int delivered;
  final int cancelled;
  final int preparing;

  OrderStats({
    this.total = 0,
    this.pending = 0,
    this.confirmed = 0,
    this.delivery = 0,
    this.delivered = 0,
    this.cancelled = 0,
    this.preparing = 0,
  });
}

abstract class OrdersState extends Equatable {
  const OrdersState();
  
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  final OrderStats stats;
  final OrderStatus filterStatus;

  const OrdersLoaded({
    required this.orders,
    required this.stats,
    this.filterStatus = OrderStatus.all,
  });
  
  @override
  List<Object?> get props => [orders, stats, filterStatus];
  
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
  
  const OrdersError(this.message);
  
  @override
  List<Object?> get props => [message];
}