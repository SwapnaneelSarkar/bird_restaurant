import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SidebarOpener extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Color? iconColor;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;

  const SidebarOpener({
    Key? key,
    required this.scaffoldKey,
    this.iconColor,
    this.iconSize = 24.0,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: () {
        HapticFeedback.lightImpact(); // Subtle feedback when menu is opened
        scaffoldKey.currentState?.openDrawer(); // Use safe null access
      },
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8.0),
        child: Icon(
          Icons.menu_rounded,
          color: iconColor ?? Colors.black87,
          size: iconSize,
        ),
      ),
    );
  }
}