# Error Handling Best Practices

## Overview

This document outlines best practices for error handling in the CNE POS Apps Flutter application. Implementing these practices will improve application stability, user experience, and maintainability.

## Current Error Handling Approach

The current error handling in the application has several strengths:

1. Use of try-catch blocks for critical operations
2. Fallback mechanisms for platform-specific functionality
3. Error logging to console

However, there are opportunities for improvement:

1. Inconsistent error handling across different parts of the application
2. Limited user feedback when errors occur
3. No centralized error tracking or reporting
4. Minimal error recovery mechanisms

## Recommended Error Handling Architecture

### 1. Custom Exception Classes

Create a hierarchy of custom exception classes to represent different types of errors:

```dart
// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  final StackTrace? stackTrace;
  
  AppException(this.message, {this.code, this.details, this.stackTrace});
  
  @override
  String toString() => 'AppException: $code - $message';
}

// Network-related exceptions
class NetworkException extends AppException {
  final int? statusCode;
  
  NetworkException(
    String message, {
    this.statusCode,
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(message, code: code ?? 'NETWORK_ERROR', details: details, stackTrace: stackTrace);
}

// File operation exceptions
class FileException extends AppException {
  final String? path;
  final String? operation;
  
  FileException(
    String message, {
    this.path,
    this.operation,
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'FILE_ERROR',
          details: details ?? {'path': path, 'operation': operation},
          stackTrace: stackTrace,
        );
}

// Platform-specific exceptions
class PlatformException extends AppException {
  final String? platform;
  
  PlatformException(
    String message, {
    this.platform,
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'PLATFORM_ERROR',
          details: details ?? {'platform': platform},
          stackTrace: stackTrace,
        );
}

// PDF generation exceptions
class PdfGenerationException extends AppException {
  PdfGenerationException(
    String message, {
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(message, code: code ?? 'PDF_ERROR', details: details, stackTrace: stackTrace);
}
```

### 2. Centralized Error Handler

Implement a centralized error handler to process all exceptions consistently:

```dart
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();
  
  // Optional: Analytics service for error reporting
  // final AnalyticsService _analytics = AnalyticsService();
  
  // Handle exceptions in a consistent way
  Future<void> handleException(dynamic error, {StackTrace? stackTrace}) async {
    // 1. Log the error
    _logError(error, stackTrace);
    
    // 2. Report to analytics/monitoring service
    // await _reportError(error, stackTrace);
    
    // 3. Show appropriate UI feedback if needed
    _showErrorFeedback(error);
  }
  
  void _logError(dynamic error, StackTrace? stackTrace) {
    final errorMessage = error is AppException 
        ? '${error.code}: ${error.message}'
        : error.toString();
    
    print('ERROR: $errorMessage');
    if (stackTrace != null) {
      print('STACK TRACE: $stackTrace');
    }
    
    // Log additional details for AppException
    if (error is AppException && error.details != null) {
      print('DETAILS: ${error.details}');
    }
  }
  
  // Future<void> _reportError(dynamic error, StackTrace? stackTrace) async {
  //   try {
  //     if (error is AppException) {
  //       await _analytics.logError(
  //         error.code ?? 'UNKNOWN_ERROR',
  //         error.message,
  //         error.details,
  //         stackTrace,
  //       );
  //     } else {
  //       await _analytics.logError(
  //         'UNCATEGORIZED_ERROR',
  //         error.toString(),
  //         null,
  //         stackTrace,
  //       );
  //     }
  //   } catch (e) {
  //     // Fail silently - don't let analytics errors cause more problems
  //     print('Failed to report error: $e');
  //   }
  // }
  
  void _showErrorFeedback(dynamic error) {
    // This could show a snackbar, dialog, or update UI state
    // Implementation depends on how you want to handle user feedback
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text(_getUserFriendlyMessage(error)),
          backgroundColor: Colors.red[700],
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
  
  String _getUserFriendlyMessage(dynamic error) {
    if (error is NetworkException) {
      return 'Network error: Please check your connection and try again.';
    } else if (error is FileException) {
      return 'File operation failed: Unable to access required files.';
    } else if (error is PlatformException) {
      return 'Platform error: This feature may not be supported on your device.';
    } else if (error is PdfGenerationException) {
      return 'Failed to generate receipt: Please try again later.';
    } else if (error is AppException) {
      return error.message;
    } else {
      return 'An unexpected error occurred. Please try again later.';
    }
  }
}
```

