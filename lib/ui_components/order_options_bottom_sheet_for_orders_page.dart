import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order_model.dart';
import '../constants/enums.dart';
import '../constants/api_constants.dart';
import '../services/token_service.dart';
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
  
  const OrderOptionsBottomSheetForOrdersPage({
    Key? key, 
    required this.order, 
    required this.ordersBloc
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
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              
              final fullOrder = await OrderService.fetchOrderDetailsById(order.id);
              
              if (Navigator.canPop(context)) Navigator.pop(context);
              
              if (fullOrder != null) {
                if (Navigator.canPop(context)) Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailsStandalone(order: fullOrder),
                  ),
                );
              } else {
                if (Navigator.canPop(context)) Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error'),
                    content: const Text('Could not load order details.'),
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

class OrderDetailsStandalone extends StatefulWidget {
  final Order order;
  
  const OrderDetailsStandalone({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderDetailsStandalone> createState() => _OrderDetailsStandaloneState();
}

class _OrderDetailsStandaloneState extends State<OrderDetailsStandalone> {
  String? freshUserName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFreshUserName();
  }

  Future<void> _fetchFreshUserName() async {
    try {
      print('🔍 Fetching fresh user name for user_id: ${widget.order.userId}');
      
      final token = await TokenService.getToken();
      if (token == null) {
        print('❌ No token available');
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      // Use the user API endpoint with user_id from the order
      final url = Uri.parse('${ApiConstants.baseUrl}/user/${widget.order.userId}');
      print('🔍 Making API call to: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🔍 API Response status: ${response.statusCode}');
      print('🔍 API Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        if (responseBody['status'] == true && responseBody['data'] != null) {
          final data = responseBody['data'];
          final username = data['username'];
          
          print('🔍 Extracted username from user API: "$username"');
          
          if (username != null && username.toString().trim().isNotEmpty) {
            setState(() {
              freshUserName = username.toString().trim(); // Remove any trailing spaces
              isLoading = false;
            });
            print('✅ Set freshUserName to: "$freshUserName"');
          } else {
            print('⚠️ username is null or empty');
            setState(() {
              isLoading = false;
            });
          }
        } else {
          print('❌ API response status not true or no data');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('❌ API call failed with status: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching fresh user name: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getDisplayCustomerName() {
    // First priority: freshUserName from direct API call
    if (freshUserName != null && freshUserName!.isNotEmpty) {
      print('✅ Using fresh user name: "$freshUserName"');
      return freshUserName!;
    }
    
    // Second priority: customerName from order (if it looks like a real name)
    String customerName = widget.order.customerName;
    print('🔍 Checking order.customerName: "$customerName"');
    
    if (customerName.isNotEmpty && customerName.length <= 15 && customerName.contains(' ')) {
      print('✅ Using order customerName: "$customerName"');
      return customerName;
    }
    
    // Third priority: phone number
    if (widget.order.customerPhone != null && widget.order.customerPhone!.isNotEmpty) {
      print('✅ Using phone: "${widget.order.customerPhone}"');
      return widget.order.customerPhone!;
    }
    
    // Final fallback
    print('⚠️ Using fallback: "Customer"');
    return 'Customer';
  }

  @override
  Widget build(BuildContext context) {
    final customerName = _getDisplayCustomerName();
    
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
      body: isLoading
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderHeader(customerName),
                  const SizedBox(height: 16),
                  _buildOrderItems(),
                  const SizedBox(height: 16),
                  _buildOrderSummary(),
                  const SizedBox(height: 16),
                  _buildOrderStatus(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderHeader(String customerName) {
    return Container(
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
            _buildInfoRow('Order ID', widget.order.id.length > 20 ? '${widget.order.id.substring(0, 20)}...' : widget.order.id, Icons.tag),
            _buildInfoRow('Customer', customerName, Icons.person),
            if (widget.order.customerPhone != null && widget.order.customerPhone!.isNotEmpty) 
              _buildInfoRow('Phone', widget.order.customerPhone!, Icons.phone),
            if (widget.order.deliveryAddress != null && widget.order.deliveryAddress!.isNotEmpty) 
              _buildInfoRow('Address', widget.order.deliveryAddress!, Icons.location_on),
            _buildInfoRow('Date', TimeUtils.formatStatusTimelineDate(widget.order.date), Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
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

  Widget _buildOrderItems() {
    return Container(
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
                        '${widget.order.items?.length ?? 0} items ordered',
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
            if (widget.order.items != null && widget.order.items!.isNotEmpty)
              ...widget.order.items!.map((item) => _buildOrderItem(item)).toList()
            else
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
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return FutureBuilder<MenuItem?>(
      future: MenuItemService.getMenuItem(item.menuId),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? 'Item';
        final price = snapshot.data?.price ?? item.price;
        final description = snapshot.data?.description ?? '';
        
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
          child: Row(
            children: [
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
                child: Icon(
                  Icons.restaurant,
                  color: ColorManager.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
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
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Qty: ${item.quantity} • ₹${price.toStringAsFixed(2)} each',
                      style: TextStyle(
                        color: ColorManager.textGrey,
                        fontSize: FontSize.s10,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
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
      },
    );
  }

  Widget _buildOrderSummary() {
    final deliveryFee = widget.order.deliveryFees;
    final subtotal = _calculateSubtotal();
    final total = subtotal + deliveryFee;
    return Container(
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
                Text(
                  'Order Summary',
                  style: TextStyle(
                    color: ColorManager.primary,
                    fontWeight: FontWeightManager.bold,
                    fontSize: FontSize.s16,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
            _buildSummaryRow('Delivery Fee', '₹${deliveryFee.toStringAsFixed(2)}'),
            const Divider(),
            _buildSummaryRow('Total', '₹${total.toStringAsFixed(2)}', isTotal: true),
          ],
        ),
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

  Widget _buildOrderStatus() {
    return Container(
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
                Text(
                  'Order Status',
                  style: TextStyle(
                    color: ColorManager.primary,
                    fontWeight: FontWeightManager.bold,
                    fontSize: FontSize.s16,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.order.orderStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(widget.order.orderStatus).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(widget.order.orderStatus),
                    color: _getStatusColor(widget.order.orderStatus),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.order.orderStatus.displayName,
                    style: TextStyle(
                      color: _getStatusColor(widget.order.orderStatus),
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
    );
  }

  double _calculateSubtotal() {
    if (widget.order.items == null || widget.order.items!.isEmpty) {
      return widget.order.amount;
    }
    return widget.order.items!.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
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
        return Colors.grey;
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