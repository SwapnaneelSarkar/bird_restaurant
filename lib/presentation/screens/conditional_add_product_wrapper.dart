import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/token_service.dart';
import 'add_product/view.dart';
import 'add_product_from_catalog/view.dart';

class ConditionalAddProductWrapper extends StatefulWidget {
  const ConditionalAddProductWrapper({Key? key}) : super(key: key);

  @override
  State<ConditionalAddProductWrapper> createState() => _ConditionalAddProductWrapperState();
}

class _ConditionalAddProductWrapperState extends State<ConditionalAddProductWrapper> {
  bool _isLoading = true;
  bool _isFoodSupercategory = false;

  // Food supercategory constants
  static const String _foodSupercategoryId = '7acc47a2fa5a4eeb906a753b3';
  static const String _foodSupercategoryName = 'Food';

  @override
  void initState() {
    super.initState();
    _checkSupercategory();
  }

  Future<void> _checkSupercategory() async {
    try {
      final supercategoryId = await TokenService.getSupercategoryId();
      final prefs = await SharedPreferences.getInstance();
      final supercategoryName = prefs.getString('supercategory_name');
      
      // Check if it's Food by ID or name
      final isFood = supercategoryId == _foodSupercategoryId || 
                     supercategoryName == _foodSupercategoryName;
      
      if (mounted) {
        setState(() {
          _isFoodSupercategory = isFood;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking supercategory: $e');
      if (mounted) {
        setState(() {
          _isFoodSupercategory = false; // Default to non-Food behavior
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show appropriate page based on supercategory
    if (_isFoodSupercategory) {
      return const AddProductScreen();
    } else {
      return const AddProductFromCatalogScreen();
    }
  }
} 