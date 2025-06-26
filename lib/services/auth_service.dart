import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Login user
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(responseData);

      if (authResponse.success && authResponse.data != null) {
        // Save token and user data to SharedPreferences
        await _saveAuthData(authResponse.data!);
      }

      return authResponse;
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }

  // Logout user
  Future<bool> logout() async {
    try {
      final token = await getToken();
      if (token == null) return true; // Already logged out

      final response = await http.post(
        Uri.parse(ApiConfig.logoutEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Clear stored auth data
        await _clearAuthData();
        return true;
      }
      return false;
    } catch (e) {
      print('Logout error: ${e.toString()}');
      return false;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(ApiConfig.userDataKey);
    
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConfig.tokenKey);
    print('AuthService: Retrieved token - ${token != null ? "Token exists with length ${token.length}" : "Token is null"}');
    return token;
  }

  // Save auth data to SharedPreferences
  Future<void> _saveAuthData(AuthData authData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.tokenKey, authData.token);
    await prefs.setString(ApiConfig.userDataKey, jsonEncode(authData.user.toJson()));
  }

  // Clear auth data from SharedPreferences
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.tokenKey);
    await prefs.remove(ApiConfig.userDataKey);
  }
}