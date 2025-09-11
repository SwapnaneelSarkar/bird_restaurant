

class ValidationUtils {
  /// Validates that the description contains at least one alphabet character
  /// Returns null if valid, error message if invalid
  static String? validateDescriptionHasAlphabet(String description) {
    if (description.isEmpty) {
      return 'Description is required';
    }
    
    // Check if description contains at least one alphabet character
    final hasAlphabet = RegExp(r'[a-zA-Z]').hasMatch(description);
    if (!hasAlphabet) {
      return 'Description must contain at least one alphabet character';
    }
    
    return null;
  }
  
  /// Validates description length
  /// Returns null if valid, error message if invalid
  static String? validateDescriptionLength(String description, {int maxLength = 100}) {
    if (description.isEmpty) {
      return 'Description is required';
    }
    
    if (description.length > maxLength) {
      return 'Maximum $maxLength characters allowed';
    }
    
    return null;
  }
  
  /// Validates description with both alphabet and length requirements
  /// Returns null if valid, error message if invalid
  static String? validateDescription(String description, {int maxLength = 100}) {
    // First check if it's empty
    if (description.isEmpty) {
      return 'Description is required';
    }
    
    // Check length
    if (description.length > maxLength) {
      return 'Maximum $maxLength characters allowed';
    }
    
    // Check if it contains at least one alphabet character
    final hasAlphabet = RegExp(r'[a-zA-Z]').hasMatch(description);
    if (!hasAlphabet) {
      return 'Description must contain at least one alphabet character';
    }
    
    return null;
  }
}
