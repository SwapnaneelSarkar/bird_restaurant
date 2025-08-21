// lib/presentation/screens/orders/state.dart - UPDATED WITH STATUS UPDATE STATES

import '../../../constants/enums.dart';
import '../../../models/order_model.dart';

abstract class OrdersState {}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  final OrderStats stats;
  final OrderStatus filterStatus;
  final TodayOrderSummaryData? todaySummary;
  final bool filterByToday;

  OrdersLoaded({
    required this.orders,
    required this.stats,
    this.filterStatus = OrderStatus.all,
    this.todaySummary,
    this.filterByToday = false,
  });

  List<Order> get filteredOrders {
    List<Order> filteredList = orders;
    
    // Filter by today's date if filterByToday is true
    if (filterByToday) {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      filteredList = filteredList.where((order) {
        return order.date.isAfter(todayStart) && order.date.isBefore(todayEnd);
      }).toList();
    }
    
    // Filter by status if not showing all
    if (filterStatus != OrderStatus.all) {
      filteredList = filteredList.where((order) => order.orderStatus == filterStatus).toList();
    }
    
    return filteredList;
  }

  OrdersLoaded copyWith({
    List<Order>? orders,
    OrderStats? stats,
    OrderStatus? filterStatus,
    TodayOrderSummaryData? todaySummary,
    bool? filterByToday,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      stats: stats ?? this.stats,
      filterStatus: filterStatus ?? this.filterStatus,
      todaySummary: todaySummary ?? this.todaySummary,
      filterByToday: filterByToday ?? this.filterByToday,
    );
  }
}

class OrdersError extends OrdersState {
  final String message;
  OrdersError(this.message);
}

// UPDATED: Enhanced status update states
class OrderStatusUpdating extends OrdersState {
  final String orderId;
  final OrderStatus newStatus;
  
  OrderStatusUpdating({
    required this.orderId,
    required this.newStatus,
  });
}

// ADD: Success state for status updates
class OrderStatusUpdateSuccess extends OrdersState {
  final String orderId;
  final OrderStatus newStatus;
  final String message;
  
  OrderStatusUpdateSuccess({
    required this.orderId,
    required this.newStatus,
    required this.message,
  });
}

// ADD: Error state for status updates
class OrderStatusUpdateError extends OrdersState {
  final String orderId;
  final String message;
  
  OrderStatusUpdateError({
    required this.orderId,
    required this.message,
  });
}

// Updated OrderStats class to match API response exactly
class OrderStats {
  final int total;
  final int pending;
  final int confirmed;
  final int preparing;
  final int readyForDelivery;
  final int outForDelivery;
  final int delivered;
  final int cancelled;

  const OrderStats({
    required this.total,
    required this.pending,
    required this.confirmed,
    required this.preparing,
    required this.readyForDelivery,
    required this.outForDelivery,
    required this.delivered,
    required this.cancelled,
  });

  // Factory constructor to create from API response
  factory OrderStats.fromApiResponse(Map<String, dynamic> data) {
    return OrderStats(
      total: data['total_orders'] ?? 0,
      pending: data['total_pending'] ?? 0,
      confirmed: data['total_confirmed'] ?? 0,
      preparing: data['total_preparing'] ?? 0,
      readyForDelivery: data['total_ready_for_delivery'] ?? 0,
      outForDelivery: data['total_out_for_delivery'] ?? 0,
      delivered: data['total_delivered'] ?? 0,
      cancelled: data['total_cancelled'] ?? 0,
    );
  }

  // Helper method to get count by status
  int getCountByStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.all:
        return total;
      case OrderStatus.pending:
        return pending;
      case OrderStatus.confirmed:
        return confirmed;
      case OrderStatus.preparing:
        return preparing;
      case OrderStatus.readyForDelivery:
        return readyForDelivery;
      case OrderStatus.outForDelivery:
        return outForDelivery;
      case OrderStatus.delivered:
        return delivered;
      case OrderStatus.cancelled:
        return cancelled;
    }
  }

  // Create a copy with updated values
  OrderStats copyWith({
    int? total,
    int? pending,
    int? confirmed,
    int? preparing,
    int? readyForDelivery,
    int? outForDelivery,
    int? delivered,
    int? cancelled,
  }) {
    return OrderStats(
      total: total ?? this.total,
      pending: pending ?? this.pending,
      confirmed: confirmed ?? this.confirmed,
      preparing: preparing ?? this.preparing,
      readyForDelivery: readyForDelivery ?? this.readyForDelivery,
      outForDelivery: outForDelivery ?? this.outForDelivery,
      delivered: delivered ?? this.delivered,
      cancelled: cancelled ?? this.cancelled,
    );
  }

  @override
  String toString() {
    return 'OrderStats(total: $total, pending: $pending, confirmed: $confirmed, '
           'preparing: $preparing, readyForDelivery: $readyForDelivery, '
           'outForDelivery: $outForDelivery, delivered: $delivered, cancelled: $cancelled)';
  }
}