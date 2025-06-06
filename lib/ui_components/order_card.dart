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
  final VoidCallback onTap;

  const OrderCard({
    Key? key,
    required this.orderId,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.status,
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
        child: Row(
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
            const SizedBox(width: 16),
            // Order Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #$orderId',
                        style: TextStyle(
                          fontSize: FontSize.s14,
                          fontWeight: FontWeightManager.medium,
                          color: Colors.grey[700],
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    customerName,
                    style: TextStyle(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.semiBold,
                      color: ColorManager.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        'Payable: ₹${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: FontSize.s14,
                          fontWeight: FontWeightManager.medium,
                          color: ColorManager.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM d, yyyy').format(date),
                        style: TextStyle(
                          fontSize: FontSize.s14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    late final Color backgroundColor;
    late final Color textColor;
    late final String statusText;
    
    switch (status) {
      case OrderStatus.pending:
        backgroundColor = const Color(0xFFFFEFD6);
        textColor = Colors.orange[800]!;
        statusText = 'Pending';
        break;
      case OrderStatus.confirmed:
        backgroundColor = const Color(0xFFD1F5EA);
        textColor = Colors.green[700]!;
        statusText = 'Confirmed';
        break;
      case OrderStatus.delivery:
        backgroundColor = const Color(0xFFE3EAFF);
        textColor = Colors.blue[700]!;
        statusText = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        backgroundColor = const Color(0xFFD1F5EA);
        textColor = Colors.green[700]!;
        statusText = 'Delivered';
        break;
      case OrderStatus.cancelled:
        backgroundColor = const Color(0xFFFFE5E5);
        textColor = Colors.red[700]!;
        statusText = 'Cancelled';
        break;
      case OrderStatus.preparing:
        backgroundColor = const Color(0xFFFFF8E1);
        textColor = Colors.amber[800]!;
        statusText = 'Preparing';
        break;
      case OrderStatus.all:
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        statusText = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: FontSize.s12,
          fontWeight: FontWeightManager.medium,
          color: textColor,
        ),
      ),
    );
  }
}