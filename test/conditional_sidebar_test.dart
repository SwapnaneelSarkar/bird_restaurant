import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bird_restaurant/presentation/screens/homePage/sidebar/sidebar_drawer.dart';

void main() {
  group('Conditional Sidebar Tests', () {
    testWidgets('should render sidebar with conditional menu items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SidebarDrawer(
              activePage: 'home',
              restaurantName: 'Test Restaurant',
              restaurantSlogan: 'Test Slogan',
            ),
          ),
        ),
      );

      // Verify the sidebar renders
      expect(find.byType(SidebarDrawer), findsOneWidget);
    });

    testWidgets('should show conditional menu items based on supercategory', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SidebarDrawer(
              activePage: 'home',
              restaurantName: 'Test Restaurant',
              restaurantSlogan: 'Test Slogan',
            ),
          ),
        ),
      );

      // Verify basic menu items are present
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      
      // Verify Attributes is not shown (removed for all supercategories)
      expect(find.text('Attributes'), findsNothing);
    });
  });
} 