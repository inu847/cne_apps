import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/receipt_service.dart';

class ErrorHandler {
  static final AuthService _authService = AuthService();

  /// Handle API response errors and redirect to login if unauthorized
  static Future<void> handleApiError({
    required int statusCode,
    required String responseBody,
    BuildContext? context,
  }) async {
    try {
      // Parse response body
      final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
      
      // Check for unauthorized error
      if (statusCode == 401 || 
          (jsonResponse['success'] == false && 
           jsonResponse['error_code'] == 'unauthorized')) {
        
        print('Unauthorized access detected. Redirecting to login.');
        
        // Clear user session
        await _authService.logout();
        
        // Navigate to login screen using global navigator key
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
        
        // Show error message if context is available
        if (context != null && context.mounted) {
          _showErrorSnackBar(
            context, 
            jsonResponse['message'] ?? 'Sesi Anda telah berakhir. Silakan login kembali.'
          );
        }
      }
    } catch (e) {
      print('Error parsing API response: $e');
      
      // If status code is 401, still redirect to login
      if (statusCode == 401) {
        await _authService.logout();
        
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      }
    }
  }

  /// Show error message using SnackBar
  static void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle general API errors with user-friendly messages
  static void handleGeneralError(BuildContext context, String error) {
    String userFriendlyMessage;
    
    if (error.contains('SocketException') || error.contains('TimeoutException')) {
      userFriendlyMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    } else if (error.contains('FormatException')) {
      userFriendlyMessage = 'Terjadi kesalahan dalam memproses data.';
    } else {
      userFriendlyMessage = 'Terjadi kesalahan yang tidak terduga.';
    }
    
    _showErrorSnackBar(context, userFriendlyMessage);
  }
}