### 3. Error Boundary Widget

Implement an error boundary widget to catch and handle errors in the widget tree:

```dart
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, dynamic)? errorBuilder;
  
  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
  }) : super(key: key);
  
  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  dynamic _error;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Show error UI if provided, otherwise show default error widget
      return widget.errorBuilder?.call(context, _error) ?? 
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headline6,
                ),
                SizedBox(height: 8),
                Text(
                  _error.toString(),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                  },
                  child: Text('Try Again'),
                ),
              ],
            ),
          ),
        );
    }
    
    // Use ErrorWidget.builder to catch errors in the widget tree
    return ErrorWidget.builder = (FlutterErrorDetails details) {
      // Log the error
      ErrorHandler().handleException(details.exception, stackTrace: details.stack);
      
      // Update state to show error UI
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _error = details.exception;
          });
        }
      });
      
      // Return empty container while state updates
      return Container();
    };
  }
}
```

## Best Practices for Specific Error Scenarios

### 1. Network Errors

```dart
Future<void> fetchData() async {
  try {
    final response = await http.get(Uri.parse('https://api.example.com/data'));
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success - process data
      final data = jsonDecode(response.body);
      // Process data...
    } else {
      // HTTP error
      throw NetworkException(
        'Failed to fetch data',
        statusCode: response.statusCode,
        details: {'body': response.body},
      );
    }
  } on SocketException catch (e) {
    throw NetworkException(
      'No internet connection',
      details: {'original_error': e.toString()},
      stackTrace: StackTrace.current,
    );
  } on TimeoutException catch (e) {
    throw NetworkException(
      'Connection timed out',
      details: {'original_error': e.toString()},
      stackTrace: StackTrace.current,
    );
  } on FormatException catch (e) {
    throw NetworkException(
      'Invalid response format',
      details: {'original_error': e.toString()},
      stackTrace: StackTrace.current,
    );
  } catch (e, stackTrace) {
    throw NetworkException(
      'Unexpected error during network request',
      details: {'original_error': e.toString()},
      stackTrace: stackTrace,
    );
  }
}

// Usage with error handler
void loadData() async {
  try {
    await fetchData();
  } catch (e, stackTrace) {
    await ErrorHandler().handleException(e, stackTrace: stackTrace);
  }
}
```

### 2. File Operations

```dart
Future<File> saveReceiptPdf(String invoiceNumber, Uint8List pdfBytes) async {
  try {
    final platformService = PlatformService();
    final tempDir = await platformService.getTemporaryDir();
    final filePath = '${tempDir.path}/receipt_$invoiceNumber.pdf';
    
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return file;
  } on FileSystemException catch (e) {
    throw FileException(
      'Failed to save receipt PDF',
      path: 'receipt_$invoiceNumber.pdf',
      operation: 'write',
      details: {'original_error': e.toString()},
      stackTrace: StackTrace.current,
    );
  } catch (e, stackTrace) {
    throw FileException(
      'Unexpected error saving receipt PDF',
      path: 'receipt_$invoiceNumber.pdf',
      operation: 'write',
      details: {'original_error': e.toString()},
      stackTrace: stackTrace,
    );
  }
}
```

### 3. Platform-Specific Operations

```dart
Future<void> initializePlatformFeatures() async {
  try {
    final platformService = PlatformService();
    final platform = await platformService.getPlatformName();
    
    switch (platform) {
      case 'android':
        await _initializeAndroidFeatures();
        break;
      case 'ios':
        await _initializeIOSFeatures();
        break;
      case 'windows':
        await _initializeWindowsFeatures();
        break;
      case 'linux':
        await _initializeLinuxFeatures();
        break;
      case 'macos':
        await _initializeMacOSFeatures();
        break;
      case 'web':
        await _initializeWebFeatures();
        break;
      default:
        throw PlatformException(
          'Unsupported platform',
          platform: platform,
        );
    }
  } catch (e, stackTrace) {
    if (e is PlatformException) {
      throw e;
    }
    
    throw PlatformException(
      'Failed to initialize platform features',
      details: {'original_error': e.toString()},
      stackTrace: stackTrace,
    );
  }
}
```

