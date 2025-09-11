// lib/presentation/screens/order_action/view.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/order_service.dart';
import '../../../services/token_service.dart';
import '../../../services/menu_item_service.dart';
import '../chat/state.dart' show OrderDetails, OrderItem; // Use partner order details model
import '../../../utils/time_utils.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../../resources/router/router.dart';

class OrderActionView extends StatefulWidget {
  final String orderId;

  const OrderActionView({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderActionView> createState() => _OrderActionViewState();
}

class _OrderActionViewState extends State<OrderActionView> {
  bool _isLoading = true;
  bool _isUpdating = false;
  OrderDetails? _order;
  String? _errorMessage;
  Map<String, MenuItem> _menuItems = {};

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final partnerId = await OrderService.getPartnerId();
      if (partnerId == null || partnerId.isEmpty) {
        throw Exception('Partner ID not found');
      }
      final order = await OrderService.getOrderDetails(
        partnerId: partnerId,
        orderId: widget.orderId,
      );
      
      // Load menu items if order has items
      Map<String, MenuItem> menuItems = {};
      if (order != null && order.items.isNotEmpty) {
        try {
          final menuIds = order.items.map((item) => item.menuId).toList();
          menuItems = await MenuItemService.getMenuItems(menuIds);
        } catch (e) {
          debugPrint('OrderActionView: ❌ Error loading menu items: $e');
          // Continue without menu items - will fall back to menu IDs
        }
      }
      
      setState(() {
        _order = order;
        _menuItems = menuItems;
        _isLoading = false;
      });

      // If order is already accepted (preparing) or cancelled, navigate to order details
      if (order != null && (order.orderStatus.toUpperCase() == 'PREPARING' || order.orderStatus.toUpperCase() == 'CANCELLED')) {
        _navigateToOrderDetails();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load order details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String newStatus, String actionName) async {
    if (_order == null) return;

    try {
      debugPrint('OrderActionView: 🎯 Updating order status');
      debugPrint('OrderActionView: 🎯 Order ID: ${widget.orderId}');
      debugPrint('OrderActionView: 🎯 New Status: $newStatus');
      debugPrint('OrderActionView: 🎯 Action Name: $actionName');
      
      setState(() {
        _isUpdating = true;
      });

      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        throw Exception('Partner ID not found');
      }

      debugPrint('OrderActionView: 🔄 Partner ID: $partnerId');

      final success = await OrderService.updateOrderStatus(
        partnerId: partnerId,
        orderId: widget.orderId,
        newStatus: newStatus,
      );

      debugPrint('OrderActionView: ✅ OrderService result: $success');

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Order $actionName successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Navigate to orders screen after successful update
        _navigateToOrders();
      } else {
        throw Exception('Failed to update order status - API returned false');
      }
    } catch (e) {
      debugPrint('OrderActionView: ❌ Error updating order status: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to $actionName order: ${e.toString().replaceAll('Exception: ', '')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _navigateToOrders() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.orders,
      (route) => false,
    );
  }

  void _navigateToOrderDetails() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.orders,
      (route) => false,
      arguments: widget.orderId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.homePage,
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: ColorManager.background,
        appBar: AppBar(
          backgroundColor: ColorManager.primary,
          elevation: 0,
          title: Text(
            'Order Action Required',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeightManager.semiBold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _navigateToOrders(),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading order details...'),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeightManager.semiBold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadOrderDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.primary,
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : _order == null
                    ? const Center(child: Text('Order not found'))
                    : _buildOrderActionContent(),
      ),
    );
  }

  Widget _buildOrderActionContent() {
    final order = _order!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.orderId}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeightManager.semiBold,
                          color: ColorManager.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.orderStatus),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          OrderService.formatOrderStatus(order.orderStatus),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeightManager.medium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Customer', order.userName),
                  const SizedBox(height: 8),
                  _buildInfoRow('Total Amount', '₹${order.totalAmount}'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Order Date & Time',
                      order.datetime != null ? TimeUtils.formatStatusTimelineDate(order.datetime!) : '-'),
                  if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('Delivery Address', order.deliveryAddress!),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Order Items
          if (order.items.isNotEmpty) ...[
            Text(
              'Order Items',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeightManager.semiBold,
              ),
            ),
            const SizedBox(height: 12),
            ...order.items.map((item) => Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getItemDisplayName(item),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeightManager.medium,
                            ),
                          ),
                          Text(
                            'Qty: ${item.quantity}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${item.itemPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeightManager.medium,
                        color: ColorManager.primary,
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
            const SizedBox(height: 24),
          ],

          // Action Buttons
          if (order.orderStatus.toUpperCase() == 'PENDING' || order.orderStatus.toUpperCase() == 'CONFIRMED') ...[
            Text(
              'Action Required',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeightManager.semiBold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating ? null : () => _updateOrderStatus('CANCELLED', 'rejected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _isUpdating 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.cancel, color: Colors.white),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeightManager.semiBold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating ? null : () => _updateOrderStatus('CONFIRMED', 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _isUpdating 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle, color: Colors.white),
                    label: Text(
                      'Accept',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeightManager.semiBold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This order has already been ${order.orderStatus.toLowerCase()}. You will be redirected to order details.',
                        style: GoogleFonts.poppins(
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToOrderDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'View Order Details',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeightManager.semiBold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeightManager.medium,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PREPARING':
        return Colors.purple;
      case 'READY_FOR_DELIVERY':
        return Colors.indigo;
      case 'OUT_FOR_DELIVERY':
        return Colors.teal;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getItemDisplayName(OrderItem item) {
    final menuItem = _menuItems[item.menuId];
    if (menuItem != null) {
      return menuItem.name;
    }
    return item.itemName ?? 'Item: ${item.menuId}';
  }
}