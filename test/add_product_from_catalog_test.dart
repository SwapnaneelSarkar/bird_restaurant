import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bird_restaurant/presentation/screens/add_product_from_catalog/view.dart';
import 'package:bird_restaurant/presentation/screens/add_product_from_catalog/bloc.dart';
import 'package:bird_restaurant/presentation/screens/add_product_from_catalog/event.dart';
import 'package:bird_restaurant/presentation/screens/add_product_from_catalog/state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  group('AddProductFromCatalogScreen Tests', () {
    testWidgets('should render the screen with initial state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AddProductFromCatalogBloc>(
            create: (context) => AddProductFromCatalogBloc(),
            child: const AddProductFromCatalogScreen(),
          ),
        ),
      );

      // Verify that the screen title is displayed
      expect(find.text('Add Product From Catalog'), findsOneWidget);
      
      // Verify that the info message is displayed
      expect(find.text('Select a product from the catalog and set your price and quantity'), findsOneWidget);
      
      // Verify that the category dropdown is present
      expect(find.text('Category *'), findsOneWidget);
    });

    testWidgets('should show loading state for categories', (WidgetTester tester) async {
      final bloc = AddProductFromCatalogBloc();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AddProductFromCatalogBloc>.value(
            value: bloc,
            child: const AddProductFromCatalogScreen(),
          ),
        ),
      );

      // Emit loading state
      bloc.emit(AddProductFromCatalogFormState(isLoadingCategories: true));
      await tester.pump();

      // Verify loading indicator is shown
      expect(find.text('Loading categories...'), findsOneWidget);
    });

    testWidgets('should show error message when there is an error', (WidgetTester tester) async {
      final bloc = AddProductFromCatalogBloc();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AddProductFromCatalogBloc>.value(
            value: bloc,
            child: const AddProductFromCatalogScreen(),
          ),
        ),
      );

      // Emit error state
      bloc.emit(AddProductFromCatalogFormState(errorMessage: 'Test error message'));
      await tester.pump();

      // Verify error message is shown in snackbar
      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('should show success message when product is added', (WidgetTester tester) async {
      final bloc = AddProductFromCatalogBloc();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AddProductFromCatalogBloc>.value(
            value: bloc,
            child: const AddProductFromCatalogScreen(),
          ),
        ),
      );

      // Emit success state
      bloc.emit(AddProductFromCatalogFormState(isSuccess: true));
      await tester.pump();

      // Verify success message is shown in snackbar
      expect(find.text('Product added successfully!'), findsOneWidget);
    });
  });
} 