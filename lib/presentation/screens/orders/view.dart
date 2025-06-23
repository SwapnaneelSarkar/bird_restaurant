// lib/presentation/screens/orders/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/enums.dart';
import '../../../presentation/resources/colors.dart';
import '../../../presentation/resources/font.dart';
import '../../../ui_components/order_card.dart';
import '../../../ui_components/order_stats_card.dart';
// Remove this import
import '../homePage/sidebar/sidebar_drawer.dart';
import '../../../ui_components/subscription_lock_dialog.dart';
import '../../../services/subscription_lock_service.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../../services/restaurant_info_service.dart';

// Wrapper widget that provides OrdersBloc
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersBloc()..add(const LoadOrdersEvent()), // Load orders on creation
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Restaurant info state
  Map<String, String>? _restaurantInfo;
  bool _isRestaurantInfoLoaded = false;
  
  // Subscription check state
  bool _hasCheckedSubscription = false;
  bool _hasValidSubscription = false;
  bool _hasShownSubscriptionDialog = false;

  @override
  void initState() {
    super.initState();
    // Check subscription first, then load orders if valid
    _checkSubscriptionAndLoadData();
  }

  Future<void> _checkSubscriptionAndLoadData() async {
    try {
      // Check if user can access orders page
      final canAccess = await SubscriptionLockService.canAccessPage('/orders');
      
      if (mounted) {
        setState(() {
          _hasValidSubscription = canAccess;
          _hasCheckedSubscription = true;
        });
        
        if (canAccess) {
          // User has valid subscription, load orders
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<OrdersBloc>().add(const LoadOrdersEvent());
            _loadRestaurantInfo();
          });
        } else {
          // User doesn't have valid subscription, show dialog
          _showSubscriptionDialog();
        }
      }
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      if (mounted) {
        setState(() {
          _hasCheckedSubscription = true;
          _hasValidSubscription = false;
        });
        _showSubscriptionDialog();
      }
    }
  }

  void _showSubscriptionDialog() async {
    if (_hasShownSubscriptionDialog) return;
    
    _hasShownSubscriptionDialog = true;
    
    try {
      final subscriptionStatus = await SubscriptionLockService.getSubscriptionStatus();
      
      if (mounted) {
        if (subscriptionStatus['status'] == 'PENDING') {
          // Show pending subscription dialog - NO ACCESS ALLOWED
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => PendingSubscriptionLockDialog(
              pageName: 'Orders Management',
              planName: subscriptionStatus['planName'] ?? 'Subscription',
              endDate: subscriptionStatus['endDate'] ?? 'Unknown',
              onGoBack: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
              },
            ),
          );
        } else {
          // Show subscription required dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => SubscriptionLockDialog(
              pageName: 'Orders Management',
              onGoToPlans: () {
                Navigator.of(context).pop();
                // Use safe navigation
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    try {
                      Navigator.of(context).pushNamed('/plan');
                    } catch (e) {
                      debugPrint('Error navigating to plans from fallback dialog: $e');
                      // Fallback navigation
                      try {
                        Navigator.of(context).pushNamedAndRemoveUntil('/plan', (route) => false);
                      } catch (fallbackError) {
                        debugPrint('Fallback navigation also failed: $fallbackError');
                      }
                    }
                  }
                });
              },
              onGoBack: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
              },
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error showing subscription dialog: $e');
      // Fallback to basic subscription dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SubscriptionLockDialog(
            pageName: 'Orders Management',
            onGoToPlans: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/plan');
            },
            onGoBack: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
          ),
        );
      }
    }
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      // Force refresh from API to get the latest restaurant info
      final info = await RestaurantInfoService.refreshRestaurantInfo();
      if (mounted) {
        setState(() {
          _restaurantInfo = info;
          _isRestaurantInfoLoaded = true;
        });
        debugPrint('🔄 OrdersPage: Loaded restaurant info - Name: ${info['name']}, Slogan: ${info['slogan']}, Image: ${info['imageUrl']}');
      }
    } catch (e) {
      debugPrint('Error loading restaurant info: $e');
    }
  }

  void _openSidebar() {
    // Use the scaffold's built-in drawer instead of pushing a new route
    _scaffoldKey.currentState?.openDrawer();
  }

