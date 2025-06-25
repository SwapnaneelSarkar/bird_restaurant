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
        elevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: IconThemeData(color: ColorManager.primary),
        title: Text(
          'Order Details',
          style: TextStyle(
            color: ColorManager.primary,
            fontWeight: FontWeightManager.bold,
            fontSize: FontSize.s18,
            fontFamily: FontFamily.Montserrat,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header Section with enhanced design
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorManager.primary.withOpacity(0.1),
                    ColorManager.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ColorManager.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.primary.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ColorManager.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: ColorManager.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Information',
                                style: TextStyle(
                                  color: ColorManager.primary,
                                  fontWeight: FontWeightManager.bold,
                                  fontSize: FontSize.s16,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Complete order details',
                                style: TextStyle(
                                  color: ColorManager.textGrey,
                                  fontSize: FontSize.s10,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildEnhancedInfoRow('Order ID', order.id.length > 20 ? '${order.id.substring(0, 20)}...' : order.id, Icons.tag),
                    _buildEnhancedInfoRow('Customer', order.displayCustomerName, Icons.person),
                    if (order.customerPhone != null) _buildEnhancedInfoRow('Phone', order.customerPhone!, Icons.phone),
                    if (order.deliveryAddress != null) _buildEnhancedInfoRow('Address', order.deliveryAddress!, Icons.location_on),
                    _buildEnhancedInfoRow('Date', TimeUtils.formatStatusTimelineDate(order.date), Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Items Section with enhanced design
            if (order.items != null && order.items!.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ColorManager.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.restaurant_menu,
                              color: ColorManager.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Items',
                                  style: TextStyle(
                                    color: ColorManager.primary,
                                    fontWeight: FontWeightManager.bold,
                                    fontSize: FontSize.s16,
                                    fontFamily: FontFamily.Montserrat,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${order.items!.length} items ordered',
                                  style: TextStyle(
                                    color: ColorManager.textGrey,
                                    fontSize: FontSize.s10,
                                    fontFamily: FontFamily.Montserrat,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...order.items!.map((item) => _buildEnhancedOrderItem(item)).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ColorManager.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.restaurant_menu,
                              color: ColorManager.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Items',
                                  style: TextStyle(
                                    color: ColorManager.primary,
                                    fontWeight: FontWeightManager.bold,
                                    fontSize: FontSize.s16,
                                    fontFamily: FontFamily.Montserrat,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'No items available',
                                  style: TextStyle(
                                    color: ColorManager.textGrey,
                                    fontSize: FontSize.s10,
                                    fontFamily: FontFamily.Montserrat,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: ColorManager.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorManager.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 36,
                                color: ColorManager.textGrey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No items available for this order',
                                style: TextStyle(
                                  color: ColorManager.textGrey,
                                  fontSize: FontSize.s12,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Order Summary Section with enhanced design
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorManager.primary.withOpacity(0.08),
                    ColorManager.primary.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ColorManager.primary.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.primary.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ColorManager.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calculate,
                            color: ColorManager.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Summary',
                                style: TextStyle(
                                  color: ColorManager.primary,
                                  fontWeight: FontWeightManager.bold,
                                  fontSize: FontSize.s16,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Payment breakdown',
                                style: TextStyle(
                                  color: ColorManager.textGrey,
                                  fontSize: FontSize.s10,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildEnhancedSummaryRow('Subtotal', '₹${_calculateSubtotal().toStringAsFixed(2)}'),
                    _buildEnhancedSummaryRow('Delivery Fee', '₹0.00'),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            ColorManager.primary.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    _buildEnhancedSummaryRow('Total', '₹${order.amount.toStringAsFixed(2)}', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Status Section with enhanced design
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ColorManager.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: ColorManager.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Status',
                                style: TextStyle(
                                  color: ColorManager.primary,
                                  fontWeight: FontWeightManager.bold,
                                  fontSize: FontSize.s16,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Current order progress',
                                style: TextStyle(
                                  color: ColorManager.textGrey,
                                  fontSize: FontSize.s10,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(order.orderStatus).withOpacity(0.1),
                            _getStatusColor(order.orderStatus).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(order.orderStatus).withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(order.orderStatus).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.orderStatus).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getStatusIcon(order.orderStatus),
                              color: _getStatusColor(order.orderStatus),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            order.orderStatus.displayName,
                            style: TextStyle(
                              color: _getStatusColor(order.orderStatus),
                              fontWeight: FontWeightManager.bold,
                              fontSize: FontSize.s14,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: ColorManager.primary,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ColorManager.textGrey,
                    fontSize: FontSize.s10,
                    fontWeight: FontWeightManager.medium,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: FontSize.s12,
                    fontWeight: FontWeightManager.semiBold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOrderItem(OrderItem item) {
    return FutureBuilder<MenuItem?>(
      future: MenuItemService.getMenuItem(item.menuId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorManager.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorManager.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2691E)),
                ),
              ),
            ),
          );
        }
        final apiData = snapshot.data;
        final name = apiData?.name ?? 'Item';
        final price = apiData?.price ?? 0.0;
        final description = apiData?.description ?? '';
        return _buildEnhancedOrderItemContent(name, price, description, item);
      },
    );
  }

  Widget _buildEnhancedOrderItemContent(String name, double price, String description, OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorManager.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorManager.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Enhanced Item Image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: ColorManager.primary.withOpacity(0.1),
              border: Border.all(
                color: ColorManager.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.restaurant,
                        color: ColorManager.primary,
                        size: 22,
                      ),
                    ),
                  )
                : Icon(
                    Icons.restaurant,
                    color: ColorManager.primary,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          // Enhanced Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: FontSize.s14,
                    fontWeight: FontWeightManager.bold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: ColorManager.textGrey,
                      fontSize: FontSize.s10,
                      fontFamily: FontFamily.Montserrat,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Qty: ${item.quantity}',
                        style: TextStyle(
                          color: ColorManager.primary,
                          fontSize: FontSize.s10,
                          fontWeight: FontWeightManager.bold,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${price.toStringAsFixed(2)} each',
                      style: TextStyle(
                        color: ColorManager.textGrey,
                        fontSize: FontSize.s10,
                        fontWeight: FontWeightManager.medium,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Enhanced Item Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ColorManager.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '₹${(price * item.quantity).toStringAsFixed(2)}',
              style: TextStyle(
                color: ColorManager.primary,
                fontSize: FontSize.s12,
                fontWeight: FontWeightManager.bold,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryRow(String label, String value, {bool isTotal = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? ColorManager.primary : ColorManager.textGrey,
              fontSize: isTotal ? FontSize.s14 : FontSize.s12,
              fontWeight: isTotal ? FontWeightManager.bold : FontWeightManager.medium,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? ColorManager.primary : ColorManager.black,
              fontSize: isTotal ? FontSize.s16 : FontSize.s12,
              fontWeight: isTotal ? FontWeightManager.bold : FontWeightManager.semiBold,
              fontFamily: FontFamily.Montserrat,
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