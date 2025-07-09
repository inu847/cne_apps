import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../config/api_config.dart';
import '../utils/error_handler.dart';
import 'receipt_service.dart';

class ProductService {
  String? _token;
  
  // Set token untuk otorisasi
  void setToken(String token) {
    _token = token;
    print('ProductService: Token set successfully');
  }
  
  // Mendapatkan daftar produk dari API
  Future<List<Product>> getProducts({
    int? categoryId,
    String? search,
    bool? isActive,
    bool? hasStock,
    int page = 1,
    int perPage = 10,
  }) async {
    if (_token == null) {
      // Redirect ke halaman login
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
      throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
    }
    
    // Membangun URL dengan query parameters
    final queryParams = <String, String>{};
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (isActive != null) queryParams['is_active'] = isActive.toString();
    if (hasStock != null) queryParams['has_stock'] = hasStock.toString();
    queryParams['page'] = page.toString();
    queryParams['per_page'] = perPage.toString();
    
    // Membuat URI dengan query parameters
    final uri = Uri.parse(ApiConfig.productsEndpoint).replace(queryParameters: queryParams);
    
    print('ProductService: Fetching products from $uri');
    print('ProductService: Headers - Authorization: Bearer ${_token!.substring(0, 10)}...');
    
    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('ProductService: Response status code - ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          try {
            final productsData = responseData['data']['products'] as List;
            final products = productsData.map((productJson) => Product.fromJson(productJson)).toList();
            
            print('ProductService: Successfully fetched ${products.length} products');
            return products;
          } catch (e) {
            print('ProductService: Error parsing products data - ${e.toString()}');
            print('ProductService: Response data structure - ${responseData['data']}');
            throw Exception('Gagal memproses data produk: ${e.toString()}');
          }
        } else {
          print('ProductService: API returned success=false or no data');
          throw Exception('Gagal memuat data produk: ${responseData['message'] ?? "Unknown error"}');
        }
      } else {
        print('ProductService: API returned error status code ${response.statusCode}');
        print('ProductService: Response body - ${response.body}');
        
        // Handle API errors including unauthorized
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception('Gagal memuat data produk: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('ProductService: Exception occurred - ${e.toString()}');
      throw Exception('Gagal memuat data produk: ${e.toString()}');
    }
  }
}