@override
Widget build(BuildContext context) {
  // Show loading while checking subscription
  if (!_hasCheckedSubscription) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: _openSidebar,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.menu_rounded,
                  color: Colors.black87,
                  size: 24.0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Orders Management',
              style: TextStyle(
                fontFamily: FontFamily.Montserrat,
                fontSize: FontSize.s18,
                color: ColorManager.black,
                fontWeight: FontWeightManager.bold,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: ColorManager.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Checking subscription status...',
              style: TextStyle(
                fontSize: FontSize.s16,
                color: ColorManager.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // If user doesn't have valid subscription, show a placeholder screen
  if (!_hasValidSubscription) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: _openSidebar,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.menu_rounded,
                  color: Colors.black87,
                  size: 24.0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Orders Management',
              style: TextStyle(
                fontFamily: FontFamily.Montserrat,
                fontSize: FontSize.s18,
                color: ColorManager.black,
                fontWeight: FontWeightManager.bold,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: ColorManager.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Subscription Required',
              style: TextStyle(
                fontSize: FontSize.s20,
                fontWeight: FontWeightManager.bold,
                color: ColorManager.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please subscribe to access Orders Management',
              style: TextStyle(
                fontSize: FontSize.s16,
                color: ColorManager.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/plan');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Subscribe Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: FontSize.s16,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Scaffold(
    key: _scaffoldKey,
    backgroundColor: ColorManager.background,
    drawer: SidebarDrawer(
      activePage: 'orders',
      restaurantName: _restaurantInfo?['name'] ?? 'Restaurant',
      restaurantSlogan: _restaurantInfo?['slogan'] ?? 'Manage your orders',
      restaurantImageUrl: _restaurantInfo?['imageUrl'],
    ),
    appBar: AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: _openSidebar,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.menu_rounded,
                color: Colors.black87,
                size: 24.0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Orders Management',
            style: TextStyle(
              fontFamily: FontFamily.Montserrat,
              fontSize: FontSize.s18,
              color: ColorManager.black,
              fontWeight: FontWeightManager.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => context.read<OrdersBloc>().add(const RefreshOrdersEvent()),
          icon: const Icon(Icons.refresh, color: Colors.black87),
        ),
      ],
    ),
    body: MultiBlocListener(
      listeners: [
        // Status update success listener
        BlocListener<OrdersBloc, OrdersState>(
          listenWhen: (previous, current) => current is OrderStatusUpdateSuccess,
          listener: (context, state) {
            if (state is OrderStatusUpdateSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.message,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        ),
        
        // Status update error listener
        BlocListener<OrdersBloc, OrdersState>(
          listenWhen: (previous, current) => current is OrderStatusUpdateError,
          listener: (context, state) {
            if (state is OrderStatusUpdateError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.message,
                          style: const TextStyle(
                            fontWeight: FontWeightManager.medium,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          },
        ),
        
        // General error listener
        BlocListener<OrdersBloc, OrdersState>(
          listenWhen: (previous, current) => current is OrdersError,
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
        ),
      ],
      child: BlocBuilder<OrdersBloc, OrdersState>(
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
          
          // Show updating indicator for status updates
          if (state is OrderStatusUpdating) {
            // Keep the previous loaded state visible but show updating indicator
            final previousLoaded = context.read<OrdersBloc>().state;
            if (previousLoaded is OrdersLoaded) {
              return Stack(
                children: [
                  _buildOrdersContent(context, previousLoaded),
                  
                  // Overlay updating indicator
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.orange.withOpacity(0.9),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Updating order status...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeightManager.medium,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE17A47)),
              );
            }
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
                    // The OrderCard will handle bottom sheet internally
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