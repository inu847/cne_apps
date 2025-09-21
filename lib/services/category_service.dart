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

  // 1. Get All Categories - GET /api/categories
  Future<CategoryResponse> getCategories({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      // Membangun query parameters
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isActive != null) {
        queryParams['is_active'] = isActive.toString();
      }
      queryParams['page'] = page.toString();
      queryParams['per_page'] = perPage.toString();

      // Membuat URL dengan query parameters
      final uriComponents = Uri.parse(categoriesEndpoint);
      
      Uri uri;
      if (uriComponents.scheme == 'https') {
        uri = Uri.https(
          uriComponents.authority,
          uriComponents.path,
          queryParams
        );
      } else {
        uri = Uri.http(
          uriComponents.authority,
          uriComponents.path,
          queryParams
        );
      }
      
      print('CategoryService: Requesting $uri');
      print('CategoryService: Headers $headers');
      
      // Melakukan request
      final response = await http.get(uri, headers: headers);
      
      print('CategoryService: Response status ${response.statusCode}');
      print('CategoryService: Response body ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      
      // Memeriksa status response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final categoryResponse = CategoryResponse.fromJson(responseData);
          print('CategoryService: Loaded ${categoryResponse.categories.length} categories');
          return categoryResponse;
        } else {
          final errorMsg = 'Failed to load categories: ${responseData['message'] ?? "Unknown error"}';
          print('CategoryService: Error - $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Failed to load categories: Status ${response.statusCode}, Body: ${response.body}';
        print('CategoryService: Error - $errorMsg');
        
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

  // 2. Create Category - POST /api/categories
  Future<Category> createCategory(Category category) async {
    try {
      final uriComponents = Uri.parse(categoriesEndpoint);
      
      Uri uri;
      if (uriComponents.scheme == 'https') {
        uri = Uri.https(uriComponents.authority, uriComponents.path);
      } else {
        uri = Uri.http(uriComponents.authority, uriComponents.path);
      }
      
      print('CategoryService: Creating category at $uri');
      print('CategoryService: Request body ${json.encode(category.toCreateJson())}');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(category.toCreateJson()),
      );
      
      print('CategoryService: Create response status ${response.statusCode}');
      print('CategoryService: Create response body ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final categoryData = responseData['data']['category'];
          final createdCategory = Category.fromJson(categoryData);
          print('CategoryService: Category created successfully with ID ${createdCategory.id}');
          return createdCategory;
        } else {
          final errorMsg = 'Failed to create category: ${responseData['message'] ?? "Unknown error"}';
          print('CategoryService: Error - $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Failed to create category: Status ${response.statusCode}, Body: ${response.body}';
        print('CategoryService: Error - $errorMsg');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Failed to create category: $e';
      print('CategoryService: Exception - $errorMsg');
      throw Exception(errorMsg);
    }
  }

  // 3. Get Category Details - GET /api/categories/{id}
  Future<Category> getCategoryById(int id) async {
    try {
      final uriComponents = Uri.parse('$categoriesEndpoint/$id');
      
      Uri uri;
      if (uriComponents.scheme == 'https') {
        uri = Uri.https(uriComponents.authority, uriComponents.path);
      } else {
        uri = Uri.http(uriComponents.authority, uriComponents.path);
      }
      
      print('CategoryService: Getting category details at $uri');
      
      final response = await http.get(uri, headers: headers);
      
      print('CategoryService: Get details response status ${response.statusCode}');
      print('CategoryService: Get details response body ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final categoryData = responseData['data']['category'];
          final category = Category.fromJson(categoryData);
          print('CategoryService: Category details loaded for ID $id');
          return category;
        } else {
          final errorMsg = 'Failed to get category details: ${responseData['message'] ?? "Unknown error"}';
          print('CategoryService: Error - $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Failed to get category details: Status ${response.statusCode}, Body: ${response.body}';
        print('CategoryService: Error - $errorMsg');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Failed to get category details: $e';
      print('CategoryService: Exception - $errorMsg');
      throw Exception(errorMsg);
    }
  }

  // 4. Update Category - PUT /api/categories/{id}
  Future<Category> updateCategory(int id, Category category) async {
    try {
      final uriComponents = Uri.parse('$categoriesEndpoint/$id');
      
      Uri uri;
      if (uriComponents.scheme == 'https') {
        uri = Uri.https(uriComponents.authority, uriComponents.path);
      } else {
        uri = Uri.http(uriComponents.authority, uriComponents.path);
      }
      
      print('CategoryService: Updating category at $uri');
      print('CategoryService: Update request body ${json.encode(category.toUpdateJson())}');
      
      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(category.toUpdateJson()),
      );
      
      print('CategoryService: Update response status ${response.statusCode}');
      print('CategoryService: Update response body ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final categoryData = responseData['data']['category'];
          final updatedCategory = Category.fromJson(categoryData);
          print('CategoryService: Category updated successfully for ID $id');
          return updatedCategory;
        } else {
          final errorMsg = 'Failed to update category: ${responseData['message'] ?? "Unknown error"}';
          print('CategoryService: Error - $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Failed to update category: Status ${response.statusCode}, Body: ${response.body}';
        print('CategoryService: Error - $errorMsg');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Failed to update category: $e';
      print('CategoryService: Exception - $errorMsg');
      throw Exception(errorMsg);
    }
  }

  // 5. Delete Category - DELETE /api/categories/{id}
  Future<bool> deleteCategory(int id) async {
    try {
      final uriComponents = Uri.parse('$categoriesEndpoint/$id');
      
      Uri uri;
      if (uriComponents.scheme == 'https') {
        uri = Uri.https(uriComponents.authority, uriComponents.path);
      } else {
        uri = Uri.http(uriComponents.authority, uriComponents.path);
      }
      
      print('CategoryService: Deleting category at $uri');
      
      final response = await http.delete(uri, headers: headers);
      
      print('CategoryService: Delete response status ${response.statusCode}');
      print('CategoryService: Delete response body ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          print('CategoryService: Category deleted successfully for ID $id');
          return true;
        } else {
          final errorMsg = 'Failed to delete category: ${responseData['message'] ?? "Unknown error"}';
          print('CategoryService: Error - $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Failed to delete category: Status ${response.statusCode}, Body: ${response.body}';
        print('CategoryService: Error - $errorMsg');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Failed to delete category: $e';
      print('CategoryService: Exception - $errorMsg');
      throw Exception(errorMsg);
    }
  }

  // Helper method untuk mendapatkan categories sederhana (backward compatibility)
  Future<List<Category>> getCategoriesSimple({
    String? search,
    String? status,
    int page = 1,
    int perPage = 10,
  }) async {
    bool? isActive;
    if (status != null) {
      isActive = status.toLowerCase() == 'active' || status == 'true';
    }
    
    final response = await getCategories(
      search: search,
      isActive: isActive,
      page: page,
      perPage: perPage,
    );
    
    return response.categories;
  }
}