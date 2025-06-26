import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/payment_method_model.dart';
import 'auth_service.dart';

class PaymentMethodService {
  final AuthService _authService = AuthService();
  
  // Mendapatkan daftar metode pembayaran
  Future<Map<String, dynamic>> getPaymentMethods({
    String? search,
    bool? isActive,
    int perPage = 15,
  }) async {
    try {
      // Dapatkan token
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token autentikasi. Silakan login kembali.'
        };
      }
      
      // Buat query parameters
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isActive != null) {
        queryParams['is_active'] = isActive.toString();
      }
      queryParams['per_page'] = perPage.toString();
      
      // Kirim request
      final uri = Uri.parse(ApiConfig.paymentMethodsEndpoint).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      // Parse response
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Konversi data JSON ke objek PaymentMethod
        final List<dynamic> paymentMethodsJson = responseData['data']['payment_methods'];
        final List<PaymentMethod> paymentMethods = paymentMethodsJson
            .map((json) => PaymentMethod.fromJson(json))
            .toList();
        
        return {
          'success': true,
          'data': {
            'payment_methods': paymentMethods,
            'pagination': responseData['data']['pagination'],
          },
          'message': responseData['message'] ?? 'Berhasil mendapatkan metode pembayaran'
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mendapatkan metode pembayaran'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }
}