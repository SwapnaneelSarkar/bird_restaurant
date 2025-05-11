import 'package:flutter/material.dart';
import '../constants/enums.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import '../presentation/screens/resturant_details_2/state.dart';

class CuisineCard extends StatelessWidget {
  final CuisineType cuisine;
  final bool selected;
  final VoidCallback? onTap;

  const CuisineCard({
    Key? key,
    required this.cuisine,
    required this.selected,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final border =
        Border.all(color: ColorManager.grey, width: 1);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: selected
              ? ColorManager.black.withOpacity(.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: border,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cuisine.icon,
                size: 28,
                color: selected ? ColorManager.black : Colors.grey.shade700),
            const SizedBox(height: 6),
            Text(
              cuisine.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontConstants.fontFamily,
                fontSize: FontSize.s12,
                fontWeight: FontWeightManager.medium,
                color:
                    selected ? ColorManager.black : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
