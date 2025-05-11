// lib/ui_components/proggress_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressBar({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (i) {
        // Even index: a step circle
        if (i.isEven) {
          final step = i ~/ 2 + 1;
          final isActive = step <= currentStep;

          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? ColorManager.primary
                  : ColorManager.progressWhite,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$step',
              style: GoogleFonts.poppins(
                fontSize: FontSize.s16,
                fontWeight: FontWeightManager.medium,
                color: isActive
                    ? Colors.white
                    : Colors.grey.shade600,
              ),
            ),
          );
        }

        // Odd index: the connector line
        final connectorIndex = (i - 1) ~/ 2 + 1;
        final isFilled = connectorIndex < currentStep;

        return Expanded(
          child: Container(
            // increased gap around the line
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 6,
            color: isFilled
                ? ColorManager.primary
                : ColorManager.progressWhite,
          ),
        );
      }),
    );
  }
}
