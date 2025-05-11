import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

enum ProfileButtonStyle { filled, outline }

class ProfileButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final ProfileButtonStyle style;

  const ProfileButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.style = ProfileButtonStyle.filled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFilled = style == ProfileButtonStyle.filled;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: FontSize.s16,
          fontWeight: FontWeightManager.medium,
        ),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48), // keep same height as NextButton
        backgroundColor:
            isFilled ? ColorManager.primary : Colors.transparent,
        foregroundColor: isFilled ? Colors.white : ColorManager.black,
        disabledBackgroundColor:
            isFilled ? ColorManager.primary : Colors.transparent,
        disabledForegroundColor:
            isFilled ? Colors.white : ColorManager.black.withOpacity(.4),
        elevation: isFilled ? 4 : 0,
        side: isFilled
            ? BorderSide.none
            : BorderSide(color: ColorManager.grey, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }
}
