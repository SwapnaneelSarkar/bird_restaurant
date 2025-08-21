import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? label;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;  // ← NEW: For on blur validation
  final ValueChanged<String>? onFieldSubmitted; // ← NEW: For on submit validation
  final bool enabled;
  final String? errorText;             // ← NEW: For validation errors
  final int? maxLength;                // ← NEW: For character limit
  final String? counterText;           // ← NEW: For custom character counter
  final List<TextInputFormatter>? inputFormatters; // ← NEW: For input formatting

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.label,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onEditingComplete,            // ← NEW
    this.onFieldSubmitted,             // ← NEW
    this.enabled = true,
    this.errorText,                     // ← NEW
    this.maxLength,                     // ← NEW
    this.counterText,                   // ← NEW
    this.inputFormatters,               // ← NEW
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Build a counter widget if counterText is provided
    Widget? buildCounter(
      BuildContext context, {
      required int currentLength,
      required int? maxLength,
      required bool isFocused,
    }) {
      return counterText != null
          ? Text(
              counterText!,
              style: TextStyle(
                color: currentLength > (maxLength ?? 0) && maxLength != null
                    ? Colors.red[700]
                    : Colors.grey[600],
                fontSize: 12,
              ),
            )
          : null;
    }

    final field = TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,    // ← NEW
      onSubmitted: onFieldSubmitted,           // ← NEW
      maxLength: maxLength,
      buildCounter: counterText != null ? buildCounter : null,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(
        fontSize: FontSize.s14,
        fontWeight: FontWeightManager.regular,
        color: ColorManager.black,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          fontSize: FontSize.s14,
          fontWeight: FontWeightManager.regular,
          color: ColorManager.textGrey,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20, // taller field
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorManager.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorManager.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: errorText != null ? Colors.red : ColorManager.grey, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[700]!, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[700]!, width: 1.5),
        ),
        errorText: errorText,
        errorStyle: TextStyle(
          color: Colors.red[700],
          fontSize: 12,
          height: 1,
        ),
        counterText: "", // Hide default counter if we're using our custom one
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: TextStyle(
            fontFamily: FontConstants.fontFamily,
            fontSize: FontSize.s14,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}