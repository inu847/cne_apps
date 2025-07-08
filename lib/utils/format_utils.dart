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
  
  /// Formats a price value to a readable currency string with thousand separators
  /// 
  /// Example: 20000 becomes "20.000" or "Rp 20.000" if showSymbol is true
  /// Can handle int, double, or String inputs
  /// 
  /// Parameters:
  /// - price: The price to format (can be int, double, or String)
  /// - showSymbol: Whether to show the currency symbol (defaults to true)
  static String formatCurrency(dynamic price, {bool showSymbol = true}) {
    // Handle different input types
    int numericValue;
    
    if (price is int) {
      numericValue = price;
    } else if (price is double) {
      numericValue = price.toInt();
    } else if (price is String) {
      try {
        // Try to parse as double first to handle decimal strings
        numericValue = double.tryParse(price)?.toInt() ?? 0;
      } catch (e) {
        print('Error parsing currency value: $price - $e');
        numericValue = 0;
      }
    } else {
      numericValue = 0;
    }
    
    final formattedValue = numericValue.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => '.');
    return showSymbol ? 'Rp $formattedValue' : formattedValue;
  }
  
  /// Formats a nullable price value to a readable currency string with thousand separators
  /// 
  /// Example: 20000 becomes "20.000" or "Rp 20.000" if showSymbol is true, null becomes "-"
  /// Can handle int, double, or String inputs
  /// 
  /// Parameters:
  /// - price: The price to format (can be null, int, double, or String)
  /// - nullDisplay: The string to display if price is null (defaults to "-")
  /// - showSymbol: Whether to show the currency symbol (defaults to true)
  static String formatCurrencyNullable(dynamic price, {String nullDisplay = "-", bool showSymbol = true}) {
    if (price == null) return nullDisplay;
    return formatCurrency(price, showSymbol: showSymbol);
  }
}