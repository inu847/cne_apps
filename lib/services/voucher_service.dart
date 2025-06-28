import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class VoucherService {
  final AuthService _authService = AuthService();
  
  // Memvalidasi voucher
  Future<Map<String, dynamic>> validateVoucher({
    required String code,
    required double orderAmount,
    int? customerId,
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
      
      // Siapkan body request
      final Map<String, dynamic> requestBody = {
        'code': code,
        'order_amount': orderAmount,
      };
      
      // Tambahkan customer_id jika ada
      if (customerId != null) {
        requestBody['customer_id'] = customerId;
      }
      
      // Kirim request
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/vouchers/validate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': 'Voucher berhasil divalidasi'
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Voucher tidak valid'
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