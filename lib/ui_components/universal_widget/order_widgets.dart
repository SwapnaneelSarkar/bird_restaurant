// lib/ui_components/universal_widget/order_widgets.dart
// COMPLETELY FIXED VERSION

import 'dart:async';
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
import '../../services/currency_service.dart';
import '../../services/attribute_service.dart';
import '../../models/attribute_model.dart';

class OrderDetailsWidget extends StatelessWidget {
  const OrderDetailsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: TextStyle(
            color: ColorManager.primary,
            fontWeight: FontWeightManager.bold,
            fontFamily: FontFamily.Montserrat,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: ColorManager.primary),
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
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
                      backgroundColor: ColorManager.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(orderDetails),
          const SizedBox(height: 18),
          _buildOrderItems(orderDetails, menuItems),
          const SizedBox(height: 18),
          _buildOrderSummary(orderDetails),
          const SizedBox(height: 18),
          _buildOrderStatus(orderDetails),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(OrderDetails orderDetails) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: ColorManager.primary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: ColorManager.primary, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order #${orderDetails.orderId.length > 8 ? orderDetails.orderId.substring(orderDetails.orderId.length - 8) : orderDetails.orderId}',
                  style: TextStyle(
                    color: ColorManager.primary,
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
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'User ID: ${orderDetails.userId.length > 12 ? orderDetails.userId.substring(orderDetails.userId.length - 12) : orderDetails.userId}',
                  style: TextStyle(
                    color: Colors.grey[700],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: ColorManager.primary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: ColorManager.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order Items (${orderDetails.items.length})',
                  style: TextStyle(
                    color: ColorManager.primary,
                    fontSize: 18,
                    fontWeight: FontWeightManager.bold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...orderDetails.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: ColorManager.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorManager.primary.withOpacity(0.06)),
              ),
              child: FutureBuilder<AttributeResponse>(
                future: AttributeService.getAttributes(item.menuId),
                builder: (context, snapshot) {
                  List<Widget> attributeWidgets = [];
                  final itemAttributes = (item.attributes != null && item.attributes!.isNotEmpty)
                    ? item.attributes!
                    : null;
                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.data != null && itemAttributes != null) {
                    final attributes = snapshot.data!.data!;
                    itemAttributes.forEach((attributeId, valueId) {
                      final attributeGroup = attributes.firstWhere(
                        (attr) => attr.attributeId == attributeId,
                        orElse: () => AttributeGroup(
                          attributeId: '',
                          menuId: '',
                          name: 'Unknown Attribute',
                          type: '',
                          isRequired: 0,
                          createdAt: '',
                          updatedAt: '',
                          attributeValues: [],
                        ),
                      );
                      final value = attributeGroup.attributeValues.firstWhere(
                        (val) => val.valueId == valueId,
                        orElse: () => AttributeValue(name: 'Unknown Value'),
                      );
                      attributeWidgets.add(
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0, left: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.label_important, color: ColorManager.primary, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${attributeGroup.name}: ',
                                style: TextStyle(
                                  color: ColorManager.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeightManager.medium,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                              Text(
                                value.name ?? '',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 13,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              menuItems[item.menuId]?.name ?? 'Item',
                              style: TextStyle(
                                color: ColorManager.black,
                                fontSize: 16,
                                fontWeight: FontWeightManager.medium,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ),
                          Text(
                            'x${item.quantity}',
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontSize: 15,
                              fontWeight: FontWeightManager.bold,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\u20B9${item.itemPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontSize: 15,
                              fontWeight: FontWeightManager.bold,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ],
                      ),
                      ...attributeWidgets,
                    ],
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(OrderDetails orderDetails) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColorManager.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: ColorManager.primary.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: ColorManager.primary, size: 22),
              const SizedBox(width: 12),
              Text(
                'Order Summary',
                style: TextStyle(
                  color: ColorManager.primary,
                  fontSize: 18,
                  fontWeight: FontWeightManager.bold,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<String>(
            future: CurrencyService().getCurrencySymbol(),
            builder: (context, snapshot) {
              final symbol = snapshot.data ?? '';
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                      Text(
                        orderDetails.formattedTotal(symbol),
                        style: TextStyle(
                          color: ColorManager.black,
                          fontSize: 15,
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
                          color: Colors.grey[700],
                          fontSize: 15,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                      Text(
                        orderDetails.formattedDeliveryFees(symbol),
                        style: TextStyle(
                          color: ColorManager.black,
                          fontSize: 15,
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
                          color: ColorManager.primary,
                          fontSize: 18,
                          fontWeight: FontWeightManager.bold,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                      Text(
                        orderDetails.formattedGrandTotal(symbol),
                        style: TextStyle(
                          color: ColorManager.primary,
                          fontSize: 18,
                          fontWeight: FontWeightManager.bold,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus(OrderDetails orderDetails) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: ColorManager.primary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: ColorManager.primary, size: 22),
              const SizedBox(width: 12),
              Text(
                'Order Status',
                style: TextStyle(
                  color: ColorManager.primary,
                  fontSize: 18,
                  fontWeight: FontWeightManager.bold,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: OrderService.getStatusColor(orderDetails.orderStatus).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  OrderService.getStatusIcon(orderDetails.orderStatus),
                  color: OrderService.getStatusColor(orderDetails.orderStatus),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  OrderService.formatOrderStatus(orderDetails.orderStatus),
                  style: TextStyle(
                    color: OrderService.getStatusColor(orderDetails.orderStatus),
                    fontSize: 16,
                    fontWeight: FontWeightManager.bold,
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
}

// StatusChangeBottomSheet Widget - FOR CHAT SCREEN ONLY
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
  late StreamSubscription<ChatState> _stateSubscription;

  @override
  void initState() {
    super.initState();
    
    // Listen to ChatBloc state changes
    _stateSubscription = context.read<ChatBloc>().stream.listen((state) {
      if (!mounted || !_isUpdating) return;
      
      debugPrint('StatusChangeBottomSheet: Stream listener - State: ${state.runtimeType}');
      
      if (state is ChatLoaded) {
        // Check if this is a status update response
        if (state.lastUpdateTimestamp != null) {
          if (state.lastUpdateSuccess == true) {
            debugPrint('StatusChangeBottomSheet: Success detected');
            _handleSuccess();
          } else if (state.lastUpdateSuccess == false) {
            debugPrint('StatusChangeBottomSheet: Error detected - ${state.lastUpdateMessage}');
            _handleError(state.lastUpdateMessage ?? 'Failed to update order status');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    super.dispose();
  }

  void _handleSuccess() {
    if (!mounted || !_isUpdating) return;
    
    setState(() {
      _isUpdating = false;
    });

    Navigator.of(context).pop();
    
    // Show success message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Order status updated successfully!',
                    style: const TextStyle(
                      fontWeight: FontWeightManager.medium,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  void _handleError(String message) {
    if (!mounted || !_isUpdating) return;
    
    setState(() {
      _isUpdating = false;
    });

    Navigator.of(context).pop();
    
    // Show error message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
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
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get available status options
    final allStatuses = OrderService.getAllValidStatuses();

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
          
          const SizedBox(height: 20),
          
          // Show status options
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
          
          // Show all status options
          ...allStatuses.map((status) => _buildStatusOption(
            status: status,
            onTap: () => _updateOrderStatus(status),
          )),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusOption({
    required String status,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _isUpdating ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Status emoji and icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OrderService.getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      OrderService.getStatusEmoji(status),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      OrderService.getStatusIcon(status),
                      color: OrderService.getStatusColor(status),
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
                    Text(
                      OrderService.formatOrderStatus(status),
                      style: TextStyle(
                        color: ColorManager.black,
                        fontSize: 14,
                        fontWeight: FontWeightManager.medium,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      OrderService.getStatusDescription(status),
                      style: TextStyle(
                        color: Colors.grey[600],
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
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    // Use ChatBloc to update status - the stream listener will handle the response
    context.read<ChatBloc>().add(UpdateOrderStatus(
      orderId: widget.orderId,
      partnerId: widget.partnerId,
      newStatus: newStatus,
    ));
  }
}

// Order Options Bottom Sheet Widget - FOR CHAT SCREEN ONLY
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
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderDetailsWidget(),
                ),
              );
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
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => StatusChangeBottomSheet(
                  orderId: orderId,
                  partnerId: partnerId,
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