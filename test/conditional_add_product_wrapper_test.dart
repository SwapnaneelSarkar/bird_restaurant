import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bird_restaurant/presentation/screens/conditional_add_product_wrapper.dart';
import 'package:bird_restaurant/presentation/screens/add_product/view.dart';
import 'package:bird_restaurant/presentation/screens/add_product_from_catalog/view.dart';

void main() {
  group('ConditionalAddProductWrapper Tests', () {
    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ConditionalAddProductWrapper(),
        ),
      );

      // Verify loading indicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should render the wrapper widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ConditionalAddProductWrapper(),
        ),
      );

      // Verify the wrapper widget is rendered
      expect(find.byType(ConditionalAddProductWrapper), findsOneWidget);
    });
  });
} 