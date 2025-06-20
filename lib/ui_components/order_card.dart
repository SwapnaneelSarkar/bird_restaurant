// lib/ui_components/order_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../constants/enums.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import '../presentation/screens/orders/bloc.dart';
import '../services/order_service.dart';
import 'order_status_bottomsheet.dart'; // Import the ORDERS-specific bottom sheet
import 'universal_widget/order_widgets.dart'; // Import the ORDER OPTIONS bottom sheet
import '../services/token_service.dart';

class OrderCard extends StatelessWidget {
  final String orderId;
  final String customerName;
  final double amount;
  final DateTime date;
  final OrderStatus status;
  final String? customerPhone;
  final String? deliveryAddress;
  final VoidCallback? onTap; // Make optional for bottom sheet handling

  const OrderCard({
    Key? key,
    required this.orderId,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.status,
    this.customerPhone,
    this.deliveryAddress,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleCardTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Order ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${orderId.length > 8 ? orderId.substring(0, 8) + '...' : orderId}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeightManager.bold,
                    color: ColorManager.black,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: OrderService.getStatusColor(status.apiValue),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Customer Name and Phone
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customerName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                ),
                if (customerPhone != null) ...[
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    customerPhone!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Delivery Address (if available)
            if (deliveryAddress != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deliveryAddress!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: FontFamily.Montserrat,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Bottom Row with Amount and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeightManager.bold,
                    color: ColorManager.primary,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleCardTap(BuildContext context) {
    // If a custom onTap is provided, use it (for backward compatibility)
    if (onTap != null) {
      onTap!();
      return;
    }

    // Otherwise, show the ORDER STATUS bottom sheet (for orders page)
    _showOrderStatusBottomSheet(context);
  }

  void _showOrderStatusBottomSheet(BuildContext context) async {
    // Fetch partnerId from TokenService
    final partnerId = await TokenService.getUserId();
    if (partnerId == null || partnerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load order details. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => OrderOptionsBottomSheet(
        orderId: orderId,
        partnerId: partnerId,
      ),
    );
  }
}