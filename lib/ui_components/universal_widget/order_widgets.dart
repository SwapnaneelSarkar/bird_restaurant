// lib/presentation/widgets/order_widgets.dart - COMPLETE FIXED VERSION
import 'dart:convert';

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
              color: OrderService.getStatusColor(orderDetails.orderStatus),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  OrderService.getStatusIcon(orderDetails.orderStatus),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  OrderService.formatOrderStatus(orderDetails.orderStatus),
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
          
          // View Order Details Option
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

// REPLACE the existing StatusChangeBottomSheet class in your order_widgets.dart file with this fixed version:

class StatusChangeBottomSheet extends StatefulWidget {
  final String orderId;
  final String partnerId;

  const StatusChangeBottomSheet({
    Key? key,
    required this.orderId,
    required this.partnerId,
  }) : super(key: key);

  @override
  State<StatusChangeBottomSheet> createState() => _StatusChangeBottomSheetState();
}

class _StatusChangeBottomSheetState extends State<StatusChangeBottomSheet> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    // Get current status from bloc state if available
    String currentStatus = 'PENDING';
    final chatBlocState = context.read<ChatBloc>().state;
    if (chatBlocState is ChatLoaded && chatBlocState.orderDetails != null) {
      currentStatus = chatBlocState.orderDetails!.orderStatus;
    }

    // SHOW ALL 7 STATUS OPTIONS as requested
    final allStatuses = OrderService.getAllValidStatuses();
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
            'Update Order Status',
            style: TextStyle(
              color: ColorManager.black,
              fontSize: 20,
              fontWeight: FontWeightManager.bold,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Current status with emoji and enhanced styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: OrderService.getStatusColor(currentStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: OrderService.getStatusColor(currentStatus).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  OrderService.getStatusEmoji(currentStatus),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Icon(
                  OrderService.getStatusIcon(currentStatus),
                  color: OrderService.getStatusColor(currentStatus),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current: ${OrderService.formatOrderStatus(currentStatus)}',
                  style: TextStyle(
                    color: OrderService.getStatusColor(currentStatus),
                    fontSize: 16,
                    fontWeight: FontWeightManager.bold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Show all 7 status options with visual indicators
          Text(
            'Select New Status:',
            style: TextStyle(
              color: ColorManager.black,
              fontSize: 16,
              fontWeight: FontWeightManager.medium,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // SHOW ALL 7 STATUS OPTIONS
          ...allStatuses.map((status) => _buildStatusOption(
            status: status,
            currentStatus: currentStatus,
            isAllowed: availableStatuses.contains(status),
            isCurrent: status.toUpperCase() == currentStatus.toUpperCase(),
            onTap: () {
              if (status.toUpperCase() == currentStatus.toUpperCase()) {
                // Same status - show info message
                _showInfoSnackBar('Order is already in ${OrderService.formatOrderStatus(status)} status');
                return;
              }
              
              _updateOrderStatus(status, currentStatus);
            },
          )),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusOption({
    required String status,
    required String currentStatus,
    required bool isAllowed,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    final isProgressive = _isProgressiveChange(currentStatus, status);
    final isCancellation = status.toUpperCase() == 'CANCELLED';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _isUpdating ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrent
                ? OrderService.getStatusColor(status).withOpacity(0.1)
                : isAllowed
                    ? (isCancellation
                        ? Colors.red.withOpacity(0.05)
                        : isProgressive 
                            ? OrderService.getStatusColor(status).withOpacity(0.05)
                            : Colors.blue.withOpacity(0.05))
                    : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? OrderService.getStatusColor(status)
                  : isAllowed
                      ? (isCancellation
                          ? Colors.red.withOpacity(0.3)
                          : isProgressive
                              ? OrderService.getStatusColor(status).withOpacity(0.3)
                              : Colors.blue.withOpacity(0.3))
                      : Colors.grey.withOpacity(0.3),
              width: isCurrent ? 2 : (isAllowed ? 1.5 : 1),
            ),
          ),
          child: Row(
            children: [
              // Status emoji and icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OrderService.getStatusColor(status).withOpacity(
                    isCurrent ? 0.2 : (isAllowed ? 0.1 : 0.05)
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      OrderService.getStatusEmoji(status),
                      style: TextStyle(
                        fontSize: 16,
                        // opacity: isAllowed ? 1.0 : 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      OrderService.getStatusIcon(status),
                      color: OrderService.getStatusColor(status).withOpacity(
                        isAllowed ? 1.0 : 0.5
                      ),
                      size: 18,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            OrderService.formatOrderStatus(status),
                            style: TextStyle(
                              color: isAllowed ? ColorManager.black : Colors.grey[500],
                              fontSize: 14,
                              fontWeight: isCurrent 
                                  ? FontWeightManager.bold 
                                  : FontWeightManager.medium,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ),
                        
                        // Status indicators
                        if (isCurrent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: OrderService.getStatusColor(status),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'CURRENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeightManager.bold,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ),
                        ] else if (isAllowed) ...[
                          if (isProgressive && !isCancellation) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'NEXT',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 8,
                                  fontWeight: FontWeightManager.bold,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            ),
                          ] else if (isCancellation) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CANCEL',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 8,
                                  fontWeight: FontWeightManager.bold,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ALLOWED',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 8,
                                  fontWeight: FontWeightManager.bold,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            ),
                          ]
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'NOT ALLOWED',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 8,
                                fontWeight: FontWeightManager.bold,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      OrderService.getStatusDescription(status),
                      style: TextStyle(
                        color: isAllowed ? Colors.grey[600] : Colors.grey[400],
                        fontSize: 11,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              if (_isUpdating) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFE17A47),
                  ),
                ),
              ] else ...[
                Icon(
                  isAllowed ? Icons.arrow_forward_ios : Icons.block,
                  color: isAllowed 
                      ? (isProgressive || isCancellation 
                          ? OrderService.getStatusColor(status) 
                          : Colors.blue[400])
                      : Colors.grey[400],
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper to determine if status change is progressive (forward in workflow)
  bool _isProgressiveChange(String currentStatus, String newStatus) {
    final statusOrder = [
      'PENDING',
      'CONFIRMED',
      'PREPARING',
      'READY_FOR_DELIVERY',
      'OUT_FOR_DELIVERY',
      'DELIVERED'
    ];
    
    final currentIndex = statusOrder.indexOf(currentStatus.toUpperCase());
    final newIndex = statusOrder.indexOf(newStatus.toUpperCase());
    
    return currentIndex != -1 && newIndex != -1 && newIndex > currentIndex;
  }

  // FIXED: Handle API call and response with proper context management
  Future<void> _updateOrderStatus(String newStatus, String currentStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // Call the API directly and get the response
      final success = await OrderService.updateOrderStatus(
        partnerId: widget.partnerId,
        orderId: widget.orderId,
        newStatus: newStatus,
      );

      if (mounted) {
        setState(() {
          _isUpdating = false;
        });

        // Close the bottom sheet first
        Navigator.of(context).pop();

        // Wait a frame to ensure the bottom sheet is closed before showing snackbar
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          if (success) {
            // Success - show success message
            _showSuccessSnackBarInParent(
              'Order status updated to ${OrderService.formatOrderStatus(newStatus)} successfully!',
              newStatus,
            );
            
            // Trigger bloc update
            context.read<ChatBloc>().add(UpdateOrderStatus(
              orderId: widget.orderId,
              partnerId: widget.partnerId,
              newStatus: newStatus,
            ));
          } else {
            // This shouldn't happen with our updated service, but handle it
            _showErrorSnackBarInParent('Failed to update order status. Please try again.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });

        // Close the bottom sheet first
        Navigator.of(context).pop();

        // Wait a frame to ensure the bottom sheet is closed
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          // Extract the API error message from the exception
          String errorMessage = 'Failed to update order status. Please try again.';
          
          try {
            // Parse the JSON error from the exception
            final errorString = e.toString();
            if (errorString.contains('Exception: {')) {
              final jsonStart = errorString.indexOf('{');
              if (jsonStart != -1) {
                final jsonStr = errorString.substring(jsonStart);
                final errorData = json.decode(jsonStr);
                
                if (errorData['message'] != null) {
                  errorMessage = errorData['message'];
                  
                  // Show allowed next statuses if available
                  if (errorData['allowedNextStatuses'] != null) {
                    final allowedStatuses = List<String>.from(errorData['allowedNextStatuses']);
                    final formattedStatuses = allowedStatuses
                        .map((s) => OrderService.formatOrderStatus(s))
                        .join(', ');
                    errorMessage += '\n\nAllowed statuses: $formattedStatuses';
                  }
                }
              }
            }
          } catch (parseError) {
            // If parsing fails, check for specific error patterns
            final errorString = e.toString();
            if (errorString.contains('Cannot change status')) {
              errorMessage = 'Cannot change status from ${OrderService.formatOrderStatus(currentStatus)} to ${OrderService.formatOrderStatus(newStatus)}';
            }
          }
          
          _showErrorSnackBarInParent(errorMessage);
        }
      }
    }
  }

  void _showSuccessSnackBarInParent(String message, String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(
              OrderService.getStatusEmoji(status),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBarInParent(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeightManager.medium,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 6),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeightManager.medium,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}