// lib/presentation/screens/orders/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/enums.dart';
import '../../../presentation/resources/colors.dart';
import '../../../presentation/resources/font.dart';
import '../../../ui_components/order_card.dart';
import '../../../ui_components/order_stats_card.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

// Wrapper widget that provides OrdersBloc
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersBloc(),
      child: const OrdersView(),
    );
  }
}

class OrdersView extends StatefulWidget {
  const OrdersView({Key? key}) : super(key: key);

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  @override
  void initState() {
    super.initState();
    // Load orders after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersBloc>().add(const LoadOrdersEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        title: Text(
          'Orders Management',
          style: TextStyle(
            fontFamily: FontFamily.Montserrat,
            fontSize: FontSize.s18,
            color: ColorManager.black,
            fontWeight: FontWeightManager.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.read<OrdersBloc>().add(const RefreshOrdersEvent()),
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
        ],
      ),
      body: BlocConsumer<OrdersBloc, OrdersState>(
        listener: (context, state) {
          if (state is OrdersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE17A47),
              ),
            );
          }

          if (state is OrdersLoaded) {
            return _buildOrdersContent(context, state);
          }

          if (state is OrdersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading orders',
                    style: TextStyle(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.medium,
                      color: ColorManager.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: FontSize.s14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<OrdersBloc>().add(const LoadOrdersEvent()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE17A47),
                    ),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
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
          
          // First Row - 3 Cards (Total Orders, Pending, Confirmed)
          SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    title: 'Total Orders',
                    count: state.stats.total,
                    iconColor: Colors.indigo,
                    icon: Icons.shopping_bag_outlined,
                    onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.all)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatsCard(
                    title: 'Pending',
                    count: state.stats.pending,
                    iconColor: Colors.orange,
                    icon: Icons.access_time,
                    onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.pending)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatsCard(
                    title: 'Confirmed',
                    count: state.stats.confirmed,
                    iconColor: Colors.blue,
                    icon: Icons.check_circle_outline,
                    onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.confirmed)),
                  ),
                ),
              ],
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // Second Row - 3 Cards (Preparing, Ready, Out for Delivery)
          SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    title: 'Preparing',
                    count: state.stats.preparing,
                    iconColor: Colors.purple,
                    icon: Icons.restaurant,
                    onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.preparing)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatsCard(
                    title: 'Ready',
                    count: state.stats.readyForDelivery,
                    iconColor: Colors.green,
                    icon: Icons.done_all,
                    onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.readyForDelivery)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatsCard(
                    title: 'Out for Delivery',
                    count: state.stats.outForDelivery,
                    iconColor: Colors.cyan,
                    icon: Icons.delivery_dining,
                    onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.outForDelivery)),
                  ),
                ),
              ],
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // Third Row - 2 Cards (Delivered, Cancelled)
          SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildStatsCard(
                    title: 'Delivered',
                    count: state.stats.delivered,
                    iconColor: Colors.teal,
                    icon: Icons.check_circle,
                    onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.delivered)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildStatsCard(
                    title: 'Cancelled',
                    count: state.stats.cancelled,
                    iconColor: Colors.red,
                    icon: Icons.cancel_outlined,
                    onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.cancelled)),
                  ),
                ),
              ],
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          
          // Filter Status Header
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getFilterTitle(state.filterStatus),
                  style: TextStyle(
                    fontSize: FontSize.s16,
                    fontWeight: FontWeightManager.bold,
                    color: ColorManager.black,
                  ),
                ),
                if (state.filterStatus != OrderStatus.all)
                  TextButton(
                    onPressed: () => bloc.add(const FilterOrdersEvent(OrderStatus.all)),
                    child: Text(
                      'Show All',
                      style: TextStyle(
                        color: const Color(0xFFE17A47),
                        fontWeight: FontWeightManager.medium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // Orders List
          if (state.filteredOrders.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No orders found',
                        style: TextStyle(
                          fontSize: FontSize.s16,
                          fontWeight: FontWeightManager.medium,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.filterStatus == OrderStatus.all
                            ? 'No orders available'
                            : 'No ${_getStatusName(state.filterStatus)} orders found',
                        style: TextStyle(
                          fontSize: FontSize.s14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
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
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required int count,
    required Color iconColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: FontSize.s18,
                fontWeight: FontWeightManager.bold,
                color: ColorManager.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: FontSize.s10,
                fontWeight: FontWeightManager.medium,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterTitle(OrderStatus status) {
    switch (status) {
      case OrderStatus.all:
        return 'All Orders';
      case OrderStatus.pending:
        return 'Pending Orders';
      case OrderStatus.confirmed:
        return 'Confirmed Orders';
      case OrderStatus.preparing:
        return 'Preparing Orders';
      case OrderStatus.readyForDelivery:
        return 'Ready for Delivery';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered Orders';
      case OrderStatus.cancelled:
        return 'Cancelled Orders';
    }
  }

  String _getStatusName(OrderStatus status) {
    switch (status) {
      case OrderStatus.all:
        return 'all';
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
    }
  }
}