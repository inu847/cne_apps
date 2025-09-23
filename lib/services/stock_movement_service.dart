import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock_movement_model.dart';
import '../config/api_config.dart';
import '../utils/error_handler.dart';

class StockMovementService {
  String? _token;
  
  // Set token untuk otorisasi
  void setToken(String token) {
    _token = token;
    print('StockMovementService: Token set successfully');
  }
  
  // Mendapatkan daftar stock movements dari API
  Future<List<StockMovement>> getStockMovements({
    int? productId,
    String? type,
    String? referenceType,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    if (_token == null) {
      throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
    }
    
    // Membangun URL dengan query parameters
    final queryParams = <String, String>{};
    if (productId != null) queryParams['product_id'] = productId.toString();
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (referenceType != null && referenceType.isNotEmpty) queryParams['reference_type'] = referenceType;
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
    queryParams['page'] = page.toString();
    queryParams['per_page'] = perPage.toString();
    
    // Membuat URI dengan query parameters
    final uri = Uri.parse(ApiConfig.stockMovementsEndpoint).replace(queryParameters: queryParams);
    
    print('StockMovementService: Fetching stock movements from $uri');
    print('StockMovementService: Headers - Authorization: Bearer ${_token!.substring(0, 10)}...');
    
    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('StockMovementService: Response status code - ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          try {
            final stockMovementsData = responseData['data']['stock_movements'] as List;
            final stockMovements = stockMovementsData.map((movementJson) => StockMovement.fromJson(movementJson)).toList();
            
            print('StockMovementService: Successfully fetched ${stockMovements.length} stock movements');
            return stockMovements;
          } catch (e) {
            print('StockMovementService: Error parsing stock movements data - ${e.toString()}');
            print('StockMovementService: Response data structure - ${responseData['data']}');
            throw Exception('Gagal memproses data pergerakan stok: ${e.toString()}');
          }
        } else {
          print('StockMovementService: API returned success=false or no data');
          throw Exception('Gagal memuat data pergerakan stok: ${responseData['message'] ?? "Unknown error"}');
        }
      } else {
        print('StockMovementService: API returned error status code ${response.statusCode}');
        print('StockMovementService: Response body - ${response.body}');
        
        // Handle API errors including unauthorized
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception('Gagal memuat data pergerakan stok: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('StockMovementService: Exception occurred - ${e.toString()}');
      throw Exception('Gagal memuat data pergerakan stok: ${e.toString()}');
    }
  }
  
  // Mendapatkan stock movement berdasarkan ID
  Future<StockMovement> getStockMovementById(int id) async {
    if (_token == null) {
      throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
    }
    
    final url = '${ApiConfig.stockMovementsEndpoint}/$id';
    
    print('StockMovementService: Fetching stock movement from $url');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('StockMovementService: Response status code - ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          try {
            final stockMovementData = responseData['data']['stock_movement'];
            final stockMovement = StockMovement.fromJson(stockMovementData);
            
            print('StockMovementService: Successfully fetched stock movement with ID $id');
            return stockMovement;
          } catch (e) {
            print('StockMovementService: Error parsing stock movement data - ${e.toString()}');
            throw Exception('Gagal memproses data pergerakan stok: ${e.toString()}');
          }
        } else {
          print('StockMovementService: API returned success=false or no data');
          throw Exception('Gagal memuat data pergerakan stok: ${responseData['message'] ?? "Unknown error"}');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Pergerakan stok tidak ditemukan');
      } else {
        print('StockMovementService: API returned error status code ${response.statusCode}');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception('Gagal memuat data pergerakan stok: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('StockMovementService: Exception occurred - ${e.toString()}');
      throw Exception('Gagal memuat data pergerakan stok: ${e.toString()}');
    }
  }
  
  // Membuat stock movement baru
  Future<StockMovement> createStockMovement(CreateStockMovementRequest request) async {
    if (_token == null) {
      throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
    }
    
    print('StockMovementService: Creating stock movement');
    print('StockMovementService: Request data - ${request.toJson()}');
    
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.stockMovementsEndpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      );
      
