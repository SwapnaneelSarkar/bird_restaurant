import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';


class CustomButtonSlim extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isOutline;
  final IconData? suffixIcon;

  const CustomButtonSlim({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isOutline = false,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = isOutline ? Colors.transparent : ColorManager.primary;
    final borderColor = isOutline ? ColorManager.primary : Colors.transparent;
    final textColor = isOutline ? ColorManager.primary : Colors.white;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: textColor, backgroundColor: bgColor,
        elevation: isOutline ? 0 : 4,
        side: BorderSide(color: borderColor, width: isOutline ? 1.5 : 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: FontSize.s16,
              fontWeight: FontWeightManager.medium,
              color: textColor,
            ),
          ),
          if (suffixIcon != null) ...[
            const SizedBox(width: 8),
            Icon(suffixIcon, size: 20, color: textColor),
          ]
        ],
      ),
    );
  }
}
