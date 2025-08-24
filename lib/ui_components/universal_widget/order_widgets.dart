// lib/ui_components/universal_widget/order_widgets.dart
// COMPLETELY FIXED VERSION

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/resources/colors.dart';
import '../../presentation/resources/font.dart';
import '../../presentation/screens/chat/bloc.dart';
import '../../presentation/screens/chat/event.dart';
import '../../presentation/screens/chat/state.dart';
import '../../presentation/screens/chat/view.dart';
import '../../services/menu_item_service.dart';
import '../../services/order_service.dart';
import '../../services/currency_service.dart';
import '../../services/attribute_service.dart';
import '../../models/attribute_model.dart';
import '../../utils/time_utils.dart';

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
          debugPrint('OrderDetailsWidget: Current state: ${state.runtimeType}');
          
          if (state is OrderDetailsLoading) {
            debugPrint('OrderDetailsWidget: Showing OrderDetailsLoading');
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE17A47)),
            );
          }
          
          if (state is ChatLoaded && state.orderDetails != null) {
            debugPrint('OrderDetailsWidget: ChatLoaded with orderDetails - ${state.orderDetails!.orderId}');
            return _buildOrderDetails(context, state.orderDetails!, state.menuItems);
          }
          
          if (state is OrderDetailsLoaded) {
            debugPrint('OrderDetailsWidget: OrderDetailsLoaded - ${state.orderDetails.orderId}');
            return _buildOrderDetails(context, state.orderDetails, state.menuItems ?? {});
          }
          
          if (state is OrderDetailsError) {
            debugPrint('OrderDetailsWidget: OrderDetailsError - ${state.message}');
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
          
          debugPrint('OrderDetailsWidget: Default loading state - waiting for event');
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
          _buildRestaurantHeader(orderDetails),
          const SizedBox(height: 18),
          _buildOrderItemsAndSummary(orderDetails, menuItems),
          const SizedBox(height: 18),
          _buildOrderStatus(orderDetails),
        ],
      ),
    );
  }

    Widget _buildRestaurantHeader(OrderDetails orderDetails) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: ColorManager.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restaurant Name', // This should come from orderDetails if available
                      style: TextStyle(
                        color: ColorManager.black,
                        fontSize: 18,
                        fontWeight: FontWeightManager.bold,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            orderDetails.deliveryAddress ?? 'Restaurant Location',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontFamily: FontFamily.Montserrat,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: OrderService.getStatusColor(orderDetails.orderStatus).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: OrderService.getStatusColor(orderDetails.orderStatus).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  OrderService.formatOrderStatus(orderDetails.orderStatus),
                  style: TextStyle(
                    color: OrderService.getStatusColor(orderDetails.orderStatus),
                    fontSize: 12,
                    fontWeight: FontWeightManager.semiBold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Customer Information Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorManager.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorManager.primary.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: ColorManager.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Customer Information',
                      style: TextStyle(
                        color: ColorManager.black,
                        fontSize: 16,
                        fontWeight: FontWeightManager.semiBold,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCustomerInfoRow('Name', orderDetails.userName, Icons.person_outline),
                _buildCustomerInfoRow('Order ID', orderDetails.orderId, Icons.tag),
                if (orderDetails.deliveryAddress != null && orderDetails.deliveryAddress!.isNotEmpty)
                  _buildCustomerInfoRow('Delivery Address', orderDetails.deliveryAddress!, Icons.location_on),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>?>(
            future: OrderService.fetchOrderReview(
              partnerId: orderDetails.partnerId,
              orderId: orderDetails.orderId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              
              if (snapshot.hasData && snapshot.data != null) {
                final reviewData = snapshot.data!;
                final rating = reviewData['rating'] ?? 0;
                final reviewText = reviewData['review_text'] ?? '';
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorManager.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColorManager.primary.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: const Color(0xFFFFC107),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Food Rating',
                            style: TextStyle(
                              color: ColorManager.black,
                              fontSize: 16,
                              fontWeight: FontWeightManager.semiBold,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                Icons.star,
                                color: index < rating 
                                    ? const Color(0xFFFFC107)
                                    : Colors.grey[300],
                                size: 18,
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$rating/5',
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontSize: 14,
                              fontWeight: FontWeightManager.bold,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ],
                      ),
                      if (reviewText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"$reviewText"',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontFamily: FontFamily.Montserrat,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_border,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No rating available',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: ColorManager.primary,
              size: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ColorManager.textGrey,
                    fontSize: 10,
                    fontWeight: FontWeightManager.medium,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: 12,
                    fontWeight: FontWeightManager.semiBold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsAndSummary(OrderDetails orderDetails, Map<String, MenuItem> menuItems) {
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
          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 16),
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
                  // Delivery Fees row (only if > 0)
                  if (orderDetails.deliveryFeesDouble > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Text(
                        //   'Delivery Fees',
                        //   style: TextStyle(
                        //     color: Colors.grey[700],
                        //     fontSize: 15,
                        //     fontFamily: FontFamily.Montserrat,
                        //   ),
                        // ),
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
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 8),
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
          if (orderDetails.datetime != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorManager.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: ColorManager.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Placed on: ${TimeUtils.formatStatusTimelineDate(orderDetails.datetime!)} IST',
                      style: TextStyle(
                        color: ColorManager.primary,
                        fontSize: 14,
                        fontWeight: FontWeightManager.semiBold,
                        fontFamily: FontFamily.Montserrat,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  
}



// StatusChangeBottomSheet Widget - FOR CHAT SCREEN ONLY
class StatusChangeBottomSheet extends StatefulWidget {
  final String orderId;
  final String partnerId;
  final VoidCallback? onStatusUpdateSuccess;

  const StatusChangeBottomSheet({
    Key? key,
    required this.orderId,
    required this.partnerId,
    this.onStatusUpdateSuccess,
  }) : super(key: key);

  @override
  State<StatusChangeBottomSheet> createState() => _StatusChangeBottomSheetState();
}

class _StatusChangeBottomSheetState extends State<StatusChangeBottomSheet> {
  bool _isUpdating = false;
  late StreamSubscription<ChatState> _stateSubscription;
  Timer? _fallbackTimer;
  Timer? _stateCheckTimer;

  @override
  void initState() {
    super.initState();
    
    // Listen to ChatBloc state changes
    _stateSubscription = context.read<ChatBloc>().stream.listen((state) {
      if (!mounted || !_isUpdating) return;
      
      debugPrint('StatusChangeBottomSheet: Stream listener - State: ${state.runtimeType}');
      
      if (state is ChatLoaded) {
        debugPrint('StatusChangeBottomSheet: ChatLoaded state - isUpdatingOrderStatus: ${state.isUpdatingOrderStatus}, lastUpdateSuccess: ${state.lastUpdateSuccess}, lastUpdateTimestamp: ${state.lastUpdateTimestamp}');
        
        // Check if this is a status update response - either success or error
        if (state.lastUpdateTimestamp != null && state.isUpdatingOrderStatus == false) {
          if (state.lastUpdateSuccess == true) {
            debugPrint('StatusChangeBottomSheet: Success detected');
            _handleSuccess();
          } else if (state.lastUpdateSuccess == false) {
            debugPrint('StatusChangeBottomSheet: Error detected - ${state.lastUpdateMessage}');
            _handleError(state.lastUpdateMessage ?? 'Failed to update order status');
          }
        }
        
        // Additional check: if we've been updating for too long and the state shows not updating, handle it
        if (_isUpdating && state.isUpdatingOrderStatus == false && state.lastUpdateTimestamp == null) {
          debugPrint('StatusChangeBottomSheet: Detected state reset without timestamp, treating as success');
          _handleSuccess();
        }
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    _fallbackTimer?.cancel();
    _stateCheckTimer?.cancel();
    super.dispose();
  }

  void _handleSuccess() {
    debugPrint('StatusChangeBottomSheet: _handleSuccess called');
    if (!mounted || !_isUpdating) {
      debugPrint('StatusChangeBottomSheet: _handleSuccess - not mounted or not updating');
      return;
    }
    
    debugPrint('StatusChangeBottomSheet: _handleSuccess - cancelling timers');
    _fallbackTimer?.cancel();
    _stateCheckTimer?.cancel();
    
    debugPrint('StatusChangeBottomSheet: _handleSuccess - setting isUpdating to false');
    setState(() {
      _isUpdating = false;
    });

    debugPrint('StatusChangeBottomSheet: _handleSuccess - closing bottom sheet');
    Navigator.of(context).pop();
    debugPrint('StatusChangeBottomSheet: _handleSuccess - bottom sheet closed');
    
    // Call the success callback if provided
    if (widget.onStatusUpdateSuccess != null) {
      debugPrint('StatusChangeBottomSheet: Calling success callback');
      widget.onStatusUpdateSuccess!();
    }
  }

  void _handleError(String message) {
    debugPrint('StatusChangeBottomSheet: _handleError called with message: $message');
    if (!mounted || !_isUpdating) {
      debugPrint('StatusChangeBottomSheet: _handleError - not mounted or not updating');
      return;
    }
    
    _fallbackTimer?.cancel();
    _stateCheckTimer?.cancel();
    setState(() {
      _isUpdating = false;
    });

    debugPrint('StatusChangeBottomSheet: _handleError - closing bottom sheet');
    Navigator.of(context).pop();
  }

  Future<void> _fetchAndUpdateOrderDetails() async {
    try {
      debugPrint('StatusChangeBottomSheet: Fetching order details directly...');
      debugPrint('StatusChangeBottomSheet: Partner ID: ${widget.partnerId}, Order ID: ${widget.orderId}');
      
      final orderDetails = await OrderService.getOrderDetails(
        partnerId: widget.partnerId,
        orderId: widget.orderId,
      );
      
      debugPrint('StatusChangeBottomSheet: Order details fetch completed');
      
      if (orderDetails != null) {
        debugPrint('StatusChangeBottomSheet: Direct order details fetch successful - Status: ${orderDetails.orderStatus}');
        
        // Update the ChatBloc state directly
        final chatBloc = context.read<ChatBloc>();
        final currentState = chatBloc.state;
        
        debugPrint('StatusChangeBottomSheet: Current ChatBloc state: ${currentState.runtimeType}');
        
        if (currentState is ChatLoaded) {
          final actualOrderStatus = OrderService.formatOrderStatus(orderDetails.orderStatus);
          debugPrint('StatusChangeBottomSheet: Formatted status: $actualOrderStatus');
          
          // Update the order info with new status
          final updatedOrderInfo = currentState.orderInfo.copyWith(
            status: actualOrderStatus,
          );
          
          debugPrint('StatusChangeBottomSheet: About to emit updated state');
          
          // Emit updated state
          chatBloc.emit(currentState.copyWith(
            orderInfo: updatedOrderInfo,
            orderDetails: orderDetails,
          ));
          
          debugPrint('StatusChangeBottomSheet: Direct state update completed - New status: $actualOrderStatus');
        } else {
          debugPrint('StatusChangeBottomSheet: ChatBloc not in ChatLoaded state, cannot update');
        }
      } else {
        debugPrint('StatusChangeBottomSheet: Direct order details fetch returned null');
      }
    } catch (e) {
      debugPrint('StatusChangeBottomSheet: Direct order details fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine current status from ChatBloc to compute allowed next statuses
    final chatState = context.read<ChatBloc>().state;
    String currentStatus = 'PENDING';
    if (chatState is ChatLoaded) {
      final rawStatus = chatState.orderDetails?.orderStatus ?? chatState.orderInfo.status;
      if (rawStatus != null) {
        currentStatus = rawStatus.toUpperCase().replaceAll(' ', '_');
      }
    }

    // Compute allowed next statuses for partner (removes previous statuses automatically)
    final availableStatuses = OrderService.getPartnerAvailableStatusOptions(currentStatus);

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
          // Text(
          //   'Select New Status:',
          //   style: TextStyle(
          //     color: ColorManager.black,
          //     fontSize: 16,
          //     fontWeight: FontWeightManager.medium,
          //     fontFamily: FontFamily.Montserrat,
          //   ),
          // ),
          
          const SizedBox(height: 12),
          
          // Show partner-specific allowed status options based on current status
          ...availableStatuses.map((status) => _buildStatusOption(
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
    debugPrint('StatusChangeBottomSheet: Starting status update to: $newStatus');
    
    setState(() {
      _isUpdating = true;
    });

    // Try direct API call first as a fallback
    try {
      debugPrint('StatusChangeBottomSheet: Attempting direct API call...');
      
      final success = await OrderService.updateOrderStatus(
        partnerId: widget.partnerId,
        orderId: widget.orderId,
        newStatus: newStatus,
      );
      
      if (success) {
        debugPrint('StatusChangeBottomSheet: Direct API call successful');
        
        // Show success message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Order status updated to ${OrderService.formatOrderStatus(newStatus)}',
                    style: const TextStyle(
                      fontWeight: FontWeightManager.medium,
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
        
        // SIMPLE SOLUTION: Just reload the chat data immediately after successful status update
        debugPrint('StatusChangeBottomSheet: Status update successful, reloading chat data...');
        
        // Store the context and bloc reference
        final chatBloc = context.read<ChatBloc>();
        final orderId = widget.orderId;
        
        // Immediately reload the entire chat data to get fresh order details
        debugPrint('StatusChangeBottomSheet: Triggering immediate chat reload...');
        debugPrint('StatusChangeBottomSheet: ChatBloc state before reload: ${chatBloc.state.runtimeType}');
        
        // Try multiple approaches to ensure the reload happens
        try {
          chatBloc.add(LoadChatData(orderId));
          debugPrint('StatusChangeBottomSheet: Chat reload event dispatched');
        } catch (e) {
          debugPrint('StatusChangeBottomSheet: Error dispatching LoadChatData: $e');
        }
        
        // Also try using the global method
        try {
          ChatView.forceRefreshCurrentChat(context, orderId);
          debugPrint('StatusChangeBottomSheet: Global force refresh called');
        } catch (e) {
          debugPrint('StatusChangeBottomSheet: Error calling global force refresh: $e');
        }
        
        debugPrint('StatusChangeBottomSheet: ChatBloc state after reload: ${chatBloc.state.runtimeType}');
        
        // Also show a success message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Order status updated to ${OrderService.formatOrderStatus(newStatus)}',
                    style: const TextStyle(
                      fontWeight: FontWeightManager.medium,
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
        
        _handleSuccess();
        return;
      } else {
        debugPrint('StatusChangeBottomSheet: Direct API call failed');
      }
    } catch (e) {
      debugPrint('StatusChangeBottomSheet: Direct API call error: $e');
    }

    // Fallback to ChatBloc approach
    debugPrint('StatusChangeBottomSheet: Falling back to ChatBloc approach...');
    
    // Check if ChatBloc is in the correct state before proceeding
    final chatBloc = context.read<ChatBloc>();
    final currentState = chatBloc.state;
    
    debugPrint('StatusChangeBottomSheet: Current ChatBloc state: ${currentState.runtimeType}');
    
    if (currentState is! ChatLoaded) {
      debugPrint('StatusChangeBottomSheet: ChatBloc not in ChatLoaded state, triggering chat load first...');
      
      // Trigger chat loading first
      chatBloc.add(LoadChatData(widget.orderId));
      
      // Wait for ChatLoaded state with timeout
      bool stateReady = false;
      
      _stateCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!mounted || !_isUpdating) {
          timer.cancel();
          return;
        }
        
        final currentState = chatBloc.state;
        debugPrint('StatusChangeBottomSheet: Checking state: ${currentState.runtimeType}');
        
        if (currentState is ChatLoaded) {
          debugPrint('StatusChangeBottomSheet: ChatBloc now in ChatLoaded state, proceeding with update');
          stateReady = true;
          timer.cancel();
          
          // Now proceed with the status update
          chatBloc.add(UpdateOrderStatus(
            orderId: widget.orderId,
            partnerId: widget.partnerId,
            newStatus: newStatus,
          ));
          
          debugPrint('StatusChangeBottomSheet: UpdateOrderStatus event added to ChatBloc');
        }
      });
      
      // Timeout after 15 seconds (increased for chat loading)
      Timer(const Duration(seconds: 15), () {
        if (!stateReady && mounted && _isUpdating) {
          debugPrint('StatusChangeBottomSheet: Timeout waiting for ChatLoaded state');
          _stateCheckTimer?.cancel();
          setState(() {
            _isUpdating = false;
          });
          Navigator.of(context).pop();
        }
      });
      
      return;
    }

    // Use ChatBloc to update status - the stream listener will handle the response
    context.read<ChatBloc>().add(UpdateOrderStatus(
      orderId: widget.orderId,
      partnerId: widget.partnerId,
      newStatus: newStatus,
    ));

    debugPrint('StatusChangeBottomSheet: UpdateOrderStatus event added to ChatBloc');

    // Add a timeout to prevent infinite loading
    Timer(const Duration(seconds: 10), () {
      if (mounted && _isUpdating) {
        debugPrint('StatusChangeBottomSheet: Timeout reached, resetting loading state');
        setState(() {
          _isUpdating = false;
        });
        Navigator.of(context).pop();
      }
    });

    // Add a fallback timer that checks the ChatBloc state every 2 seconds
    _fallbackTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || !_isUpdating) {
        timer.cancel();
        return;
      }
      
      final chatBloc = context.read<ChatBloc>();
      final currentState = chatBloc.state;
      
      if (currentState is ChatLoaded) {
        debugPrint('StatusChangeBottomSheet: Fallback check - isUpdatingOrderStatus: ${currentState.isUpdatingOrderStatus}, lastUpdateSuccess: ${currentState.lastUpdateSuccess}');
        
        if (currentState.isUpdatingOrderStatus == false && currentState.lastUpdateTimestamp != null) {
          debugPrint('StatusChangeBottomSheet: Fallback detected completion');
          timer.cancel();
          
          if (currentState.lastUpdateSuccess == true) {
            _handleSuccess();
          } else {
            _handleError(currentState.lastUpdateMessage ?? 'Failed to update order status');
          }
        }
      }
    });
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