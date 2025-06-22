import 'package:flutter/material.dart';
import '../../../../services/restaurant_info_service.dart';
import 'sidebar_drawer.dart';

class SidebarProvider extends StatefulWidget {
  final String? activePage;
  final Widget child;

  const SidebarProvider({
    Key? key,
    required this.activePage,
    required this.child,
  }) : super(key: key);

  @override
  State<SidebarProvider> createState() => _SidebarProviderState();
}

class _SidebarProviderState extends State<SidebarProvider> {
  Map<String, String>? _restaurantInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantInfo();
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      final info = await RestaurantInfoService.getRestaurantInfo();
      if (mounted) {
        setState(() {
          _restaurantInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading restaurant info: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: GlobalKey<ScaffoldState>(),
      drawer: _isLoading
          ? const Drawer(
              child: Center(child: CircularProgressIndicator()),
            )
          : SidebarDrawer.createWithCachedInfo(
              activePage: widget.activePage,
              cachedInfo: _restaurantInfo,
            ),
      body: widget.child,
    );
  }
}

// Extension to easily add sidebar to any widget
extension SidebarExtension on Widget {
  Widget withSidebar(String? activePage) {
    return SidebarProvider(
      activePage: activePage,
      child: this,
    );
  }
} 