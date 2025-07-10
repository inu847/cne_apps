import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sales_dashboard_model.dart';
import '../config/api_config.dart';
import 'package:cne_pos_apps/services/auth_service.dart';
import 'receipt_service.dart'; // Import untuk navigatorKey

class SalesDashboardService {
  final AuthService _authService = AuthService();
  // Mendapatkan data dashboard laporan penjualan
  Future<Object> getDashboardData({int? period}) async {
    try {
      
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
      
      // Buat URL dengan parameter period jika disediakan
      String url = '${ApiConfig.baseUrl}/sales-reports/dashboard-data';
      if (period != null) {
        url += '?period=$period';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return SalesDashboardData.fromJson(responseData['data']);
        } else {
          throw Exception('Failed to load dashboard data: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 401) {
        // Untuk kasus sesi berakhir, kita perlu menangani secara khusus
        // agar UI dapat menampilkan pesan yang sesuai dan mengarahkan ke login
        throw Exception('Sesi telah berakhir. Silakan login kembali.');
      } else {
        throw Exception('Gagal memuat data dashboard: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting dashboard data: $e');
      throw Exception(e.toString());
    }
  }
}