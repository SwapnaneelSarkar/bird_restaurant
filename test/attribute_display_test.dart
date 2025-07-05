import 'package:flutter_test/flutter_test.dart';
import 'package:bird_restaurant/models/attribute_model.dart';

void main() {
  group('Attribute Display Tests', () {
    test('should parse attribute values correctly from JSON', () {
      final json = {
        'attribute_id': 'test-id',
        'menu_id': 'menu-id',
        'name': 'Test Attribute',
        'type': 'checkbox',
        'is_required': 1,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'attribute_values': [
          {
            'name': 'Value 1',
            'value_id': 'value-1',
            'is_default': 0,
            'price_adjustment': 100,
          },
          {
            'name': 'Value 2',
            'value_id': 'value-2',
            'is_default': 1,
            'price_adjustment': 200,
          },
        ],
      };

      final attributeGroup = AttributeGroup.fromJson(json);
      final attribute = attributeGroup.toAttribute();

      expect(attribute.name, equals('Test Attribute'));
      expect(attribute.type, equals('checkbox'));
      expect(attribute.values.length, equals(2));
      expect(attribute.values, contains('Value 1'));
      expect(attribute.values, contains('Value 2'));
    });

    test('should handle empty attribute values', () {
      final json = {
        'attribute_id': 'test-id',
        'menu_id': 'menu-id',
        'name': 'Test Attribute',
        'type': 'checkbox',
        'is_required': 1,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'attribute_values': [],
      };

      final attributeGroup = AttributeGroup.fromJson(json);
      final attribute = attributeGroup.toAttribute();

      expect(attribute.name, equals('Test Attribute'));
      expect(attribute.values.length, equals(0));
    });

    test('should filter out null or empty attribute values', () {
      final json = {
        'attribute_id': 'test-id',
        'menu_id': 'menu-id',
        'name': 'Test Attribute',
        'type': 'checkbox',
        'is_required': 1,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'attribute_values': [
          {
            'name': 'Valid Value',
            'value_id': 'value-1',
            'is_default': 0,
            'price_adjustment': 100,
          },
          {
            'name': null,
            'value_id': 'value-2',
            'is_default': 0,
            'price_adjustment': 200,
          },
          {
            'name': '',
            'value_id': 'value-3',
            'is_default': 0,
            'price_adjustment': 300,
          },
          {
            'name': '   ',
            'value_id': 'value-4',
            'is_default': 0,
            'price_adjustment': 400,
          },
        ],
      };

      final attributeGroup = AttributeGroup.fromJson(json);
      final attribute = attributeGroup.toAttribute();

      expect(attribute.name, equals('Test Attribute'));
      expect(attribute.values.length, equals(1));
      expect(attribute.values, contains('Valid Value'));
    });
  });
} 