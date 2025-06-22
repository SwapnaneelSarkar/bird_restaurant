// lib/ui_components/attribute_card.dart
import 'package:flutter/material.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class AttributeCard extends StatelessWidget {
  final String title;
  final String values;
  final Function() onEditValues;

  const AttributeCard({
    Key? key,
    required this.title,
    required this.values,
    required this.onEditValues,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,  // White background for the card
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: FontSize.s16,
                  fontWeight: FontWeightManager.semiBold,
                  color: ColorManager.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            values,
            style: TextStyle(
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.regular,
              color: Colors.grey[600],
              height: 1.3, // Slightly tighter line height to match image
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onEditValues,
            child: Row(
              children: [
                Icon(
                  Icons.edit,
                  size: 18,
                  color: const Color(0xFFCD6E32), // Exact orange color from image
                ),
                const SizedBox(width: 6),
                Text(
                  "Edit Values",
                  style: TextStyle(
                    fontSize: FontSize.s14,
                    fontWeight: FontWeightManager.medium,
                    color: const Color(0xFFCD6E32), // Exact orange color from image
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