// lib/ui_components/next_button.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class NextButton extends StatelessWidget {
  final String label;
  final IconData? suffixIcon;
  final VoidCallback? onPressed;

  const NextButton({
    Key? key,
    required this.label,
    this.suffixIcon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        // normal background
        backgroundColor: ColorManager.primary,
        // override the disabled background so it stays orange even when onPressed == null
        disabledBackgroundColor: ColorManager.primary,
        // normal text/icon color
        foregroundColor: Colors.white,
        // keep the text/icon white when “disabled”
        disabledForegroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
            ),
          ),
          if (suffixIcon != null) ...[
            const SizedBox(width: 8),
            Icon(suffixIcon, size: 20),
          ],
        ],
      ),
    );
  }
}
