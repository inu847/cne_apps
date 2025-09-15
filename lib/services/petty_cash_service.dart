import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/petty_cash_model.dart';
import 'auth_service.dart';
import '../utils/error_handler.dart';
import 'receipt_service.dart';

class PettyCashService {
  final AuthService _authService = AuthService();

  // Mendapatkan status petty cash aktif
  Future<Map<String, dynamic>> getActivePettyCash() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
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

      print('PettyCashService: Requesting ${ApiConfig.pettyCashActiveOpeningEndpoint}');
      
      final response = await http.get(
        Uri.parse(ApiConfig.pettyCashActiveOpeningEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('PettyCashService: Response status ${response.statusCode}');
      print('PettyCashService: Response body ${response.body}');
      
      final responseData = jsonDecode(response.body);
      print('PettyCashService: Parsed response data: $responseData');

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('PettyCashService: Success response with data: ${responseData['data']}');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil mendapatkan status petty cash'
        };
      } else {
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mendapatkan status petty cash'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // Membuka petty cash (opening)
  Future<Map<String, dynamic>> openPettyCash(PettyCashRequest request) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
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

      print('PettyCashService: Opening petty cash to ${ApiConfig.pettyCashOpeningEndpoint}');
      print('PettyCashService: Request payload: ${jsonEncode(request.toJson())}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.pettyCashOpeningEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );
      
      print('PettyCashService: Opening response status ${response.statusCode}');
      print('PettyCashService: Opening response body ${response.body}');

      final responseData = jsonDecode(response.body);

      if (responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil membuka petty cash'
        };
      } else {
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal membuka petty cash'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // Menutup petty cash (closing)
  Future<Map<String, dynamic>> closePettyCash(PettyCashRequest request) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
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

      print('PettyCashService: Closing petty cash to ${ApiConfig.pettyCashClosingEndpoint}');
      print('PettyCashService: Request payload: ${jsonEncode(request.toJson())}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.pettyCashClosingEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );
      
      print('PettyCashService: Closing response status ${response.statusCode}');
      print('PettyCashService: Closing response body ${response.body}');

      final responseData = jsonDecode(response.body);

      if (responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil menutup petty cash'
        };
      } else {
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal menutup petty cash'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // Mendapatkan daftar petty cash
  Future<Map<String, dynamic>> getPettyCashList({
    String? status,
    String? type,
    String? startDate,
    String? endDate,
    int? warehouseId,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
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
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId.toString();

      final uri = Uri.parse(ApiConfig.pettyCashEndpoint).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil mendapatkan daftar petty cash'
        };
      } else {
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mendapatkan daftar petty cash'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // Mendapatkan detail petty cash berdasarkan ID
  Future<Map<String, dynamic>> getPettyCashDetail(int pettyCashId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
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

      final response = await http.get(
        Uri.parse('${ApiConfig.pettyCashEndpoint}/$pettyCashId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Berhasil mendapatkan detail petty cash'
        };
      } else {
        await ErrorHandler.handleApiError(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mendapatkan detail petty cash'
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