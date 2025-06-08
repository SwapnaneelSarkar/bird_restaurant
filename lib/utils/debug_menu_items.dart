// lib/utils/debug_menu_items.dart - DEBUG HELPER

import 'package:flutter/foundation.dart';
import '../services/menu_item_service.dart';
import '../presentation/screens/chat/state.dart';

class MenuItemDebugHelper {
  static void logOrderDetails(OrderDetails orderDetails) {
    debugPrint('🔍 ORDER DETAILS DEBUG:');
    debugPrint('  Order ID: ${orderDetails.orderId}');
    debugPrint('  User ID: ${orderDetails.userId}');
    debugPrint('  Status: ${orderDetails.orderStatus}');
    debugPrint('  Total Amount: ${orderDetails.formattedTotal}');
    debugPrint('  Delivery Fees: ${orderDetails.formattedDeliveryFees}');
    debugPrint('  Grand Total: ${orderDetails.formattedGrandTotal}');
    debugPrint('  Number of Items: ${orderDetails.items.length}');
    debugPrint('  All Menu IDs: ${orderDetails.allMenuIds}');
    
    for (int i = 0; i < orderDetails.items.length; i++) {
      final item = orderDetails.items[i];
      debugPrint('  Item ${i + 1}:');
      debugPrint('    Menu ID: ${item.menuId}');
      debugPrint('    Quantity: ${item.quantity}');
      debugPrint('    Item Price: ${item.formattedPrice}');
      debugPrint('    Total Price: ${item.formattedTotalPrice}');
    }
  }

  static void logMenuItemsStatus(
    List<String> requestedMenuIds,
    Map<String, MenuItem> loadedMenuItems,
  ) {
    debugPrint('🍽️ MENU ITEMS LOADING DEBUG:');
    debugPrint('  Requested Menu IDs: ${requestedMenuIds.length}');
    debugPrint('  Successfully Loaded: ${loadedMenuItems.length}');
    debugPrint('  Success Rate: ${(loadedMenuItems.length / requestedMenuIds.length * 100).toStringAsFixed(1)}%');
    
    debugPrint('  📋 Detailed Status:');
    for (final menuId in requestedMenuIds) {
      if (loadedMenuItems.containsKey(menuId)) {
        final item = loadedMenuItems[menuId]!;
        debugPrint('    ✅ $menuId: "${item.name}" - ₹${item.price} ${item.isAvailable ? "(Available)" : "(Unavailable)"}');
        if (item.hasImage) {
          debugPrint('      🖼️ Image: ${item.displayImageUrl}');
        } else {
          debugPrint('      📷 No image available');
        }
      } else {
        debugPrint('    ❌ $menuId: FAILED TO LOAD');
      }
    }
  }

  static Future<void> testSingleMenuItem(String menuId) async {
    debugPrint('🧪 TESTING SINGLE MENU ITEM: $menuId');
    
    try {
      final startTime = DateTime.now();
      final menuItem = await MenuItemService.getMenuItem(menuId);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      if (menuItem != null) {
        debugPrint('  ✅ SUCCESS (${duration.inMilliseconds}ms)');
        debugPrint('    Name: ${menuItem.name}');
        debugPrint('    Price: ₹${menuItem.price}');
        debugPrint('    Description: ${menuItem.description}');
        debugPrint('    Category: ${menuItem.category}');
        debugPrint('    Available: ${menuItem.isAvailable}');
        debugPrint('    Image URL: ${menuItem.imageUrl}');
        debugPrint('    Display Image URL: ${menuItem.displayImageUrl}');
        debugPrint('    Has Image: ${menuItem.hasImage}');
        debugPrint('    Tags: ${menuItem.tags}');
      } else {
        debugPrint('  ❌ FAILED (${duration.inMilliseconds}ms) - Returned null');
      }
    } catch (e) {
      debugPrint('  💥 ERROR: $e');
    }
  }

  static Future<void> testBatchMenuItems(List<String> menuIds) async {
    debugPrint('🧪 TESTING BATCH MENU ITEMS: ${menuIds.length} items');
    
    try {
      final startTime = DateTime.now();
      final menuItems = await MenuItemService.getMenuItems(menuIds);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      debugPrint('  ⏱️ Total Time: ${duration.inMilliseconds}ms');
      debugPrint('  📊 Results: ${menuItems.length}/${menuIds.length} loaded');
      
      logMenuItemsStatus(menuIds, menuItems);
      
    } catch (e) {
      debugPrint('  💥 BATCH ERROR: $e');
    }
  }

