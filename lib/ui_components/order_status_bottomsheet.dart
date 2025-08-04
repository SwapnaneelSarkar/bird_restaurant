// lib/ui_components/order_status_bottomsheet.dart
// CREATE THIS NEW FILE FOR ORDERS PAGE

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/enums.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import '../presentation/screens/orders/bloc.dart';
import '../presentation/screens/orders/event.dart';
import '../presentation/screens/orders/state.dart';
import '../services/order_service.dart';

class OrderStatusBottomSheet extends StatefulWidget {
  final String orderId;
  final OrderStatus currentStatus;
  final OrdersBloc ordersBloc;

  const OrderStatusBottomSheet({
    Key? key,
    required this.orderId,
    required this.currentStatus,
    required this.ordersBloc,
  }) : super(key: key);

  @override
  State<OrderStatusBottomSheet> createState() => _OrderStatusBottomSheetState();
}

class _OrderStatusBottomSheetState extends State<OrderStatusBottomSheet> {
  bool _isUpdating = false;
  late StreamSubscription<OrdersState> _stateSubscription;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    
    // Use the passed OrdersBloc instance
    try {
      // Listen to OrdersBloc state changes directly
      _stateSubscription = widget.ordersBloc.stream.listen((state) {
        debugPrint('OrderStatusBottomSheet: Stream listener - State: ${state.runtimeType}');
        debugPrint('OrderStatusBottomSheet: _isUpdating: $_isUpdating, mounted: $mounted');
        
        if (!mounted || !_isUpdating) {
          debugPrint('OrderStatusBottomSheet: Ignoring state change - not updating or not mounted');
          return;
        }
        
        if (state is OrderStatusUpdateSuccess) {
          debugPrint('OrderStatusBottomSheet: Success detected - ${state.message}');
          _handleSuccess(state.message);
        } else if (state is OrderStatusUpdateError) {
          debugPrint('OrderStatusBottomSheet: Error detected - ${state.message}');
          _handleError(state.message);
        } else if (state is OrdersLoaded) {
          // This means the orders were reloaded after successful update OR after error
          if (_isUpdating) {
            debugPrint('OrderStatusBottomSheet: Orders reloaded after status update attempt');
            // Don't show success message here since we already handled success/error above
            // Just close the bottom sheet
            _closeBottomSheet();
          }
        } else {
          debugPrint('OrderStatusBottomSheet: Received other state: ${state.runtimeType}');
        }
      });
    } catch (e) {
      debugPrint('OrderStatusBottomSheet: Could not access OrdersBloc: $e');
      // Handle the case where OrdersBloc is not available
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to access orders. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _closeBottomSheet() {
    if (!mounted || !_isUpdating) return;
    
    _timeoutTimer?.cancel();
    
    setState(() {
      _isUpdating = false;
    });

    Navigator.of(context).pop();
  }

  void _handleSuccess(String message) {
    if (!mounted || !_isUpdating) return;
    
    _timeoutTimer?.cancel();
    
    setState(() {
      _isUpdating = false;
    });

    Navigator.of(context).pop();
  }

  void _handleError(String message) {
    if (!mounted || !_isUpdating) return;
    
    _timeoutTimer?.cancel();
    
    setState(() {
      _isUpdating = false;
    });

    Navigator.of(context).pop();
  }

  void _handleTimeout() {
    if (!mounted || !_isUpdating) return;
    
    debugPrint('OrderStatusBottomSheet: Request timeout');
    _handleError('Request timeout. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    // Get partner-specific status options (excluding PENDING and delivery-related statuses)
    final partnerStatuses = OrderService.getPartnerValidStatuses()
        .where((status) => status != 'PENDING') // Remove PENDING since it's default
        .map((status) => OrderStatus.values.firstWhere(
            (enumStatus) => enumStatus.apiValue == status,
            orElse: () => OrderStatus.pending))
        .toList();

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
          
          // Show partner-specific status options
          ...partnerStatuses.map((status) => _buildStatusOption(
            status: status,
            isCurrent: status == widget.currentStatus,
            onTap: () {
              if (status == widget.currentStatus) {
                _showInfoSnackBar('Order is already in ${status.displayName} status');
                return;
              }
              _updateOrderStatus(status);
            },
          )),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusOption({
    required OrderStatus status,
    required bool isCurrent,
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
            color: isCurrent
                ? OrderService.getStatusColor(status.apiValue).withOpacity(0.1)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? OrderService.getStatusColor(status.apiValue).withOpacity(0.3)
                  : Colors.grey[300]!,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Status icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OrderService.getStatusColor(status.apiValue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      OrderService.getStatusEmoji(status.apiValue),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      OrderService.getStatusIcon(status.apiValue),
                      color: OrderService.getStatusColor(status.apiValue),
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
                        Text(
                          status.displayName,
                          style: TextStyle(
                            color: ColorManager.black,
                            fontSize: 14,
                            fontWeight: isCurrent 
                                ? FontWeightManager.bold 
                                : FontWeightManager.medium,
                            fontFamily: FontFamily.Montserrat,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: OrderService.getStatusColor(status.apiValue),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      OrderService.getStatusDescription(status.apiValue),
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
              ] else if (isCurrent) ...[
                Icon(
                  Icons.check_circle,
                  color: OrderService.getStatusColor(status.apiValue),
                  size: 18,
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

  Future<void> _updateOrderStatus(OrderStatus newStatus) async {
    if (_isUpdating) return;
    
    debugPrint('OrderStatusBottomSheet: Starting status update...');
    debugPrint('OrderStatusBottomSheet: Order ID: ${widget.orderId}');
    debugPrint('OrderStatusBottomSheet: New Status: ${newStatus.apiValue}');
    
    setState(() {
      _isUpdating = true;
    });

    // Set timeout timer
    _timeoutTimer = Timer(const Duration(seconds: 8), _handleTimeout);
    
    // Set a fallback timer to close the bottom sheet if no state changes are received
    Timer(const Duration(seconds: 10), () {
      if (_isUpdating && mounted) {
        debugPrint('OrderStatusBottomSheet: ⚠️ Fallback timer triggered - no state changes received');
        _handleError('Request timed out. Please try again.');
      }
    });

    try {
      debugPrint('OrderStatusBottomSheet: Triggering UpdateOrderStatusEvent');
      debugPrint('OrderStatusBottomSheet: Order ID: ${widget.orderId}');
      debugPrint('OrderStatusBottomSheet: New Status: ${newStatus.apiValue}');
      
      // Use the passed OrdersBloc instance
      debugPrint('OrderStatusBottomSheet: OrdersBloc found: ${widget.ordersBloc != null}');
      debugPrint('OrderStatusBottomSheet: OrdersBloc current state: ${widget.ordersBloc.state.runtimeType}');
      
      // Use OrdersBloc to update status
      widget.ordersBloc.add(UpdateOrderStatusEvent(
        orderId: widget.orderId,
        newStatus: newStatus,
      ));
      
      debugPrint('OrderStatusBottomSheet: UpdateOrderStatusEvent added to OrdersBloc');
      debugPrint('OrderStatusBottomSheet: Waiting for state changes...');

      // The stream listener will handle the response
      
    } catch (e) {
      debugPrint('OrderStatusBottomSheet: Error in _updateOrderStatus: $e');
      debugPrint('OrderStatusBottomSheet: Error stack trace: ${StackTrace.current}');
      _handleError('Failed to update order status. Please try again.');
    }
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