// lib/presentation/screens/orders/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../ui_components/order_card.dart';
import '../../../ui_components/order_stats_card.dart';
import '../../../ui_components/universal_widget/topbar.dart';

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
                child: BlocBuilder<OrdersBloc, OrdersState>(
                  builder: (context, state) {
                    if (state is OrdersLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (state is OrdersLoaded) {
                      return _buildOrdersContent(context, state);
                    } else if (state is OrdersError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
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
          SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
          
          // First row of stat cards
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OrderStatCard(
                  title: 'Orders',
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
                  iconColor: Colors.green,
                  icon: Icons.check_circle_outline,
                  onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.confirmed)),
                ),
              ],
            ),
          ),
          
          // Second row of stat cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OrderStatCard(
                    title: 'Delivery',
                    count: state.stats.delivery,
                    iconColor: Colors.blue,
                    icon: Icons.delivery_dining,
                    onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.delivery)),
                  ),
                  OrderStatCard(
                    title: 'Delivered',
                    count: state.stats.delivered,
                    iconColor: Colors.green,
                    icon: Icons.done_all,
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
          ),
          
          // Third row with single stat card
          SliverToBoxAdapter(
            child: Row(
              children: [
                OrderStatCard(
                  title: 'Preparing',
                  count: state.stats.preparing,
                  iconColor: Colors.amber,
                  icon: Icons.restaurant,
                  onTap: () => bloc.add(const FilterOrdersEvent(OrderStatus.preparing)),
                ),
                const Spacer(),
              ],
            ),
          ),
          
          SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
          
          // Order cards
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final order = state.orders[index];
                return OrderCard(
                  orderId: order.id,
                  customerName: order.customerName,
                  amount: order.amount,
                  date: order.date,
                  status: order.status,
                  onTap: () {
                    // Handle order tap - could navigate to order details
                    // or show a bottom sheet with options
                  },
                );
              },
              childCount: state.orders.length,
            ),
          ),
          
          SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }
}