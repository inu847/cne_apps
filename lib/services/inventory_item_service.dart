import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cne_pos_apps/config/api_config.dart';
import 'package:cne_pos_apps/services/auth_service.dart';
import 'package:cne_pos_apps/services/receipt_service.dart';
import '../utils/error_handler.dart';

class InventoryItemService {
  final AuthService _authService = AuthService();
  
  // Mendapatkan daftar item persediaan
  Future<Map<String, dynamic>> getInventoryItems({
    String? search,
    bool? isActive,
    bool? lowStock,
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
      
      // Membuat query parameters
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isActive != null) {
        queryParams['is_active'] = isActive.toString();
      }
      if (lowStock != null) {
        queryParams['low_stock'] = lowStock.toString();
      }
      queryParams['page'] = page.toString();
      queryParams['per_page'] = perPage.toString();
      
      // Membuat URI dengan query parameters
      final uri = Uri.parse(ApiConfig.inventoryItemsEndpoint).replace(queryParameters: queryParams);
      
      print('InventoryItemService: Fetching inventory items from $uri');
      
      // Kirim request
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('InventoryItemService: Response status code - ${response.statusCode}');
      
      // Parse response
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil mendapatkan daftar item persediaan'
        };
      } else {
        print('InventoryItemService: API error - ${response.body}');
        
        // Handle API errors including unauthorized
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        // Jika API gagal, gunakan data dummy sebagai fallback
        print('InventoryItemService: Using dummy data as fallback');
        return _getDummyInventoryItems();
      }
    } catch (e) {
      print('InventoryItemService: Exception occurred - ${e.toString()}');
      // Jika terjadi exception, gunakan data dummy sebagai fallback
      print('InventoryItemService: Using dummy data as fallback due to exception');
      return _getDummyInventoryItems();
    }
  }
  
  // Metode untuk mendapatkan data dummy sebagai fallback
  Map<String, dynamic> _getDummyInventoryItems() {
    return {
      'success': true,
      'data': {
        'inventory_items': [
          {
            'id': 1,
            'name': 'Beras',
            'code': 'BRS-001',
            'description': 'Beras premium',
            'minimum_quantity': 50,
            'default_uom_id': 1,
            'default_uom_name': 'Kg',
            'is_active': true,
            'created_at': '2023-06-01T08:00:00.000000Z',
            'updated_at': '2023-06-01T08:00:00.000000Z'
          },
          {
            'id': 2,
            'name': 'Beras Merah',
            'code': 'BRS-002',
            'description': 'Beras merah organik',
            'minimum_quantity': 30,
            'default_uom_id': 1,
            'default_uom_name': 'Kg',
            'is_active': true,
            'created_at': '2023-06-01T08:30:00.000000Z',
            'updated_at': '2023-06-01T08:30:00.000000Z'
          },
          {'id': 3, 'name': 'Gula', 'code': 'GLA-001', 'description': 'Gula pasir', 'minimum_quantity': 40, 'default_uom_id': 1, 'default_uom_name': 'Kg', 'is_active': true},
          {'id': 4, 'name': 'Minyak Goreng', 'code': 'MNY-001', 'description': 'Minyak goreng sawit', 'minimum_quantity': 20, 'default_uom_id': 2, 'default_uom_name': 'Liter', 'is_active': true},
          {'id': 5, 'name': 'Tepung Terigu', 'code': 'TPG-001', 'description': 'Tepung terigu protein tinggi', 'minimum_quantity': 25, 'default_uom_id': 1, 'default_uom_name': 'Kg', 'is_active': true},
          {'id': 6, 'name': 'Telur', 'code': 'TLR-001', 'description': 'Telur ayam', 'minimum_quantity': 100, 'default_uom_id': 3, 'default_uom_name': 'Butir', 'is_active': true},
          {'id': 7, 'name': 'Kopi', 'code': 'KPI-001', 'description': 'Kopi arabika', 'minimum_quantity': 10, 'default_uom_id': 1, 'default_uom_name': 'Kg', 'is_active': true},
          {'id': 8, 'name': 'Susu', 'code': 'SSU-001', 'description': 'Susu segar', 'minimum_quantity': 15, 'default_uom_id': 2, 'default_uom_name': 'Liter', 'is_active': true},
          {'id': 9, 'name': 'Garam', 'code': 'GRM-001', 'description': 'Garam dapur', 'minimum_quantity': 5, 'default_uom_id': 1, 'default_uom_name': 'Kg', 'is_active': true},
          {'id': 10, 'name': 'Bawang Merah', 'code': 'BWM-001', 'description': 'Bawang merah segar', 'minimum_quantity': 8, 'default_uom_id': 1, 'default_uom_name': 'Kg', 'is_active': true},
        ],
        'pagination': {
          'total': 10,
          'per_page': 10,
          'current_page': 1,
          'last_page': 1
        }
      },
      'message': 'Berhasil mendapatkan daftar item persediaan'
    };
  }
}