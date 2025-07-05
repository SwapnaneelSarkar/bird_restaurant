// lib/ui_components/app_back_header.dart
import 'package:flutter/material.dart';

import '../../presentation/resources/colors.dart';
import '../../presentation/resources/font.dart';
import '../../presentation/resources/router/router.dart';


class AppBackHeader extends StatelessWidget {
  final String title;

  const AppBackHeader({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _handleBackNavigation(context),
            child: Icon(
              Icons.chevron_left,
              size: 28,
              color: ColorManager.black,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: FontSize.s20,
              fontWeight: FontWeightManager.bold,
              color: ColorManager.black,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBackNavigation(BuildContext context) {
    // Check if there's a previous route in the navigation stack
    if (Navigator.of(context).canPop()) {
      // If there's a previous route, pop normally
      Navigator.of(context).pop();
    } else {
      // If there's no previous route (e.g., navigated from notification), go to home
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.homePage,
        (route) => false,
      );
    }
  }
}