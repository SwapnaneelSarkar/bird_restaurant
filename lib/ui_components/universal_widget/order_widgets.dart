// lib/presentation/widgets/order_widgets.dart - COMPLETE FIXED VERSION

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/resources/colors.dart';
import '../../presentation/resources/font.dart';
import '../../presentation/screens/chat/bloc.dart';
import '../../presentation/screens/chat/event.dart';
import '../../presentation/screens/chat/state.dart';
import '../../services/menu_item_service.dart';
import '../../services/order_service.dart';

class OrderDetailsWidget extends StatelessWidget {
  const OrderDetailsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: TextStyle(
            color: ColorManager.black,
            fontWeight: FontWeightManager.bold,
            fontFamily: FontFamily.Montserrat,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: ColorManager.black),
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          print('🔍 DEBUG: Current ChatBloc state: ${state.runtimeType}');
    
          if (state is ChatLoaded) {
            print('🔍 DEBUG: ChatLoaded state:');
            print('  - Has order details: ${state.orderDetails != null}');
            print('  - Is loading order details: ${state.isLoadingOrderDetails}');
            print('  - Menu items count: ${state.menuItems.length}');
            
            if (state.orderDetails != null) {
              print('  - Order ID: ${state.orderDetails!.orderId}');
              print('  - Items count: ${state.orderDetails!.items.length}');
            }
          }
          
          if (state is OrderDetailsLoaded) {
            print('🔍 DEBUG: OrderDetailsLoaded state:');
            print('  - Order ID: ${state.orderDetails.orderId}');
            print('  - Items count: ${state.orderDetails.items.length}');
            print('  - Menu items count: ${state.menuItems?.length ?? 0}');
          }
          
          if (state is OrderDetailsLoading) {
            print('🔍 DEBUG: OrderDetailsLoading state');
          }
          
          if (state is OrderDetailsError) {
            print('🔍 DEBUG: OrderDetailsError state: ${state.message}');
          }

