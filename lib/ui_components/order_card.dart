// lib/ui_components/order_stat_card.dart (updated)
import 'package:flutter/material.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import '../presentation/screens/orders/state.dart';

class OrderStatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;

  const OrderStatCard({
    Key? key,
    required this.title,
    required this.count,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.3,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: FontSize.s14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: FontSize.s18,
                fontWeight: FontWeightManager.bold,
                color: ColorManager.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}