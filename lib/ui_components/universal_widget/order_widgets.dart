// lib/presentation/widgets/order_widgets.dart - FIXED THEME

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/resources/colors.dart';
import '../../presentation/resources/font.dart';
import '../../presentation/screens/chat/bloc.dart';
import '../../presentation/screens/chat/event.dart';
import '../../presentation/screens/chat/state.dart';
import '../../services/menu_item_service.dart';
import '../../services/order_service.dart';


class OrderOptionsBottomSheet extends StatelessWidget {
  final String orderId;
  final String partnerId;

  const OrderOptionsBottomSheet({
    super.key,
    required this.orderId,
    required this.partnerId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white, // White background like the rest of the app
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
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Text(
            'Order Actions',
            style: TextStyle(
              color: ColorManager.black,
              fontSize: 20,
              fontWeight: FontWeightManager.bold,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Order ID - FIXED OVERFLOW
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'Order: ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
                Expanded(
                  child: Text(
                    orderId,
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
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          _buildActionButton(
            context,
            icon: Icons.swap_horiz,
            title: 'Change Order Status',
            subtitle: 'Update the status of this order',
            onTap: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(ChangeOrderStatus(
                orderId: orderId,
                partnerId: partnerId,
              ));
              _showOrderStatusBottomSheet(context, orderId, partnerId);
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildActionButton(
            context,
            icon: Icons.info_outline,
            title: 'View Order Details',
            subtitle: 'See complete order information',
            onTap: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(LoadOrderDetails(
                orderId: orderId,
                partnerId: partnerId,
              ));
              _showOrderDetailsPage(context);
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionButton(
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
                color: const Color(0xFFE17A47).withOpacity(0.1), // Primary orange with opacity
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFE17A47), // Primary orange
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
                      fontWeight: FontWeightManager.bold,
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

  static void show(BuildContext context, String orderId, String partnerId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => OrderOptionsBottomSheet(
        orderId: orderId,
        partnerId: partnerId,
      ),
    );
  }

  static void _showOrderStatusBottomSheet(BuildContext context, String orderId, String partnerId) {
    // Get current order status from the state
    final chatState = context.read<ChatBloc>().state;
    String currentStatus = 'PENDING';
    
    if (chatState is ChatLoaded) {
      currentStatus = chatState.orderInfo.status.toUpperCase();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => OrderStatusBottomSheet(
        orderId: orderId,
        partnerId: partnerId,
        currentStatus: currentStatus,
      ),
    );
  }

  static void _showOrderDetailsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrderDetailsPage(),
      ),
    );
  }
}

class OrderStatusBottomSheet extends StatelessWidget {
  final String orderId;
  final String partnerId;
  final String currentStatus;

  const OrderStatusBottomSheet({
    super.key,
    required this.orderId,
    required this.partnerId,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final availableStatuses = OrderService.getAvailableStatusOptions(currentStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white, // White background
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
              color: Colors.grey[400],
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
          
          const SizedBox(height: 16),
          
          // Current status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: const Color(0xFFE17A47), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Current Status: ${OrderService.formatOrderStatus(currentStatus)}',
                    style: TextStyle(
                      color: ColorManager.black,
                      fontSize: 16,
                      fontFamily: FontFamily.Montserrat,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (availableStatuses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No status changes available for this order.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Available status options
            Column(
              children: availableStatuses.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildStatusOption(
                    context,
                    status,
                    OrderService.formatOrderStatus(status),
                    _getStatusColor(status),
                    () {
                      Navigator.pop(context);
                      context.read<ChatBloc>().add(UpdateOrderStatus(
                        orderId: orderId,
                        partnerId: partnerId,
                        newStatus: status,
                      ));
                    },
                  ),
                );
              }).toList(),
            ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    String status,
    String displayName,
    Color color,
    VoidCallback onTap,
  ) {
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
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Text(
                displayName,
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return const Color(0xFFE17A47); // Primary orange
      case 'PREPARING':
        return Colors.purple;
      case 'READY':
        return Colors.green;
      case 'OUT_FOR_DELIVERY':
        return Colors.teal;
      case 'DELIVERED':
        return Colors.green[700]!;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static void show(BuildContext context, String orderId, String partnerId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => OrderStatusBottomSheet(
        orderId: orderId,
        partnerId: partnerId,
        currentStatus: currentStatus,
      ),
    );
  }
}

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Order Details',
          style: TextStyle(
            color: ColorManager.black,
            fontFamily: FontFamily.Montserrat,
            fontWeight: FontWeightManager.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorManager.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoaded) {
            if (state.isLoadingOrderDetails) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE17A47)),
              );
            }
            
            if (state.orderDetails != null) {
              return _buildOrderDetails(context, state.orderDetails!);
            }
          }
          
          if (state is OrderDetailsLoaded) {
            return _buildOrderDetails(context, state.orderDetails);
          }
          
          if (state is OrderDetailsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
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
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: FontFamily.Montserrat,
                      ),
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

  Widget _buildOrderDetails(BuildContext context, OrderDetails orderDetails) {
  return BlocBuilder<ChatBloc, ChatState>(
    builder: (context, state) {
      Map<String, MenuItem> menuItems = {};
      
      // Get menu items from the current state
      if (state is ChatLoaded) {
        menuItems = state.menuItems;
      } else if (state is OrderDetailsLoaded) {
        menuItems = state.menuItems;
      }
      
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
    },
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
              Icon(Icons.receipt_long, color: const Color(0xFFE17A47), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order #${orderDetails.orderId}',
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
                  'User ID: ${orderDetails.userId}',
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
            Icon(Icons.restaurant_menu, color: const Color(0xFFE17A47), size: 24),
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
            child: menuItem?.imageUrl.isNotEmpty == true
                ? Image.network(
                    menuItem!.displayImageUrl,
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
        
        // Total price
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

// Helper widget for loading image
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
              Icon(Icons.calculate, color: const Color(0xFFE17A47), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order Summary',
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: 18,
                    fontWeight: FontWeightManager.bold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSummaryRow('Subtotal', orderDetails.formattedTotal),
          _buildSummaryRow('Delivery Fees', orderDetails.formattedDeliveryFees),
          
          Divider(color: Colors.grey[300], height: 24),
          
          _buildSummaryRow(
            'Total Amount',
            orderDetails.formattedGrandTotal,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? ColorManager.black : Colors.grey[600],
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeightManager.bold : FontWeightManager.regular,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: ColorManager.black,
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeightManager.bold : FontWeightManager.medium,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus(OrderDetails orderDetails) {
    final statusColor = _getStatusColor(orderDetails.orderStatus);
    
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
              Icon(Icons.flag, color: const Color(0xFFE17A47), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order Status',
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: 18,
                    fontWeight: FontWeightManager.bold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    OrderService.formatOrderStatus(orderDetails.orderStatus),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 16,
                      fontWeight: FontWeightManager.bold,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return const Color(0xFFE17A47); // Primary orange
      case 'PREPARING':
        return Colors.purple;
      case 'READY':
        return Colors.green;
      case 'OUT_FOR_DELIVERY':
        return Colors.teal;
      case 'DELIVERED':
        return Colors.green[700]!;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}