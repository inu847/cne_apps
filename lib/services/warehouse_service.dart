import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cne_pos_apps/config/api_config.dart';
import 'package:cne_pos_apps/services/auth_service.dart';

class WarehouseService {
  final AuthService _authService = AuthService();
  
  // Mendapatkan daftar gudang
  Future<Map<String, dynamic>> getWarehouses() async {
    try {
      // Dapatkan token
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token autentikasi. Silakan login kembali.'
        };
      }
      
      // Membuat URI
      final uri = Uri.parse(ApiConfig.warehousesEndpoint);
      
      print('WarehouseService: Fetching warehouses from $uri');
      
      // Kirim request
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('WarehouseService: Response status code - ${response.statusCode}');
      
      // Parse response
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil mendapatkan daftar gudang'
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mendapatkan daftar gudang'
        };
      }
    } catch (e) {
      print('WarehouseService: Exception occurred - ${e.toString()}');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }
}