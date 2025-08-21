// lib/presentation/screens/orders/bloc.dart - UPDATED WITH BETTER ERROR HANDLING

import 'dart:convert';

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

  Future<void> _onLoadOrders(LoadOrdersEvent event, Emitter<OrdersState> emit) async {
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
      
      // Try to load today's summary
      TodayOrderSummaryData? todaySummary;
      try {
        final todaySummaryResponse = await OrdersApiService.fetchTodayOrderSummary();
        if (todaySummaryResponse.data != null) {
          todaySummary = todaySummaryResponse.data;
          debugPrint('OrdersBloc: 📊 Loaded today\'s summary from API');
        }
      } catch (e) {
        debugPrint('OrdersBloc: ⚠️ Failed to load today\'s summary from API: $e');
      }
      
      emit(OrdersLoaded(
        orders: historyResponse.data,
        stats: stats,
        todaySummary: todaySummary,
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
      
      // Try to load today's summary
      TodayOrderSummaryData? todaySummary;
      try {
        final todaySummaryResponse = await OrdersApiService.fetchTodayOrderSummary();
        if (todaySummaryResponse.data != null) {
          todaySummary = todaySummaryResponse.data;
        }
      } catch (e) {
        debugPrint('OrdersBloc: ⚠️ Failed to load today\'s summary from API: $e');
      }
      
      // Preserve the current filter status and today's filter if orders are loaded
      OrderStatus currentFilter = OrderStatus.all;
      bool currentFilterByToday = false;
      if (state is OrdersLoaded) {
        currentFilter = (state as OrdersLoaded).filterStatus;
        currentFilterByToday = (state as OrdersLoaded).filterByToday;
      }
      
      emit(OrdersLoaded(
        orders: historyResponse.data,
        stats: stats,
        filterStatus: currentFilter,
        todaySummary: todaySummary,
        filterByToday: currentFilterByToday,
      ));
      
      debugPrint('OrdersBloc: ✅ Orders refreshed successfully');
    } catch (e) {
      debugPrint('OrdersBloc: ❌ Error refreshing orders: $e');
      // Don't emit error state for refresh, just log the error
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
      emit(currentState.copyWith(
        filterStatus: event.status,
        filterByToday: event.filterByToday,
      ));
      debugPrint('OrdersBloc: 🔍 Filtered orders by ${event.status}${event.filterByToday ? ' (Today only)' : ''}');
    }
  }

  // UPDATED: Better error handling for status updates with page reload
  void _onUpdateOrderStatus(UpdateOrderStatusEvent event, Emitter<OrdersState> emit) async {
    debugPrint('OrdersBloc: 🎯 _onUpdateOrderStatus called');
    debugPrint('OrdersBloc: 🎯 Event orderId: ${event.orderId}');
    debugPrint('OrdersBloc: 🎯 Event newStatus: ${event.newStatus.apiValue}');
    debugPrint('OrdersBloc: 🎯 Current state: ${state.runtimeType}');
    
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      
      debugPrint('OrdersBloc: 🔄 Updating order ${event.orderId} status to ${event.newStatus.displayName}');
      
      emit(OrderStatusUpdating(
        orderId: event.orderId,
        newStatus: event.newStatus,
      ));
      
      try {
        debugPrint('OrdersBloc: 📞 Calling OrdersApiService.updateOrderStatus');
        final success = await OrdersApiService.updateOrderStatus(
          orderId: event.orderId,
          newStatus: _mapOrderStatusToString(event.newStatus),
        );
        
        debugPrint('OrdersBloc: 📞 OrdersApiService.updateOrderStatus result: $success');
        
        if (success) {
          debugPrint('OrdersBloc: ✅ Order status updated successfully');
          
          // Show success state briefly before reloading
          emit(OrderStatusUpdateSuccess(
            orderId: event.orderId,
            newStatus: event.newStatus,
            message: 'Order status updated to ${event.newStatus.displayName} successfully!',
          ));
          
          // Wait a moment, then reload orders to get updated data
          await Future.delayed(const Duration(milliseconds: 1000));
          add(LoadOrdersEvent());
          
        } else {
          debugPrint('OrdersBloc: ❌ Failed to update order status');
          
          // Show error state briefly
          emit(OrderStatusUpdateError(
            orderId: event.orderId,
            message: 'Failed to update order status. Please try again.',
          ));
          
          // ADDED: Also reload orders after error to refresh the page
          await Future.delayed(const Duration(milliseconds: 1500));
          add(LoadOrdersEvent());
        }
      } catch (e) {
        debugPrint('OrdersBloc: ❌ Error updating order status: $e');
        debugPrint('OrdersBloc: ❌ Error stack trace: ${StackTrace.current}');
        
        // Parse error message from exception
        String errorMessage = 'Failed to update order status. Please try again.';
        try {
          if (e.toString().contains('"status":"ERROR"')) {
            // Extract JSON from exception message
            final startIndex = e.toString().indexOf('{');
            if (startIndex != -1) {
              final jsonStr = e.toString().substring(startIndex);
              final errorJson = jsonDecode(jsonStr);
              errorMessage = errorJson['message'] ?? errorMessage;
            }
          } else if (e.toString().contains('Cannot update status')) {
            // Extract the actual error message from API
            final match = RegExp(r'"message":"([^"]*)"').firstMatch(e.toString());
            if (match != null) {
              errorMessage = match.group(1) ?? errorMessage;
            }
          } else if (e.toString().contains('Invalid request')) {
            errorMessage = 'Invalid status transition. Please check the current order status.';
          } else if (e.toString().contains('Server error')) {
            errorMessage = 'Server error occurred. Please try again later.';
          }
        } catch (parseError) {
          debugPrint('OrdersBloc: Could not parse error details: $parseError');
        }
        
        // Show error state
        emit(OrderStatusUpdateError(
          orderId: event.orderId,
          message: errorMessage,
        ));
        
        // ADDED: Reload orders after error to refresh the page
        await Future.delayed(const Duration(milliseconds: 1500));
        add(LoadOrdersEvent());
      }
    } else {
      debugPrint('OrdersBloc: ❌ Cannot update order status - current state is not OrdersLoaded');
      debugPrint('OrdersBloc: ❌ Current state: ${state.runtimeType}');
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