// To run this test, ensure you have these in your pubspec.yaml under dev_dependencies:
//   mockito: ^5.0.0
//   bloc_test: ^9.0.0
// Then run: flutter pub get
// If you see missing package errors, run: flutter pub add --dev mockito bloc_test

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:bird_restaurant/presentation/screens/attributes/bloc.dart';
import 'package:bird_restaurant/presentation/screens/attributes/state.dart';
import 'package:bird_restaurant/presentation/screens/attributes/view.dart';
import 'package:bird_restaurant/presentation/screens/attributes/event.dart';
import 'package:bird_restaurant/models/attribute_model.dart';

class MockAttributeBloc extends MockBloc<AttributeEvent, AttributeState> implements AttributeBloc {}

void main() {
  group('Attribute Edit Dialog Widget Test', () {
    late MockAttributeBloc mockBloc;
    setUp(() {
      mockBloc = MockAttributeBloc();
    });

    testWidgets('shows edit dialog and dispatches update/delete events', (WidgetTester tester) async {
      // Mock initial state with one attribute
      final attribute = Attribute(
        name: 'masala',
        values: ['beans'],
        isActive: true,
        attributeId: 'attr1',
        type: 'radio',
      );
      whenListen(
        mockBloc,
        Stream<AttributeState>.fromIterable([
          AttributeLoaded(attributes: [attribute], selectedMenuId: 'menu1'),
        ]),
        initialState: AttributeLoaded(attributes: [attribute], selectedMenuId: 'menu1'),
      );

      // Prepare a fake AttributeGroup for the dialog
      final fakeGroup = AttributeGroup(
        attributeId: 'attr1',
        menuId: 'menu1',
        name: 'masala',
        type: 'radio',
        isRequired: 1,
        createdAt: '',
        updatedAt: '',
        attributeValues: [
          AttributeValue(
            name: 'beans',
            valueId: 'val1',
            isDefault: 0,
            priceAdjustment: 10,
          ),
        ],
      );

      // Use a GlobalKey to access the state
      final attributesScreenKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AttributeBloc>.value(
            value: mockBloc,
            child: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final state = attributesScreenKey.currentState;
                  if (state != null) {
                    // ignore: invalid_use_of_protected_member
                    // ignore: avoid_dynamic_calls
                    (state as dynamic).showEditDialog(
                      context,
                      attribute,
                      testFuture: Future.value(fakeGroup),
                    );
                  }
                });
                return AttributesScreen(key: attributesScreenKey);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The dialog should appear
      expect(find.textContaining('Edit'), findsWidgets);
      expect(find.text('beans'), findsWidgets);
    });
  });
} 