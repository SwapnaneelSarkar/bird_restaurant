// lib/presentation/screens/orders/bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc() : super(OrdersInitial()) {
    on<LoadOrdersEvent>(_onLoadOrders);
    on<FilterOrdersEvent>(_onFilterOrders);
    on<UpdateOrderStatusEvent>(_onUpdateOrderStatus);
  }

  void _onLoadOrders(LoadOrdersEvent event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    
    try {
      // In a real app, this would be fetched from an API
      final orders = _getDummyOrders();
      final stats = _calculateStats(orders);
      
      emit(OrdersLoaded(
        orders: orders,
        stats: stats,
      ));
    } catch (e) {
      emit(OrdersError('Failed to load orders: ${e.toString()}'));
    }
  }

  void _onFilterOrders(FilterOrdersEvent event, Emitter<OrdersState> emit) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      List<Order> filteredOrders = currentState.orders;
      
      if (event.status != OrderStatus.all) {
        filteredOrders = currentState.orders
            .where((order) => order.status == event.status)
            .toList();
      }
      
      emit(currentState.copyWith(
        filterStatus: event.status,
      ));
    }
  }

  void _onUpdateOrderStatus(UpdateOrderStatusEvent event, Emitter<OrdersState> emit) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      
      // Update the order status
      final updatedOrders = currentState.orders.map((order) {
        if (order.id == event.orderId) {
          return Order(
            id: order.id,
            customerName: order.customerName,
            amount: order.amount,
            date: order.date,
            status: event.newStatus,
          );
        }
        return order;
      }).toList();
      
      // Recalculate stats
      final updatedStats = _calculateStats(updatedOrders);
      
      emit(currentState.copyWith(
        orders: updatedOrders,
        stats: updatedStats,
      ));
    }
  }

  List<Order> _getDummyOrders() {
    return [
      Order(
        id: '12345',
        customerName: 'James Anderson',
        amount: 500,
        date: DateTime(2025, 4, 26),
        status: OrderStatus.pending,
      ),
      Order(
        id: '12346',
        customerName: 'Emily Parker',
        amount: 750,
        date: DateTime(2025, 4, 26),
        status: OrderStatus.preparing,
      ),
      Order(
        id: '12347',
        customerName: 'Michael Thompson',
        amount: 1200,
        date: DateTime(2025, 4, 26),
        status: OrderStatus.delivery,
      ),
      // Add more dummy orders if needed
    ];
  }

  OrderStats _calculateStats(List<Order> orders) {
    int total = orders.length;
    int pending = orders.where((o) => o.status == OrderStatus.pending).length;
    int confirmed = orders.where((o) => o.status == OrderStatus.confirmed).length;
    int delivery = orders.where((o) => o.status == OrderStatus.delivery).length;
    int delivered = orders.where((o) => o.status == OrderStatus.delivered).length;
    int cancelled = orders.where((o) => o.status == OrderStatus.cancelled).length;
    int preparing = orders.where((o) => o.status == OrderStatus.preparing).length;
    
    return OrderStats(
      total: total,
      pending: pending,
      confirmed: confirmed,
      delivery: delivery,
      delivered: delivered,
      cancelled: cancelled,
      preparing: preparing,
    );
  }
}