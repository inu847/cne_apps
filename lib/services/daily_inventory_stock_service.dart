import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cne_pos_apps/models/daily_inventory_stock_model.dart';
import 'package:cne_pos_apps/models/daily_inventory_stock_item_model.dart';
import 'package:cne_pos_apps/config/api_config.dart';
import 'package:cne_pos_apps/services/auth_service.dart';
import 'receipt_service.dart'; // Import untuk navigatorKey

class DailyInventoryStockService {
  final AuthService _authService = AuthService();
  
  // Mendapatkan daftar persediaan harian
  Future<Map<String, dynamic>> getDailyInventoryStocks({
    String? dateFrom,
    String? dateTo,
    int? warehouseId,
    bool? isLocked,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      // Dapatkan token
      final token = await _authService.getToken();
      if (token == null) {
        // Redirect ke halaman login
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
        return {
          'success': false,
          'message': 'Tidak ada token autentikasi. Silakan login kembali.'
        };
      }
      
      // Membangun URL dengan query parameters
      final queryParams = <String, String>{};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId.toString();
      if (isLocked != null) queryParams['is_locked'] = isLocked ? '1' : '0'; // Menggunakan format '1'/'0' untuk boolean
      queryParams['page'] = page.toString();
      queryParams['per_page'] = perPage.toString();
      
      // Membuat URI dengan query parameters
      final uri = Uri.parse(ApiConfig.dailyInventoryStocksEndpoint).replace(queryParameters: queryParams);
      
      print('DailyInventoryStockService: Fetching daily inventory stocks from $uri');
      
      // Kirim request
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('DailyInventoryStockService: Response status code - ${response.statusCode}');
      
      // Parse response
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil mendapatkan data persediaan harian'
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mendapatkan data persediaan harian'
        };
      }
    } catch (e) {
      print('DailyInventoryStockService: Exception occurred - ${e.toString()}');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }
  
  // Mendapatkan detail persediaan harian berdasarkan ID
  Future<Map<String, dynamic>> getDailyInventoryStockDetail(int stockId) async {
    try {
      // Dapatkan token
      final token = await _authService.getToken();
      if (token == null) {
        // Redirect ke halaman login
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
        return {
          'success': false,
          'message': 'Tidak ada token autentikasi. Silakan login kembali.'
        };
      }
      
      final url = '${ApiConfig.dailyInventoryStocksEndpoint}/$stockId';
      print('DailyInventoryStockService: Fetching stock detail from $url');
      
      // Kirim request
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('DailyInventoryStockService: Response status code - ${response.statusCode}');
      
      // Parse response
      final responseData = jsonDecode(response.body);
      
      // Debug: Cetak respons mentah
      print('DailyInventoryStockService: Raw response - ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Periksa struktur data
        if (responseData['data'] == null) {
          print('DailyInventoryStockService: Warning - data is null in response');
        } else if (responseData['data']['daily_inventory_stock'] == null) {
          print('DailyInventoryStockService: Warning - daily_inventory_stock is null in response data');
        } else {
          final stockData = responseData['data']['daily_inventory_stock'];
          if (stockData['items'] == null) {
            print('DailyInventoryStockService: Warning - items is null in stock data');
          } else if (!(stockData['items'] is List)) {
            print('DailyInventoryStockService: Warning - items is not a List in stock data');
          } else {
            print('DailyInventoryStockService: Found ${(stockData['items'] as List).length} items in stock data');
            // Debug: Cetak item pertama jika ada
            if ((stockData['items'] as List).isNotEmpty) {
              print('DailyInventoryStockService: First item sample - ${(stockData['items'] as List).first}');
            }
          }
        }
        
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil mendapatkan detail persediaan harian'
        };
      } else {
        print('DailyInventoryStockService: Failed to get stock detail - ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mendapatkan detail persediaan harian'
        };
      }
    } catch (e) {
      print('DailyInventoryStockService: Exception occurred - ${e.toString()}');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }
  
  // Membuat persediaan harian baru
  Future<Map<String, dynamic>> createDailyInventoryStock({
    required String stockDate,
    required int warehouseId,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // Dapatkan token
      final token = await _authService.getToken();
      if (token == null) {
        // Redirect ke halaman login
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
        return {
          'success': false,
          'message': 'Tidak ada token autentikasi. Silakan login kembali.'
        };
      }
      
      // Persiapkan data untuk dikirim
      final Map<String, dynamic> requestData = {
        'stock_date': stockDate,
        'warehouse_id': warehouseId,
        'notes': notes ?? '',
        'items': items,
      };
      
      print('DailyInventoryStockService: Creating new stock with data - ${jsonEncode(requestData)}');
      
      // Kirim request
      final response = await http.post(
        Uri.parse(ApiConfig.dailyInventoryStocksEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );
      
      print('DailyInventoryStockService: Response status code - ${response.statusCode}');
      print('DailyInventoryStockService: Raw response - ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
      
      // Parse response
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Persediaan harian berhasil dibuat'
        };
      } else {
        print('DailyInventoryStockService: Failed to create stock - ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal membuat persediaan harian'
        };
      }
    } catch (e) {
      print('DailyInventoryStockService: Exception occurred - ${e.toString()}');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }
  
  // Memperbarui persediaan harian berdasarkan ID
  Future<Map<String, dynamic>> updateDailyInventoryStock({
    required int stockId,
    String? stockDate,
    int? warehouseId,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // Dapatkan token
      final token = await _authService.getToken();
      if (token == null) {
        // Redirect ke halaman login
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
        return {
          'success': false,
          'message': 'Tidak ada token autentikasi. Silakan login kembali.'
        };
      }
      
      // Persiapkan data untuk dikirim
      final Map<String, dynamic> requestData = {
        'items': items,
      };
      
      // Tambahkan field opsional jika ada
      if (stockDate != null) requestData['stock_date'] = stockDate;
      if (warehouseId != null) requestData['warehouse_id'] = warehouseId;
      if (notes != null) requestData['notes'] = notes;
      
      print('DailyInventoryStockService: Updating stock ID $stockId with data - ${jsonEncode(requestData)}');
      
      // Kirim request
      final url = '${ApiConfig.dailyInventoryStocksEndpoint}/$stockId';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );
      
      print('DailyInventoryStockService: Response status code - ${response.statusCode}');
      print('DailyInventoryStockService: Raw response - ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
      
      // Parse response
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Persediaan harian berhasil diperbarui'
        };
      } else {
        print('DailyInventoryStockService: Failed to update stock - ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memperbarui persediaan harian'
        };
      }
    } catch (e) {
      print('DailyInventoryStockService: Exception occurred - ${e.toString()}');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }
  
  // Mengunci persediaan harian berdasarkan ID
  Future<Map<String, dynamic>> lockDailyInventoryStock(int stockId) async {
    try {
      // Dapatkan token
      final token = await _authService.getToken();
      if (token == null) {
        // Redirect ke halaman login
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
        return {
          'success': false,
          'message': 'Tidak ada token autentikasi. Silakan login kembali.'
        };
      }
      
      print('DailyInventoryStockService: Locking stock ID $stockId');
      
      // Kirim request
      final url = '${ApiConfig.dailyInventoryStocksEndpoint}/$stockId/lock';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('DailyInventoryStockService: Response status code - ${response.statusCode}');
      print('DailyInventoryStockService: Raw response - ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
      
      // Parse response
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Persediaan harian berhasil dikunci'
        };
      } else {
        print('DailyInventoryStockService: Failed to lock stock - ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengunci persediaan harian'
        };
      }
    } catch (e) {
      print('DailyInventoryStockService: Exception occurred - ${e.toString()}');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }
  
  // Menghapus persediaan harian berdasarkan ID
  Future<Map<String, dynamic>> deleteDailyInventoryStock(int stockId) async {
    try {
      // Dapatkan token
      final token = await _authService.getToken();
      if (token == null) {
        // Redirect ke halaman login
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
        return {
          'success': false,
          'message': 'Tidak ada token autentikasi. Silakan login kembali.'
        };
      }
      
      print('DailyInventoryStockService: Deleting stock ID $stockId');
      
      // Kirim request
      final url = '${ApiConfig.dailyInventoryStocksEndpoint}/$stockId';
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('DailyInventoryStockService: Response status code - ${response.statusCode}');
      print('DailyInventoryStockService: Raw response - ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
      
      // Parse response
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Persediaan harian berhasil dihapus'
        };
      } else {
        print('DailyInventoryStockService: Failed to delete stock - ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal menghapus persediaan harian'
        };
      }
    } catch (e) {
      print('DailyInventoryStockService: Exception occurred - ${e.toString()}');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }
}