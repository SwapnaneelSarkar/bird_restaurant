// lib/presentation/screens/orders/bloc.dart - UPDATED FOR COMPLETE API INTEGRATION
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../constants/enums.dart';
import '../../../models/order_model.dart';
import '../../../services/orders_api_service.dart';
import '../../../services/order_service.dart';
import 'event.dart';
import 'state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc() : super(OrdersInitial()) {
    on<LoadOrdersEvent>(_onLoadOrders);
    on<FilterOrdersEvent>(_onFilterOrders);
    on<UpdateOrderStatusEvent>(_onUpdateOrderStatus);
    on<RefreshOrdersEvent>(_onRefreshOrders);
  }

  void _onLoadOrders(LoadOrdersEvent event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    
    try {
      debugPrint('OrdersBloc: 📋 Loading orders...');
      
      // Load order history
      final historyResponse = await OrdersApiService.fetchOrderHistory();
      
      debugPrint('OrdersBloc: 📋 Loaded ${historyResponse.data.length} orders');
      
      // Try to load order summary stats from API
      OrderStats stats;
      try {
        final summaryResponse = await OrdersApiService.fetchOrderSummary();
        if (summaryResponse.data != null) {
          // Use the new factory constructor to create stats from API response
          final Map<String, dynamic> apiData = {
            'total_orders': summaryResponse.data!.totalOrders,
            'total_pending': summaryResponse.data!.totalPending,
            'total_confirmed': summaryResponse.data!.totalConfirmed,
            'total_preparing': summaryResponse.data!.totalPreparing,
            'total_ready_for_delivery': summaryResponse.data!.totalReadyForDelivery,
            'total_out_for_delivery': summaryResponse.data!.totalOutForDelivery,
            'total_delivered': summaryResponse.data!.totalDelivered,
            'total_cancelled': summaryResponse.data!.totalCancelled,
          };
          
          stats = OrderStats.fromApiResponse(apiData);
          debugPrint('OrdersBloc: 📊 Loaded order stats from API: $stats');
        } else {
          stats = _calculateStatsFromOrders(historyResponse.data);
          debugPrint('OrdersBloc: 📊 Calculated order stats from order list');
        }
      } catch (e) {
        debugPrint('OrdersBloc: ⚠️ Failed to load stats from API: $e');
        stats = _calculateStatsFromOrders(historyResponse.data);
        debugPrint('OrdersBloc: 📊 Calculated order stats from order list (fallback)');
      }
      
      emit(OrdersLoaded(
        orders: historyResponse.data,
        stats: stats,
      ));
      
      debugPrint('OrdersBloc: ✅ Orders loaded successfully');
    } catch (e) {
      debugPrint('OrdersBloc: ❌ Error loading orders: $e');
      emit(OrdersError('Failed to load orders: ${e.toString()}'));
    }
  }

  void _onRefreshOrders(RefreshOrdersEvent event, Emitter<OrdersState> emit) async {
    // For refresh, we don't show loading state, just refresh in background
    try {
      debugPrint('OrdersBloc: 🔄 Refreshing orders...');
      
      // Load order history
      final historyResponse = await OrdersApiService.fetchOrderHistory();
      
      // Try to load order summary stats
      OrderStats stats;
      try {
        final summaryResponse = await OrdersApiService.fetchOrderSummary();
        if (summaryResponse.data != null) {
          // Use the new factory constructor to create stats from API response
          final Map<String, dynamic> apiData = {
            'total_orders': summaryResponse.data!.totalOrders,
            'total_pending': summaryResponse.data!.totalPending,
            'total_confirmed': summaryResponse.data!.totalConfirmed,
            'total_preparing': summaryResponse.data!.totalPreparing,
            'total_ready_for_delivery': summaryResponse.data!.totalReadyForDelivery,
            'total_out_for_delivery': summaryResponse.data!.totalOutForDelivery,
            'total_delivered': summaryResponse.data!.totalDelivered,
            'total_cancelled': summaryResponse.data!.totalCancelled,
          };
          
          stats = OrderStats.fromApiResponse(apiData);
        } else {
          stats = _calculateStatsFromOrders(historyResponse.data);
        }
      } catch (e) {
        stats = _calculateStatsFromOrders(historyResponse.data);
      }
      
      // Preserve the current filter status if orders are loaded
      OrderStatus currentFilter = OrderStatus.all;
      if (state is OrdersLoaded) {
        currentFilter = (state as OrdersLoaded).filterStatus;
      }
      
      emit(OrdersLoaded(
        orders: historyResponse.data,
        stats: stats,
        filterStatus: currentFilter,
      ));
      
      debugPrint('OrdersBloc: ✅ Orders refreshed successfully');
    } catch (e) {
      debugPrint('OrdersBloc: ❌ Error refreshing orders: $e');
      // Don't emit error state on refresh failure, just log it
      // This prevents disrupting the user experience
    }
  }

  OrderStats _calculateStatsFromOrders(List<Order> orders) {
    return OrderStats(
      total: orders.length,
      pending: orders.where((o) => o.orderStatus == OrderStatus.pending).length,
      confirmed: orders.where((o) => o.orderStatus == OrderStatus.confirmed).length,
      preparing: orders.where((o) => o.orderStatus == OrderStatus.preparing).length,
      readyForDelivery: orders.where((o) => o.orderStatus == OrderStatus.readyForDelivery).length,
      outForDelivery: orders.where((o) => o.orderStatus == OrderStatus.outForDelivery).length,
      delivered: orders.where((o) => o.orderStatus == OrderStatus.delivered).length,
      cancelled: orders.where((o) => o.orderStatus == OrderStatus.cancelled).length,
    );
  }

  void _onFilterOrders(FilterOrdersEvent event, Emitter<OrdersState> emit) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      emit(currentState.copyWith(filterStatus: event.status));
      debugPrint('OrdersBloc: 🔍 Filtered orders by ${event.status}');
    }
  }

    void _onUpdateOrderStatus(UpdateOrderStatusEvent event, Emitter<OrdersState> emit) async {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      
      debugPrint('OrdersBloc: 🔄 Updating order ${event.orderId} status to ${event.newStatus.displayName}');
      
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
          debugPrint('OrdersBloc: ✅ Order status updated successfully');
          // Reload orders to get updated data
          add(LoadOrdersEvent());
        } else {
          debugPrint('OrdersBloc: ❌ Failed to update order status');
          emit(OrdersError('Failed to update order status'));
        }
      } catch (e) {
        debugPrint('OrdersBloc: ❌ Error updating order status: $e');
        emit(OrdersError('Failed to update order status: ${e.toString()}'));
      }
    }
  }

  // Updated mapping function to handle new restricted statuses
  String _mapOrderStatusToString(OrderStatus status) {
    return status.apiValue;
  }

  // Helper function to map API string to OrderStatus enum
  OrderStatus _mapStringToOrderStatus(String status) {
    return OrderStatusExtension.fromApiValue(status);
  }
}