          if (state is OrderDetailsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE17A47)),
            );
          }
          
          if (state is ChatLoaded && state.orderDetails != null) {
            return _buildOrderDetails(context, state.orderDetails!, state.menuItems);
          }
          
          if (state is OrderDetailsLoaded) {
            return _buildOrderDetails(context, state.orderDetails, state.menuItems ?? {});
          }
          
          if (state is OrderDetailsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: ColorManager.black,
                        fontSize: 16,
                        fontFamily: FontFamily.Montserrat,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE17A47),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE17A47)),
          );
        },
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, OrderDetails orderDetails, Map<String, MenuItem> menuItems) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          _buildOrderHeader(orderDetails),
          
          const SizedBox(height: 24),
          
          // Order items with menu item details
          _buildOrderItems(orderDetails, menuItems),
          
          const SizedBox(height: 24),
          
          // Order summary
          _buildOrderSummary(orderDetails),
          
          const SizedBox(height: 24),
          
          // Order status
          _buildOrderStatus(orderDetails),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(OrderDetails orderDetails) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFFE17A47), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order #${orderDetails.orderId.length > 8 ? orderDetails.orderId.substring(orderDetails.orderId.length - 8) : orderDetails.orderId}',
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: 20,
                    fontWeight: FontWeightManager.bold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'User ID: ${orderDetails.userId.length > 12 ? orderDetails.userId.substring(orderDetails.userId.length - 12) : orderDetails.userId}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(OrderDetails orderDetails, Map<String, MenuItem> menuItems) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: Color(0xFFE17A47), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order Items (${orderDetails.items.length})',
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: 18,
                    fontWeight: FontWeightManager.bold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ),
              
              // Loading indicator for menu items
              if (menuItems.isEmpty && orderDetails.items.isNotEmpty)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFE17A47),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Show items with enhanced display
          ...orderDetails.items.map((item) => _buildOrderItem(item, menuItems)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item, Map<String, MenuItem> menuItems) {
    final menuItem = item.getMenuItem(menuItems);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Menu item image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: (menuItem != null && menuItem.imageUrl.isNotEmpty)
                  ? Image.network(
                      menuItem.displayImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildLoadingImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item name (from menu item) or fallback to menu ID
                Text(
                  item.getDisplayName(menuItems),
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: 16,
                    fontWeight: FontWeightManager.bold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                
                const SizedBox(height: 4),
                
                // Menu item description (if available)
                if (menuItem?.description.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      menuItem!.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontFamily: FontFamily.Montserrat,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                
                // Price and quantity info
                Row(
                  children: [
                    Text(
                      item.formattedPrice,
                      style: TextStyle(
                        color: const Color(0xFFE17A47),
                        fontSize: 14,
                        fontWeight: FontWeightManager.medium,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                    Text(
                      ' × ${item.quantity}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Total price and availability
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.formattedTotalPrice,
                style: TextStyle(
                  color: ColorManager.black,
                  fontSize: 16,
                  fontWeight: FontWeightManager.bold,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
              
              // Availability indicator (if menu item is loaded)
              if (menuItem != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: menuItem.isAvailable 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    menuItem.isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: menuItem.isAvailable ? Colors.green[700] : Colors.red[700],
                      fontSize: 10,
                      fontWeight: FontWeightManager.medium,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.fastfood,
        color: Colors.grey[400],
        size: 30,
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFE17A47),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(OrderDetails orderDetails) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt, color: Color(0xFFE17A47), size: 24),
              const SizedBox(width: 12),
              Text(
                'Order Summary',
                style: TextStyle(
                  color: ColorManager.black,
                  fontSize: 18,
                  fontWeight: FontWeightManager.bold,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
              Text(
                orderDetails.formattedTotal,
                style: TextStyle(
                  color: ColorManager.black,
                  fontSize: 14,
                  fontWeight: FontWeightManager.medium,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fees',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
              Text(
                orderDetails.formattedDeliveryFees,
                style: TextStyle(
                  color: ColorManager.black,
                  fontSize: 14,
                  fontWeight: FontWeightManager.medium,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: ColorManager.black,
                  fontSize: 16,
                  fontWeight: FontWeightManager.bold,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
              Text(
                orderDetails.formattedGrandTotal,
                style: TextStyle(
                  color: const Color(0xFFE17A47),
                  fontSize: 16,
                  fontWeight: FontWeightManager.bold,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus(OrderDetails orderDetails) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFE17A47), size: 24),
              const SizedBox(width: 12),
              Text(
                'Order Status',
                style: TextStyle(
                  color: ColorManager.black,
                  fontSize: 18,
                  fontWeight: FontWeightManager.bold,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(orderDetails.orderStatus),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(orderDetails.orderStatus),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  orderDetails.orderStatus.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.access_time;
      case 'CONFIRMED':
        return Icons.check_circle_outline;
      case 'PREPARING':
        return Icons.restaurant;
      case 'READY':
        return Icons.done_all;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PREPARING':
        return const Color(0xFFE17A47);
      case 'READY':
        return Colors.green;
      case 'OUT_FOR_DELIVERY':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green[700]!;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Order Options Bottom Sheet Widget
class OrderOptionsBottomSheet extends StatelessWidget {
  final String orderId;
  final String partnerId;

  const OrderOptionsBottomSheet({
    Key? key,
    required this.orderId,
    required this.partnerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Text(
            'Order Options',
            style: TextStyle(
              color: ColorManager.black,
              fontSize: 20,
              fontWeight: FontWeightManager.bold,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // View Order Details Option - FIXED TO NAVIGATE PROPERLY
          _buildOptionTile(
            context,
            icon: Icons.receipt_long,
            title: 'View Order Details',
            subtitle: 'See items, customer info, and more',
            onTap: () {
              Navigator.pop(context); // Close the bottom sheet first
              
              // Navigate to order details page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderDetailsWidget(),
                ),
              );
              
              // Trigger the bloc event to load order details
              context.read<ChatBloc>().add(LoadOrderDetails(
                orderId: orderId,
                partnerId: partnerId,
              ));
            },
          ),
          
          const SizedBox(height: 12),
          
          // Change Order Status Option
          _buildOptionTile(
            context,
            icon: Icons.edit,
            title: 'Change Order Status',
            subtitle: 'Update the current order status',
            onTap: () {
              Navigator.pop(context);
              _showStatusChangeBottomSheet(context, orderId, partnerId);
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE17A47).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFE17A47),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: ColorManager.black,
                      fontSize: 16,
                      fontWeight: FontWeightManager.medium,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusChangeBottomSheet(BuildContext context, String orderId, String partnerId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatusChangeBottomSheet(
        orderId: orderId,
        partnerId: partnerId,
      ),
    );
  }
}

// Status Change Bottom Sheet Widget
class StatusChangeBottomSheet extends StatelessWidget {
  final String orderId;
  final String partnerId;

  const StatusChangeBottomSheet({
    Key? key,
    required this.orderId,
    required this.partnerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get current status from bloc state if available
    String currentStatus = 'PENDING';
    final chatBlocState = context.read<ChatBloc>().state;
    if (chatBlocState is ChatLoaded && chatBlocState.orderDetails != null) {
      currentStatus = chatBlocState.orderDetails!.orderStatus;
    }

    final availableStatuses = OrderService.getAvailableStatusOptions(currentStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Text(
            'Change Order Status',
            style: TextStyle(
              color: ColorManager.black,
              fontSize: 20,
              fontWeight: FontWeightManager.bold,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Current status
          Text(
            'Current: ${OrderService.formatOrderStatus(currentStatus)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Available status options
          if (availableStatuses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No status changes available for current status',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontFamily: FontFamily.Montserrat,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...availableStatuses.map((status) => _buildStatusOption(
              context,
              status: status,
              onTap: () {
                Navigator.pop(context);
                context.read<ChatBloc>().add(UpdateOrderStatus(
                  orderId: orderId,
                  partnerId: partnerId,
                  newStatus: status,
                ));
              },
            )),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context, {
    required String status,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Text(
                  OrderService.formatOrderStatus(status),
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: 16,
                    fontWeight: FontWeightManager.medium,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.access_time;
      case 'CONFIRMED':
        return Icons.check_circle_outline;
      case 'PREPARING':
        return Icons.restaurant;
      case 'READY':
        return Icons.done_all;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PREPARING':
        return const Color(0xFFE17A47);
      case 'READY':
        return Colors.green;
      case 'OUT_FOR_DELIVERY':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green[700]!;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}