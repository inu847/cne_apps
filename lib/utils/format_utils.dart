/// Utility class for formatting and parsing operations
class FormatUtils {
  /// Safely parses an integer from various value formats
  /// 
  /// Handles different input types:
  /// - Integer values are returned directly
  /// - String values are parsed to integers
  /// - String values with decimal points are parsed to integers (decimal part removed)
  /// - null values return the specified default value
  /// 
  /// Parameters:
  /// - value: The value to parse (can be int, String, or null)
  /// - defaultValue: The default value to return if parsing fails (defaults to 0)
  static int safeParseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    
    if (value is int) return value;
    
    if (value is String) {
      try {
        // Handle string representations of doubles (e.g., "20000.00")
        if (value.contains('.')) {
          return int.parse(double.parse(value).toStringAsFixed(0));
        }
        // Handle string representations of integers
        return int.parse(value);
      } catch (e) {
        print('Error parsing numeric value: $value - $e');
        return defaultValue;
      }
    }
    
    // For any other type, return the default value
    return defaultValue;
  }
  
  /// Safely parses an integer from various value formats, returning null if the value is null
  /// 
  /// Handles different input types:
  /// - Integer values are returned directly
  /// - String values are parsed to integers
  /// - String values with decimal points are parsed to integers (decimal part removed)
  /// - null values return null
  /// 
  /// Parameters:
  /// - value: The value to parse (can be int, String, or null)
  static int? safeParseIntNullable(dynamic value) {
    if (value == null) return null;
    
    if (value is int) return value;
    
    if (value is String) {
      try {
        // Handle string representations of doubles (e.g., "20000.00")
        if (value.contains('.')) {
          return int.parse(double.parse(value).toStringAsFixed(0));
        }
        // Handle string representations of integers
        return int.parse(value);
      } catch (e) {
        print('Error parsing numeric value: $value - $e');
        return null;
      }
    }
    
    // For any other type, return null
    return null;
  }
  
  /// Formats an integer price value to a readable currency string with thousand separators
  /// 
  /// Example: 20000 becomes "20.000"
  static String formatCurrency(int price) {
    return price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => '.');
  }
  
  /// Formats a nullable integer price value to a readable currency string with thousand separators
  /// 
  /// Example: 20000 becomes "20.000", null becomes "-"
  /// 
  /// Parameters:
  /// - price: The price to format (can be null)
  /// - nullDisplay: The string to display if price is null (defaults to "-")
  static String formatCurrencyNullable(int? price, {String nullDisplay = "-"}) {
    if (price == null) return nullDisplay;
    return formatCurrency(price);
  }
}