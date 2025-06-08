// lib/ui_components/order_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/enums.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import '../presentation/screens/orders/state.dart';

class OrderCard extends StatelessWidget {
  final String orderId;
  final String customerName;
  final double amount;
  final DateTime date;
  final OrderStatus status;
  final String? customerPhone;
  final String? deliveryAddress;
  final VoidCallback onTap;

  const OrderCard({
    Key? key,
    required this.orderId,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.status,
    this.customerPhone,
    this.deliveryAddress,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                  'Order #${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}',
                  style: TextStyle(
                    fontSize: FontSize.s14,
                    fontWeight: FontWeightManager.medium,
                    color: Colors.grey[700],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            
            // Customer Info Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Customer Avatar Circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Customer Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: TextStyle(
                          fontSize: FontSize.s16,
                          fontWeight: FontWeightManager.semiBold,
                          color: ColorManager.black,
                        ),
                      ),
                      if (customerPhone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          customerPhone!,
                          style: TextStyle(
                            fontSize: FontSize.s12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Amount and Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: FontSize.s16,
                        fontWeight: FontWeightManager.bold,
                        color: ColorManager.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(date),
                      style: TextStyle(
                        fontSize: FontSize.s12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Address (if available)
            if (deliveryAddress != null && deliveryAddress!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deliveryAddress!,
                        style: TextStyle(
                          fontSize: FontSize.s12,
                          color: Colors.grey[700],
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
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color badgeColor;
    String statusText;
    
    switch (status) {
      case OrderStatus.pending:
        badgeColor = Colors.orange;
        statusText = 'Pending';
        break;
      case OrderStatus.confirmed:
        badgeColor = Colors.blue;
        statusText = 'Confirmed';
        break;
      case OrderStatus.preparing:
        badgeColor = Colors.amber;
        statusText = 'Preparing';
        break;
      case OrderStatus.delivery:
        badgeColor = Colors.indigo;
        statusText = 'Delivery';
        break;
      case OrderStatus.delivered:
        badgeColor = Colors.green;
        statusText = 'Delivered';
        break;
      case OrderStatus.cancelled:
        badgeColor = Colors.red;
        statusText = 'Cancelled';
        break;
      default:
        badgeColor = Colors.grey;
        statusText = 'Unknown';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: FontSize.s10,
          fontWeight: FontWeightManager.medium,
          color: badgeColor,
        ),
      ),
    );
  }
}