### 4. PDF Generation

```dart
Future<Uint8List> generateReceiptPdf(Receipt receipt) async {
  try {
    // PDF generation logic...
    return pdfBytes;
  } on Exception catch (e) {
    throw PdfGenerationException(
      'Failed to generate receipt PDF',
      details: {
        'receipt_id': receipt.invoiceNumber,
        'original_error': e.toString(),
      },
      stackTrace: StackTrace.current,
    );
  }
}
```

## Error Recovery Strategies

### 1. Retry Mechanism

```dart
Future<T> withRetry<T>(Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  int attempts = 0;
  while (true) {
    try {
      attempts++;
      return await operation();
    } catch (e) {
      if (attempts >= maxAttempts) {
        rethrow;
      }
      
      // Wait before retrying
      await Future.delayed(delay * attempts);
      
      // Log retry attempt
      print('Retrying operation (attempt $attempts of $maxAttempts)');
    }
  }
}

// Usage
Future<void> fetchDataWithRetry() async {
  try {
    final result = await withRetry(
      () => apiService.fetchData(),
      maxAttempts: 3,
      delay: Duration(seconds: 2),
    );
    // Process result
  } catch (e, stackTrace) {
    await ErrorHandler().handleException(e, stackTrace: stackTrace);
  }
}
```

### 2. Graceful Degradation

```dart
Widget buildReceiptPreview(Receipt receipt) {
  return FutureBuilder<Uint8List>(
    future: _generatePdfWithFallback(receipt),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (snapshot.hasError) {
        // Log the error
        ErrorHandler().handleException(snapshot.error, stackTrace: snapshot.stackTrace);
        
        // Show fallback UI instead of failing completely
        return _buildFallbackReceiptView(receipt);
      }
      
      if (!snapshot.hasData) {
        return _buildFallbackReceiptView(receipt);
      }
      
      // Show PDF preview
      return PdfView(data: snapshot.data!);
    },
  );
}

Future<Uint8List> _generatePdfWithFallback(Receipt receipt) async {
  try {
    return await receiptService.generateReceiptPdf(receipt);
  } catch (e, stackTrace) {
    ErrorHandler().handleException(e, stackTrace: stackTrace);
    
    // Try simplified PDF generation as fallback
    try {
      return await receiptService.generateSimplifiedReceiptPdf(receipt);
    } catch (e, stackTrace) {
      ErrorHandler().handleException(e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

Widget _buildFallbackReceiptView(Receipt receipt) {
  // Simple text-based receipt view as fallback
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Receipt #${receipt.invoiceNumber}', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Date: ${receipt.transactionDate}'),
          Divider(),
          // Display receipt items
          ...receipt.order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.name),
                Text('${item.quantity} x ${item.price}'),
                Text('${item.quantity * item.price}'),
              ],
            ),
          )),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${receipt.order.total}', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ),
  );
}
```

## Error Monitoring and Reporting

To complete your error handling strategy, consider implementing error monitoring and reporting:

1. **Logging Service**: Implement a logging service that can write logs to a file and/or send them to a remote server.

2. **Crash Reporting**: Integrate a crash reporting service like Firebase Crashlytics, Sentry, or AppCenter.

3. **User Feedback**: Provide a mechanism for users to report errors and provide feedback.

## Conclusion

Implementing these error handling best practices will significantly improve the robustness and user experience of the CNE POS Apps. The key principles to follow are:

1. Use custom exception classes for different error types
2. Implement a centralized error handler
3. Provide meaningful feedback to users
4. Implement recovery strategies
5. Monitor and report errors

By following these practices, you can create a more resilient application that gracefully handles errors and provides a better user experience even when things go wrong.