      print('StockMovementService: Response status code - ${response.statusCode}');
      print('StockMovementService: Response body - ${response.body}');
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          try {
            final stockMovementData = responseData['data']['stock_movement'];
            final stockMovement = StockMovement.fromJson(stockMovementData);
            
            print('StockMovementService: Successfully created stock movement');
            return stockMovement;
          } catch (e) {
            print('StockMovementService: Error parsing created stock movement data - ${e.toString()}');
            throw Exception('Gagal memproses data pergerakan stok yang dibuat: ${e.toString()}');
          }
        } else {
          throw Exception('Gagal membuat pergerakan stok: ${responseData['message'] ?? "Unknown error"}');
        }
      } else {
        print('StockMovementService: API returned error status code ${response.statusCode}');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception('Gagal membuat pergerakan stok: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('StockMovementService: Exception occurred - ${e.toString()}');
      throw Exception('Gagal membuat pergerakan stok: ${e.toString()}');
    }
  }
  
  // Membuat multiple stock movements (bulk)
  Future<List<StockMovement>> createBulkStockMovements(BulkCreateStockMovementRequest request) async {
    if (_token == null) {
      throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
    }
    
    print('StockMovementService: Creating bulk stock movements');
    print('StockMovementService: Request data - ${request.toJson()}');
    
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.stockMovementsBulkEndpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      );
      
      print('StockMovementService: Response status code - ${response.statusCode}');
      print('StockMovementService: Response body - ${response.body}');
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          try {
            final stockMovementsData = responseData['data']['stock_movements'] as List;
            final stockMovements = stockMovementsData.map((movementJson) => StockMovement.fromJson(movementJson)).toList();
            
            print('StockMovementService: Successfully created ${stockMovements.length} stock movements');
            return stockMovements;
          } catch (e) {
            print('StockMovementService: Error parsing bulk created stock movements data - ${e.toString()}');
            throw Exception('Gagal memproses data pergerakan stok yang dibuat: ${e.toString()}');
          }
        } else {
          throw Exception('Gagal membuat pergerakan stok: ${responseData['message'] ?? "Unknown error"}');
        }
      } else {
        print('StockMovementService: API returned error status code ${response.statusCode}');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception('Gagal membuat pergerakan stok: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('StockMovementService: Exception occurred - ${e.toString()}');
      throw Exception('Gagal membuat pergerakan stok: ${e.toString()}');
    }
  }
  
  // Update stock movement
  Future<StockMovement> updateStockMovement(int id, CreateStockMovementRequest request) async {
    if (_token == null) {
      throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
    }
    
    final url = '${ApiConfig.stockMovementsEndpoint}/$id';
    
    print('StockMovementService: Updating stock movement with ID $id');
    print('StockMovementService: Request data - ${request.toJson()}');
    
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      );
      
      print('StockMovementService: Response status code - ${response.statusCode}');
      print('StockMovementService: Response body - ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          try {
            final stockMovementData = responseData['data']['stock_movement'];
            final stockMovement = StockMovement.fromJson(stockMovementData);
            
            print('StockMovementService: Successfully updated stock movement');
            return stockMovement;
          } catch (e) {
            print('StockMovementService: Error parsing updated stock movement data - ${e.toString()}');
            throw Exception('Gagal memproses data pergerakan stok yang diperbarui: ${e.toString()}');
          }
        } else {
          throw Exception('Gagal memperbarui pergerakan stok: ${responseData['message'] ?? "Unknown error"}');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Pergerakan stok tidak ditemukan');
      } else {
        print('StockMovementService: API returned error status code ${response.statusCode}');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception('Gagal memperbarui pergerakan stok: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('StockMovementService: Exception occurred - ${e.toString()}');
      throw Exception('Gagal memperbarui pergerakan stok: ${e.toString()}');
    }
  }
  
  // Delete stock movement
  Future<void> deleteStockMovement(int id) async {
    if (_token == null) {
      throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
    }
    
    final url = '${ApiConfig.stockMovementsEndpoint}/$id';
    
    print('StockMovementService: Deleting stock movement with ID $id');
    
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('StockMovementService: Response status code - ${response.statusCode}');
      print('StockMovementService: Response body - ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          print('StockMovementService: Successfully deleted stock movement');
          return;
        } else {
          throw Exception('Gagal menghapus pergerakan stok: ${responseData['message'] ?? "Unknown error"}');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Pergerakan stok tidak ditemukan');
      } else if (response.statusCode == 409) {
        // Conflict - cannot delete stock movement with associated transactions
        final Map<String, dynamic> responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Tidak dapat menghapus pergerakan stok yang memiliki transaksi terkait');
      } else {
        print('StockMovementService: API returned error status code ${response.statusCode}');
        
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        throw Exception('Gagal menghapus pergerakan stok: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('StockMovementService: Exception occurred - ${e.toString()}');
      throw Exception('Gagal menghapus pergerakan stok: ${e.toString()}');
    }
  }
}