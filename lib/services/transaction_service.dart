import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/order_model.dart';
import 'auth_service.dart';
import '../utils/error_handler.dart';
import 'receipt_service.dart'; // Import untuk navigatorKey

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
        // Handle API errors including unauthorized
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
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
  
  // Mendapatkan daftar transaksi dengan filter dan pagination
  Future<Map<String, dynamic>> getTransactions({
    String? search,
    String? status,
    String? customerName,
    String? startDate,
    String? endDate,
    int? minAmount,
    int? maxAmount,
    int? page,
    int? perPage,
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
      
      // Buat query parameters
      final Map<String, String> queryParams = {};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (customerName != null && customerName.isNotEmpty) queryParams['customer_name'] = customerName;
      if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;
      if (minAmount != null) queryParams['min_amount'] = minAmount.toString();
      if (maxAmount != null) queryParams['max_amount'] = maxAmount.toString();
      if (page != null) queryParams['page'] = page.toString();
      if (perPage != null) queryParams['per_page'] = perPage.toString();
      
      // Kirim request dengan query parameters
      final uri = Uri.parse(ApiConfig.transactionsEndpoint).replace(queryParameters: queryParams);
      
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
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil mendapatkan transaksi'
        };
      } else {
        // Handle API errors including unauthorized
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
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
  
  // Mendapatkan detail transaksi berdasarkan ID
  Future<Map<String, dynamic>> getTransactionDetail(int transactionId) async {
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
      
      // Kirim request
      final response = await http.get(
        Uri.parse('${ApiConfig.transactionsEndpoint}/$transactionId'),
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
          'message': responseData['message'] ?? 'Berhasil mendapatkan detail transaksi'
        };
      } else {
        // Handle API errors including unauthorized
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mendapatkan detail transaksi'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }
  
  // Mendapatkan rekapitulasi harian
  Future<Map<String, dynamic>> getDailyRecap({
    String? date,
    int? warehouseId,
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
      
      // Buat query parameters
      final Map<String, String> queryParams = {};
      if (date != null && date.isNotEmpty) queryParams['date'] = date;
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId.toString();
      
      // Kirim request dengan query parameters
      final uri = Uri.parse(ApiConfig.dailyRecapEndpoint).replace(queryParameters: queryParams);
      
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
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil mendapatkan rekapitulasi harian'
        };
      } else {
        // Handle API errors including unauthorized
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mendapatkan rekapitulasi harian'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }
  
  // Mendapatkan detail rekapitulasi harian
  Future<Map<String, dynamic>> getDailyRecapDetails({
    required String date,
    int? warehouseId,
    int? pettyCashId,
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
      
      // Buat query parameters
      final Map<String, String> queryParams = {
        'date': date,
      };
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId.toString();
      
      // Buat URL dengan path parameter pettyCashId jika ada
      String url = ApiConfig.dailyRecapDetailsEndpoint;
      if (pettyCashId != null) {
        url = '$url/$pettyCashId';
      }
      
      // Kirim request dengan query parameters
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      
      print('TransactionService: Fetching daily recap details from $uri');
      
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
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil mendapatkan detail rekapitulasi harian'
        };
      } else {
        // Handle API errors including unauthorized
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mendapatkan detail rekapitulasi harian'
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