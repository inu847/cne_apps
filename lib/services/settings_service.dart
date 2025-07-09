import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/settings_model.dart';
import '../utils/error_handler.dart';
import 'receipt_service.dart';

class SettingsService {
  String? _token;
  StoreSettings? _cachedSettings;
  static const String _settingsCacheKey = 'settings_cache';

  // Set token for authorization
  void setToken(String token) {
    _token = token;
  }

  // Get settings from API
  Future<StoreSettings?> getSettings({String? group, bool refresh = false}) async {
    // Return cached settings if available and not refreshing
    if (_cachedSettings != null && !refresh) {
      print('Using cached settings');
      return _cachedSettings;
    }

    // Check if token is available
    if (_token == null) {
      print('Token is null. Cannot fetch settings.');
      // Redirect ke halaman login
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
      // Try to get cached settings from SharedPreferences
      return await _getCachedSettingsFromPrefs();
    }

    try {
      // Build URL with query parameters if provided
      String url = ApiConfig.settingsEndpoint;
      if (group != null && group.isNotEmpty) {
        url += '?group=$group';
      }

      // Make API request
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10)); // Add timeout to prevent indefinite loading

      print('Settings API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final settingsData = jsonResponse['data']['settings'];
          final settings = StoreSettings.fromJson(settingsData);
          
          // Cache the settings
          _cachedSettings = settings;
          _cacheSettingsToPrefs(settings);
          
          return settings;
        } else {
          print('API returned success: false or no data');
          // Check for unauthorized error
          await ErrorHandler.handleApiError(
            statusCode: response.statusCode,
            responseBody: response.body,
          );
          return await _getCachedSettingsFromPrefs();
        }
      } else {
        print('Failed to load settings. Status code: ${response.statusCode}');
        // Handle API errors including unauthorized
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        return await _getCachedSettingsFromPrefs();
      }
    } catch (e) {
      print('Error fetching settings: $e');
      return await _getCachedSettingsFromPrefs();
    }
  }

  // Cache settings to SharedPreferences
  Future<void> _cacheSettingsToPrefs(StoreSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_settingsCacheKey, settingsJson);
      print('Settings cached to SharedPreferences');
    } catch (e) {
      print('Error caching settings: $e');
    }
  }

  // Get cached settings from SharedPreferences
  Future<StoreSettings?> _getCachedSettingsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsCacheKey);
      
      if (settingsJson != null) {
        print('Retrieved settings from SharedPreferences');
        final settingsMap = jsonDecode(settingsJson);
        return StoreSettings.fromJson(settingsMap);
      }
    } catch (e) {
      print('Error retrieving cached settings: $e');
    }
    
    print('No cached settings found');
    return null;
  }

  // Clear cached settings
  Future<void> clearCachedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsCacheKey);
      _cachedSettings = null;
      print('Cached settings cleared');
    } catch (e) {
      print('Error clearing cached settings: $e');
    }
  }
}