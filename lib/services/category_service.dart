import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../config/api_config.dart';
import '../utils/error_handler.dart';

class CategoryService {
  // Menggunakan endpoint dari ApiConfig
  final String categoriesEndpoint = ApiConfig.categoriesEndpoint;
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Menambahkan token ke header
  void setToken(String token) {
    headers['Authorization'] = 'Bearer $token';
    print('CategoryService: Token set in headers - Bearer ${token.substring(0, 10)}...');
    // Cetak semua headers untuk debugging
    headers.forEach((key, value) {
      print('CategoryService: Header - $key: ${key.toLowerCase() == 'authorization' ? "Bearer ${value.substring(7, 17)}..." : value}');
    });
  }

  // Mendapatkan semua kategori
  Future<List<Category>> getCategories({
    String? search,
    String? status,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      // Membangun query parameters
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      queryParams['page'] = page.toString();
      queryParams['per_page'] = perPage.toString();

      // Membuat URL dengan query parameters
      // Parsing URL untuk mendapatkan komponen-komponennya
      final uriComponents = Uri.parse(categoriesEndpoint);
      
      // Membuat URI dengan komponen yang benar
      Uri uri;
      if (uriComponents.scheme == 'https') {
        uri = Uri.https(
          uriComponents.authority, // host + port
          uriComponents.path,
          queryParams
        );
      } else {
        uri = Uri.http(
          uriComponents.authority, // host + port
          uriComponents.path,
          queryParams
        );
      }
      
      print('CategoryService: Requesting $uri');
      print('CategoryService: Original Endpoint: $categoriesEndpoint');
      print('CategoryService: Headers $headers');
      
      // Debug: Parse URL components
      print('CategoryService: URL Scheme: ${uriComponents.scheme}');
      print('CategoryService: URL Host: ${uriComponents.host}');
      print('CategoryService: URL Path: ${uriComponents.path}');
      print('CategoryService: URL Authority: ${uriComponents.authority}');
      
      // Melakukan request
      final response = await http.get(uri, headers: headers);
      
      print('CategoryService: Response status ${response.statusCode}');
      print('CategoryService: Response body ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      
      // Memeriksa status response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final categoriesData = responseData['data']['categories'] as List;
          final categories = categoriesData.map((categoryJson) => Category.fromJson(categoryJson)).toList();
          print('CategoryService: Loaded ${categories.length} categories');
          return categories;
        } else {
          final errorMsg = 'Failed to load categories: ${responseData['message'] ?? "Unknown error"}';
          print('CategoryService: Error - $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Failed to load categories: Status ${response.statusCode}, Body: ${response.body}';
        print('CategoryService: Error - $errorMsg');
        
        // Handle API errors including unauthorized
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Failed to load categories: $e';
      print('CategoryService: Exception - $errorMsg');
      throw Exception(errorMsg);
    }
  }
}