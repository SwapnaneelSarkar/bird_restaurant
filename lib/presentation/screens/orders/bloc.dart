// lib/presentation/screens/orders/bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/enums.dart';
import '../../../models/order_model.dart';
import '../../../services/orders_api_service.dart';
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
      final historyResponse = await OrdersApiService.getOrderHistory(
        page: 1,
        limit: 50,
      );
      
      OrderStats stats;
      
      try {
        final dateRange = OrdersApiService.getThisMonthDateRange();
        final summaryResponse = await OrdersApiService.getOrderSummary(
          startDate: dateRange['startDate'],
          endDate: dateRange['endDate'],
        );
        
        if (summaryResponse.data != null) {
          stats = OrdersApiService.convertSummaryToStats(summaryResponse.data!);
        } else {
          stats = _calculateStatsFromOrders(historyResponse.data);
        }
      } catch (e) {
        stats = _calculateStatsFromOrders(historyResponse.data);
      }
      
      emit(OrdersLoaded(
        orders: historyResponse.data,
        stats: stats,
      ));
    } catch (e) {
      emit(OrdersError('Failed to load orders: ${e.toString()}'));
    }
  }

  OrderStats _calculateStatsFromOrders(List<Order> orders) {
    return OrderStats(
      total: orders.length,
      pending: orders.where((o) => o.orderStatus == OrderStatus.pending).length,
      confirmed: orders.where((o) => o.orderStatus == OrderStatus.confirmed).length,
      preparing: orders.where((o) => o.orderStatus == OrderStatus.preparing).length,
      delivery: orders.where((o) => o.orderStatus == OrderStatus.delivery).length,
      delivered: orders.where((o) => o.orderStatus == OrderStatus.delivered).length,
      cancelled: orders.where((o) => o.orderStatus == OrderStatus.cancelled).length,
    );
  }

  void _onFilterOrders(FilterOrdersEvent event, Emitter<OrdersState> emit) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      
      emit(currentState.copyWith(
        filterStatus: event.status,
      ));
    }
  }

  void _onUpdateOrderStatus(UpdateOrderStatusEvent event, Emitter<OrdersState> emit) async {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      
      emit(OrderStatusUpdating(
        orderId: event.orderId,
        newStatus: event.newStatus,
      ));
      
      try {
        final success = await OrdersApiService.updateOrderStatus(
          orderId: event.orderId,
          newStatus: _mapOrderStatusToString(event.newStatus),
        );
        
        if (success) {
          add(LoadOrdersEvent());
        } else {
          emit(OrdersError('Failed to update order status'));
        }
      } catch (e) {
        emit(OrdersError('Failed to update order status: ${e.toString()}'));
      }
    }
  }

  String _mapOrderStatusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.confirmed:
        return 'CONFIRMED';
      case OrderStatus.preparing:
        return 'PREPARING';
      case OrderStatus.delivery:
        return 'OUT_FOR_DELIVERY';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
      default:
        return 'PENDING';
    }
  }
}