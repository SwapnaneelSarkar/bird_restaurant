import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  group('Owner Name Validation Tests', () {
    test('should prevent numbers in owner name', () {
      final formatters = [
        FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
        LengthLimitingTextInputFormatter(50),
      ];
      
      final oldValue = TextEditingValue(text: 'John');
      final newValue = TextEditingValue(text: 'John123');
      
      final result = formatters.fold(newValue, (value, formatter) {
        return formatter.formatEditUpdate(oldValue, value);
      });
      
      expect(result.text, 'John');
    });

    test('should limit owner name to 50 characters', () {
      final formatters = [
        FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
        LengthLimitingTextInputFormatter(50),
      ];
      
      final oldValue = TextEditingValue(text: 'John');
      final newValue = TextEditingValue(text: 'A' * 60);
      
      final result = formatters.fold(newValue, (value, formatter) {
        return formatter.formatEditUpdate(oldValue, value);
      });
      
      expect(result.text.length, 50);
    });

    test('should allow valid owner names', () {
      final formatters = [
        FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
        LengthLimitingTextInputFormatter(50),
      ];
      
      final oldValue = TextEditingValue(text: '');
      final newValue = TextEditingValue(text: 'John Doe');
      
      final result = formatters.fold(newValue, (value, formatter) {
        return formatter.formatEditUpdate(oldValue, value);
      });
      
      expect(result.text, 'John Doe');
    });

    test('should allow special characters like apostrophes and hyphens', () {
      final formatters = [
        FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
        LengthLimitingTextInputFormatter(50),
      ];
      
      final oldValue = TextEditingValue(text: '');
      final newValue = TextEditingValue(text: "O'Connor-Smith");
      
      final result = formatters.fold(newValue, (value, formatter) {
        return formatter.formatEditUpdate(oldValue, value);
      });
      
      expect(result.text, "O'Connor-Smith");
    });
  });
}
