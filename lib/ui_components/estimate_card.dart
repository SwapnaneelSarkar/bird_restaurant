import 'package:flutter/material.dart';

import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class EstimatedReviewCard extends StatelessWidget {
  final String message;
  const EstimatedReviewCard({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final hPad = isTablet ? 24.0 : 16.0;
        final vPad = isTablet ? 20.0 : 16.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad * 0.8),
          decoration: BoxDecoration(
            color: ColorManager.textWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.schedule,
                color: const Color(0xFF5C6BFF),
                size: isTablet ? 24 : 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Review Time',
                      style: TextStyle(
                        fontFamily: FontConstants.fontFamily,
                        fontSize: isTablet ? FontSize.s18 : FontSize.s16,
                        fontWeight: FontWeightManager.semiBold,
                        color: ColorManager.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: TextStyle(
                        fontFamily: FontConstants.fontFamily,
                        fontSize: isTablet ? FontSize.s16 : FontSize.s14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}