  static void logOrderItemDisplay(
    OrderItem item,
    Map<String, MenuItem> menuItems,
  ) {
    debugPrint('🎨 ORDER ITEM DISPLAY DEBUG:');
    debugPrint('  Menu ID: ${item.menuId}');
    debugPrint('  Quantity: ${item.quantity}');
    debugPrint('  Item Price: ${item.formattedPrice}');
    debugPrint('  Total Price: ${item.formattedTotalPrice}');
    
    final menuItem = item.getMenuItem(menuItems);
    if (menuItem != null) {
      debugPrint('  ✅ Menu Item Found:');
      debugPrint('    Display Name: ${item.getDisplayName(menuItems)}');
      debugPrint('    Description: ${item.getDescription(menuItems) ?? "No description"}');
      debugPrint('    Image URL: ${item.getImageUrl(menuItems) ?? "No image"}');
      debugPrint('    Available: ${item.isAvailable(menuItems) ?? "Unknown"}');
    } else {
      debugPrint('  ❌ Menu Item NOT Found');
      debugPrint('    Fallback Display Name: ${item.getDisplayName(menuItems)}');
    }
  }

  static void compareMenuItemModels(dynamic item1, dynamic item2, String model1Name, String model2Name) {
    debugPrint('🔄 COMPARING MENU ITEM MODELS:');
    debugPrint('  Model 1 ($model1Name): ${item1.runtimeType}');
    debugPrint('  Model 2 ($model2Name): ${item2.runtimeType}');
    
    // Compare common fields
    final fields = ['id', 'name', 'price', 'description', 'imageUrl', 'isAvailable', 'category'];
    for (final field in fields) {
      try {
        final value1 = _getFieldValue(item1, field);
        final value2 = _getFieldValue(item2, field);
        final match = value1 == value2;
        debugPrint('    $field: ${match ? "✅" : "❌"} ($value1 vs $value2)');
      } catch (e) {
        debugPrint('    $field: ❓ Error comparing - $e');
      }
    }
  }

  static dynamic _getFieldValue(dynamic object, String fieldName) {
    try {
      switch (fieldName) {
        case 'id':
          return object.id ?? object.menuId ?? 'N/A';
        case 'name':
          return object.name ?? 'N/A';
        case 'price':
          return object.price ?? 'N/A';
        case 'description':
          return object.description ?? 'N/A';
        case 'imageUrl':
          return object.imageUrl ?? object.image ?? 'N/A';
        case 'isAvailable':
          return object.isAvailable ?? object.available ?? 'N/A';
        case 'category':
          return object.category ?? 'N/A';
        default:
          return 'Unknown field';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Quick test to verify the MenuItemService is working
  static Future<void> quickHealthCheck() async {
    debugPrint('🏥 MENU ITEM SERVICE HEALTH CHECK');
    
    // Test with a dummy menu ID (this will likely fail, but we can see the API response)
    await testSingleMenuItem('test_menu_id_123');
    
    // Test with empty list
    await testBatchMenuItems([]);
    
    // Test with single item list
    await testBatchMenuItems(['test_menu_id_123']);
  }

  /// Debug the entire order details flow
  static Future<void> debugOrderDetailsFlow(
    OrderDetails orderDetails,
    Map<String, MenuItem> menuItems,
  ) async {
    debugPrint('🔬 FULL ORDER DETAILS FLOW DEBUG');
    debugPrint('=' * 50);
    
    // Step 1: Log order details
    logOrderDetails(orderDetails);
    
    debugPrint('');
    
    // Step 2: Check menu item loading status
    logMenuItemsStatus(orderDetails.allMenuIds, menuItems);
    
    debugPrint('');
    
    // Step 3: Test each order item display
    debugPrint('🎨 ORDER ITEMS DISPLAY TEST:');
    for (int i = 0; i < orderDetails.items.length; i++) {
      debugPrint('  --- Item ${i + 1} ---');
      logOrderItemDisplay(orderDetails.items[i], menuItems);
      debugPrint('');
    }
    
    debugPrint('=' * 50);
  }
}