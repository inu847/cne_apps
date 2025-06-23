class ApiConfig {
  // Base URL for API
  static const String baseUrl = 'http://cne.test/api';
  
  // API Endpoints
  static const String loginEndpoint = '$baseUrl/login';
  static const String logoutEndpoint = '$baseUrl/logout';
  
  // Token Key for SharedPreferences
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
}