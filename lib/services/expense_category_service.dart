import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense_category_model.dart';
import '../config/api_config.dart';
import '../utils/error_handler.dart';

class ExpenseCategoryService {
  // Menggunakan endpoint sesuai dokumentasi API
  final String expenseCategoriesEndpoint = '${ApiConfig.baseUrl}/expense-categories';
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Menambahkan token ke header
  void setToken(String token) {
    headers['Authorization'] = 'Bearer $token';
    print('ExpenseCategoryService: Token set in headers - Bearer ${token.substring(0, 10)}...');
    // Cetak semua headers untuk debugging
    headers.forEach((key, value) {
      print('ExpenseCategoryService: Header - $key: ${key.toLowerCase() == 'authorization' ? "Bearer ${value.substring(7, 17)}..." : value}');
    });
  }

  // 1. Get All Expense Categories - GET /api/expense-categories
  Future<ExpenseCategoryResponse> getExpenseCategories({
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
      final uriComponents = Uri.parse(expenseCategoriesEndpoint);
      
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
      
      print('ExpenseCategoryService: Requesting $uri');
      print('ExpenseCategoryService: Headers $headers');
      
      // Melakukan request
      final response = await http.get(uri, headers: headers);
      
      print('ExpenseCategoryService: Response status ${response.statusCode}');
      print('ExpenseCategoryService: Response body ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      
      // Memeriksa status response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final expenseCategoryResponse = ExpenseCategoryResponse.fromJson(responseData);
          print('ExpenseCategoryService: Loaded ${expenseCategoryResponse.categories.length} expense categories');
          return expenseCategoryResponse;
        } else {
          final errorMsg = 'Failed to load expense categories: ${responseData['message'] ?? "Unknown error"}';
          print('ExpenseCategoryService: Error - $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Failed to load expense categories: Status ${response.statusCode}, Body: ${response.body}';
        print('ExpenseCategoryService: Error - $errorMsg');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Failed to load expense categories: $e';
      print('ExpenseCategoryService: Exception - $errorMsg');
      throw Exception(errorMsg);
    }
  }

  // 2. Create Expense Category - POST /api/expense-categories
  Future<ExpenseCategory> createExpenseCategory(ExpenseCategory category) async {
    try {
      final uriComponents = Uri.parse(expenseCategoriesEndpoint);
      
      Uri uri;
      if (uriComponents.scheme == 'https') {
        uri = Uri.https(uriComponents.authority, uriComponents.path);
      } else {
        uri = Uri.http(uriComponents.authority, uriComponents.path);
      }
      
      print('ExpenseCategoryService: Creating expense category at $uri');
      print('ExpenseCategoryService: Request body ${json.encode(category.toCreateJson())}');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(category.toCreateJson()),
      );
      
      print('ExpenseCategoryService: Create response status ${response.statusCode}');
      print('ExpenseCategoryService: Create response body ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final createdCategory = ExpenseCategory.fromJson(responseData['data']);
          print('ExpenseCategoryService: Expense category created successfully with ID ${createdCategory.id}');
          return createdCategory;
        } else {
          final errorMsg = 'Failed to create expense category: ${responseData['message'] ?? "Unknown error"}';
          print('ExpenseCategoryService: Error - $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Failed to create expense category: Status ${response.statusCode}, Body: ${response.body}';
        print('ExpenseCategoryService: Error - $errorMsg');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Failed to create expense category: $e';
      print('ExpenseCategoryService: Exception - $errorMsg');
      throw Exception(errorMsg);
    }
  }

  // 3. Get Expense Category Details - GET /api/expense-categories/{id}
  Future<ExpenseCategory> getExpenseCategoryById(int id) async {
    try {
      final uriComponents = Uri.parse('$expenseCategoriesEndpoint/$id');
      
      Uri uri;
      if (uriComponents.scheme == 'https') {
        uri = Uri.https(uriComponents.authority, uriComponents.path);
      } else {
        uri = Uri.http(uriComponents.authority, uriComponents.path);
      }
      
      print('ExpenseCategoryService: Getting expense category details at $uri');
      
      final response = await http.get(uri, headers: headers);
      
      print('ExpenseCategoryService: Get details response status ${response.statusCode}');
      print('ExpenseCategoryService: Get details response body ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final category = ExpenseCategory.fromJson(responseData['data']);
          print('ExpenseCategoryService: Expense category details loaded for ID $id');
          return category;
        } else {
          final errorMsg = 'Failed to get expense category details: ${responseData['message'] ?? "Unknown error"}';
          print('ExpenseCategoryService: Error - $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Failed to get expense category details: Status ${response.statusCode}, Body: ${response.body}';
        print('ExpenseCategoryService: Error - $errorMsg');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Failed to get expense category details: $e';
      print('ExpenseCategoryService: Exception - $errorMsg');
      throw Exception(errorMsg);
    }
  }

  // 4. Update Expense Category - PUT /api/expense-categories/{id}
  Future<ExpenseCategory> updateExpenseCategory(int id, ExpenseCategory category) async {
    try {
      final uriComponents = Uri.parse('$expenseCategoriesEndpoint/$id');
      
      Uri uri;
      if (uriComponents.scheme == 'https') {
        uri = Uri.https(uriComponents.authority, uriComponents.path);
      } else {
        uri = Uri.http(uriComponents.authority, uriComponents.path);
      }
      
      print('ExpenseCategoryService: Updating expense category at $uri');
      print('ExpenseCategoryService: Request body ${json.encode(category.toUpdateJson())}');
      
      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(category.toUpdateJson()),
      );
      
      print('ExpenseCategoryService: Update response status ${response.statusCode}');
      print('ExpenseCategoryService: Update response body ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final updatedCategory = ExpenseCategory.fromJson(responseData['data']);
          print('ExpenseCategoryService: Expense category updated successfully with ID ${updatedCategory.id}');
          return updatedCategory;
        } else {
          final errorMsg = 'Failed to update expense category: ${responseData['message'] ?? "Unknown error"}';
          print('ExpenseCategoryService: Error - $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Failed to update expense category: Status ${response.statusCode}, Body: ${response.body}';
        print('ExpenseCategoryService: Error - $errorMsg');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Failed to update expense category: $e';
      print('ExpenseCategoryService: Exception - $errorMsg');
      throw Exception(errorMsg);
    }
  }

  // 5. Delete Expense Category - DELETE /api/expense-categories/{id}
  Future<bool> deleteExpenseCategory(int id) async {
    try {
      final uriComponents = Uri.parse('$expenseCategoriesEndpoint/$id');
      
      Uri uri;
      if (uriComponents.scheme == 'https') {
        uri = Uri.https(uriComponents.authority, uriComponents.path);
      } else {
        uri = Uri.http(uriComponents.authority, uriComponents.path);
      }
      
      print('ExpenseCategoryService: Deleting expense category at $uri');
      
      final response = await http.delete(uri, headers: headers);
      
      print('ExpenseCategoryService: Delete response status ${response.statusCode}');
      print('ExpenseCategoryService: Delete response body ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          print('ExpenseCategoryService: Expense category deleted successfully with ID $id');
          return true;
        } else {
          final errorMsg = 'Failed to delete expense category: ${responseData['message'] ?? "Unknown error"}';
          print('ExpenseCategoryService: Error - $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Failed to delete expense category: Status ${response.statusCode}, Body: ${response.body}';
        print('ExpenseCategoryService: Error - $errorMsg');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Failed to delete expense category: $e';
      print('ExpenseCategoryService: Exception - $errorMsg');
      throw Exception(errorMsg);
    }
  }

  // Method untuk mendapatkan expense categories untuk dropdown
  Future<List<ExpenseCategory>> getExpenseCategoriesForDropdown() async {
    try {
      final response = await getExpenseCategories(isActive: true, perPage: 100);
      return response.categories;
    } catch (e) {
      print('ExpenseCategoryService: Failed to get expense categories for dropdown: $e');
      return [];
    }
  }
}