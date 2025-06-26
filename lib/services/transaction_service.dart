import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/order_model.dart';
import 'auth_service.dart';

class TransactionService {
  final AuthService _authService = AuthService();
  
  // Membuat transaksi baru
  Future<Map<String, dynamic>> createTransaction(Order order, {
    bool isParked = false,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? notes,
    int? warehouseId,
    String? voucherCode,
    List<Map<String, dynamic>>? payments,
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
      
      // Siapkan item transaksi
      final List<Map<String, dynamic>> items = order.items.map((item) => {
        'product_id': item.productId,
        'quantity': item.quantity,
        'unit_price': item.price,
        'discount_amount': 0, // Sesuaikan jika ada diskon per item
        'tax_amount': (item.price * item.quantity * (order.tax / order.subtotal)).round(), // Distribusi pajak per item
        'subtotal': item.price * item.quantity
      }).toList();
      
      // Siapkan pembayaran default jika tidak ada
      final List<Map<String, dynamic>> transactionPayments = payments ?? [
        {
          'payment_method_id': 1, // Asumsi 1 adalah Cash
          'amount': order.total,
          'reference_number': 'REF-${DateTime.now().millisecondsSinceEpoch}'
        }
      ];
      
      // Siapkan body request
      final Map<String, dynamic> requestBody = {
        'items': items,
        'payments': transactionPayments,
        'subtotal': order.subtotal,
        'tax_amount': order.tax,
        'discount_amount': 0, // Sesuaikan jika ada diskon
        'total_amount': order.total,
        'customer_name': customerName ?? 'Pelanggan Umum',
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'notes': notes ?? '',
        'is_parked': isParked,
        'warehouse_id': warehouseId ?? 1, // Default warehouse
        'voucher_code': voucherCode
      };
      
      // Kirim request
      final response = await http.post(
        Uri.parse(ApiConfig.transactionsEndpoint),
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
          'message': responseData['message']
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal membuat transaksi'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }
  
  // Mendapatkan daftar transaksi
  Future<Map<String, dynamic>> getTransactions() async {
    try {
      // Dapatkan token
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token autentikasi. Silakan login kembali.'
        };
      }
      
      // Kirim request
      final response = await http.get(
        Uri.parse(ApiConfig.transactionsEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      // Parse response
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil mendapatkan transaksi'
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mendapatkan transaksi'
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