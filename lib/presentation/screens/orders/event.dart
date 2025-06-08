// lib/presentation/screens/orders/event.dart
import '../../../constants/enums.dart';

abstract class OrdersEvent {
  const OrdersEvent();
}

class LoadOrdersEvent extends OrdersEvent {
  const LoadOrdersEvent();
}

class RefreshOrdersEvent extends OrdersEvent {
  const RefreshOrdersEvent();
}

class FilterOrdersEvent extends OrdersEvent {
  final OrderStatus status;
  
  const FilterOrdersEvent(this.status);
}

class UpdateOrderStatusEvent extends OrdersEvent {
  final String orderId;
  final OrderStatus newStatus;
  
  const UpdateOrderStatusEvent({
    required this.orderId,
    required this.newStatus,
  });
}