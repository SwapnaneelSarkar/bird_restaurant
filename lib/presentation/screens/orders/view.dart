// lib/presentation/screens/orders/view.dart - UPDATED WITH ALL STATS
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/order_model.dart';
import '../../../ui_components/order_card.dart';
import '../../../ui_components/order_stats_card.dart';
import '../../../ui_components/universal_widget/topbar.dart';
import '../../../ui_components/universal_widget/order_widgets.dart';
import '../../../constants/enums.dart';
import '../../../services/order_service.dart';

import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersBloc()..add(LoadOrdersEvent()),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Column(
            children: [
              const AppBackHeader(title: 'Orders'),
              Expanded(
                child: BlocConsumer<OrdersBloc, OrdersState>(
                  listener: (context, state) {
                    if (state is OrderStatusUpdating) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updating order ${state.orderId}...'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is OrdersLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is OrdersLoaded) {
                      return _buildOrdersContent(context, state);
                    } else if (state is OrdersError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.message, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.read<OrdersBloc>().add(LoadOrdersEvent()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersContent(BuildContext context, OrdersLoaded state) {
    final bloc = context.read<OrdersBloc>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // First Row of Stats - Total, Pending, Confirmed
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OrderStatCard(
                  title: 'Total Orders',
                  count: state.stats.total,
                  iconColor: Colors.indigo,
                  icon: Icons.shopping_bag_outlined,
                  onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.all)),
                ),
                OrderStatCard(
                  title: 'Pending',
                  count: state.stats.pending,
                  iconColor: Colors.orange,
                  icon: Icons.access_time,
                  onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.pending)),
                ),
                OrderStatCard(
                  title: 'Confirmed',
                  count: state.stats.confirmed,
                  iconColor: Colors.blue,
                  icon: Icons.check_circle_outline,
                  onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.confirmed)),
                ),
              ],
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          
          // Second Row of Stats - Preparing, Ready for Delivery
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OrderStatCard(
                  title: 'Preparing',
                  count: state.stats.preparing,
                  iconColor: Colors.amber,
                  icon: Icons.restaurant,
                  onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.preparing)),
                ),
                OrderStatCard(
                  title: 'Ready for Delivery',
                  count: state.stats.readyForDelivery,
                  iconColor: Colors.purple,
                  icon: Icons.inventory_2_outlined,
                  onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.readyForDelivery)),
                ),
                // Empty placeholder to maintain 3-column layout
                Container(
                  width: MediaQuery.of(context).size.width * 0.28,
                ),
              ],
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          
          // Third Row of Stats - Out for Delivery, Delivered, Cancelled
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OrderStatCard(
                  title: 'Out for Delivery',
                  count: state.stats.outForDelivery,
                  iconColor: Colors.cyan,
                  icon: Icons.local_shipping_outlined,
                  onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.outForDelivery)),
                ),
                OrderStatCard(
                  title: 'Delivered',
                  count: state.stats.delivered,
                  iconColor: Colors.green,
                  icon: Icons.check_circle,
                  onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.delivered)),
                ),
                OrderStatCard(
                  title: 'Cancelled',
                  count: state.stats.cancelled,
                  iconColor: Colors.red,
                  icon: Icons.cancel_outlined,
                  onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.cancelled)),
                ),
              ],
            ),
          ),
          
          // Order History Section Header
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (state.filterStatus != OrderStatus.all)
                  TextButton(
                    onPressed: () => bloc.add(const FilterOrdersEvent(OrderStatus.all)),
                    child: Text(
                      'Show All',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // Order History List
          state.filteredOrders.isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.filterStatus == OrderStatus.all
                              ? 'No orders found'
                              : 'No ${_getStatusDisplayName(state.filterStatus)} orders',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.filterStatus == OrderStatus.all
                              ? 'Orders will appear here when customers place them'
                              : 'No orders with this status at the moment',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = state.filteredOrders[index];
                      return OrderCard(
                        orderId: order.id,
                        customerName: order.displayCustomerName,
                        amount: order.amount,
                        date: order.date,
                        status: order.orderStatus,
                        customerPhone: order.customerPhone,
                        deliveryAddress: order.deliveryAddress,
                        // Remove the old onTap - the card will handle bottom sheet internally
                      );
                    },
                    childCount: state.filteredOrders.length,
                  ),
                ),
          
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  String _getStatusDisplayName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.readyForDelivery:
        return 'ready for delivery';
      case OrderStatus.outForDelivery:
        return 'out for delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.all:
        return 'all';
    }
  }
}