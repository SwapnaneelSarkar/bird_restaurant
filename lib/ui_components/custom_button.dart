// lib/ui_components/custom_button.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;     // ← nullable now

  const CustomButton({
    Key? key,
    required this.label,
    this.onPressed,                   // ← no longer required
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,          // ← if null, button is disabled
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null
              ? ColorManager.primary
              : ColorManager.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: onPressed != null ? 4 : 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: FontSize.s16,
            fontWeight: FontWeightManager.semiBold,
            color: ColorManager.textWhite,
          ),
        ),
      ),
    );
  }
}
