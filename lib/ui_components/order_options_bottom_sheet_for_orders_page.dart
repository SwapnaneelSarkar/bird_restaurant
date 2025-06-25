import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/order_model.dart';
import '../constants/enums.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import '../utils/time_utils.dart';
import 'order_status_bottomsheet.dart';
import '../presentation/screens/orders/bloc.dart';
import '../services/menu_item_service.dart';
import '../services/order_service.dart';

class OrderOptionsBottomSheetForOrdersPage extends StatelessWidget {
  final Order order;
  final OrdersBloc ordersBloc;
  const OrderOptionsBottomSheetForOrdersPage({Key? key, required this.order, required this.ordersBloc}) : super(key: key);

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
          _buildOptionTile(
            context,
            icon: Icons.receipt_long,
            title: 'View Order Details',
            subtitle: 'See items, customer info, and more',
            onTap: () async {
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              final fullOrder = await OrderService.fetchOrderDetailsById(order.id);
              if (Navigator.canPop(context)) Navigator.pop(context); // Remove loading dialog
              if (fullOrder != null && fullOrder.items != null && fullOrder.items!.isNotEmpty) {
                if (Navigator.canPop(context)) Navigator.pop(context); // Close the bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _OrderDetailsStandalone(order: fullOrder),
                  ),
                );
              } else {
                if (Navigator.canPop(context)) Navigator.pop(context); // Close the bottom sheet
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error'),
                    content: const Text('Could not load order details or no items found.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            context,
            icon: Icons.edit,
            title: 'Change Order Status',
            subtitle: 'Update the current order status',
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => OrderStatusBottomSheet(
                  orderId: order.id,
                  currentStatus: order.orderStatus,
                  ordersBloc: ordersBloc,
                ),
              );
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
}

// Standalone order details page for the orders page context
class _OrderDetailsStandalone extends StatelessWidget {
  final Order order;
  const _OrderDetailsStandalone({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: ColorManager.primary),
        title: Text(
          'Order Details',
          style: TextStyle(
            color: ColorManager.primary,
            fontWeight: FontWeightManager.semiBold,
            fontSize: FontSize.s18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt, color: ColorManager.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Order Information',
                          style: TextStyle(
                            color: ColorManager.primary,
                            fontWeight: FontWeightManager.semiBold,
                            fontSize: FontSize.s16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Order ID', order.id.length > 20 ? '${order.id.substring(0, 20)}...' : order.id),
                    _buildInfoRow('Customer', order.displayCustomerName),
                    if (order.customerPhone != null) _buildInfoRow('Phone', order.customerPhone!),
                    if (order.deliveryAddress != null) _buildInfoRow('Address', order.deliveryAddress!),
                    _buildInfoRow('Date', TimeUtils.formatStatusTimelineDate(order.date)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Items Section
            if (order.items != null && order.items!.isNotEmpty) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, color: ColorManager.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Order Items (${order.items!.length})',
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontWeight: FontWeightManager.semiBold,
                              fontSize: FontSize.s16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...order.items!.map((item) => _buildOrderItem(item)).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, color: ColorManager.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Order Items',
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontWeight: FontWeightManager.semiBold,
                              fontSize: FontSize.s16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No items available for this order',
                            style: TextStyle(
                              color: ColorManager.grey,
                              fontSize: FontSize.s14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Order Summary Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calculate, color: ColorManager.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Order Summary',
                          style: TextStyle(
                            color: ColorManager.primary,
                            fontWeight: FontWeightManager.semiBold,
                            fontSize: FontSize.s16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Subtotal', '₹${_calculateSubtotal().toStringAsFixed(2)}'),
                    _buildSummaryRow('Delivery Fee', '₹0.00'),
                    const Divider(),
                    _buildSummaryRow('Total', '₹${order.amount.toStringAsFixed(2)}', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Status Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: ColorManager.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Order Status',
                          style: TextStyle(
                            color: ColorManager.primary,
                            fontWeight: FontWeightManager.semiBold,
                            fontSize: FontSize.s16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.orderStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getStatusColor(order.orderStatus)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(order.orderStatus),
                            color: _getStatusColor(order.orderStatus),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            order.orderStatus.displayName,
                            style: TextStyle(
                              color: _getStatusColor(order.orderStatus),
                              fontWeight: FontWeightManager.medium,
                              fontSize: FontSize.s14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: ColorManager.primary,
                fontSize: FontSize.s14,
                fontWeight: FontWeightManager.medium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: ColorManager.black,
                fontSize: FontSize.s14,
                fontWeight: FontWeightManager.regular,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return FutureBuilder<MenuItem?>(
      future: MenuItemService.getMenuItem(item.menuId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final apiData = snapshot.data;
        final name = apiData?.name ?? 'Item';
        final price = apiData?.price ?? 0.0;
        final description = apiData?.description ?? '';
        return _buildOrderItemContent(name, price, description, item);
      },
    );
  }

  Widget _buildOrderItemContent(String name, double price, String description, OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.restaurant,
                        color: ColorManager.primary,
                        size: 24,
                      ),
                    ),
                  )
                : Icon(
                    Icons.restaurant,
                    color: ColorManager.primary,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 12),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: FontSize.s14,
                    fontWeight: FontWeightManager.medium,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      color: ColorManager.black,
                      fontSize: FontSize.s12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Qty: ${item.quantity}',
                      style: TextStyle(
                        color: ColorManager.black,
                        fontSize: FontSize.s12,
                        fontWeight: FontWeightManager.medium,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '₹${price.toStringAsFixed(2)} each',
                      style: TextStyle(
                        color: ColorManager.black,
                        fontSize: FontSize.s12,
                        fontWeight: FontWeightManager.medium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Item Total
          Text(
            '₹${(price * item.quantity).toStringAsFixed(2)}',
            style: TextStyle(
              color: ColorManager.primary,
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.semiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: ColorManager.primary,
              fontSize: isTotal ? FontSize.s16 : FontSize.s14,
              fontWeight: isTotal ? FontWeightManager.semiBold : FontWeightManager.medium,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? ColorManager.primary : ColorManager.black,
              fontSize: isTotal ? FontSize.s16 : FontSize.s14,
              fontWeight: isTotal ? FontWeightManager.semiBold : FontWeightManager.medium,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateSubtotal() {
    if (order.items == null || order.items!.isEmpty) {
      return order.amount; // Fallback to total amount if no items
    }
    return order.items!.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.readyForDelivery:
        return Colors.indigo;
      case OrderStatus.outForDelivery:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return ColorManager.grey;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.readyForDelivery:
        return Icons.local_shipping;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
} 