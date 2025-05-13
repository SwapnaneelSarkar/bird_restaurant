// lib/presentation/screens/orders/event.dart
import 'package:equatable/equatable.dart';
import 'state.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadOrdersEvent extends OrdersEvent {}

class FilterOrdersEvent extends OrdersEvent {
  final OrderStatus status;
  
  const FilterOrdersEvent(this.status);
  
  @override
  List<Object?> get props => [status];
}

class UpdateOrderStatusEvent extends OrdersEvent {
  final String orderId;
  final OrderStatus newStatus;
  
  const UpdateOrderStatusEvent({
    required this.orderId,
    required this.newStatus,
  });
  
  @override
  List<Object?> get props => [orderId, newStatus];
}