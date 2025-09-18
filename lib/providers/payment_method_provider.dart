import 'package:flutter/foundation.dart';
import '../models/payment_method_model.dart';
import '../services/payment_method_service.dart';
import '../services/local_storage_service.dart';

class PaymentMethodProvider with ChangeNotifier {
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  final LocalStorageService _localStorageService = LocalStorageService();
  
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _pagination;
  
  // Getters
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get pagination => _pagination;
  
  // Mendapatkan daftar metode pembayaran
  Future<bool> fetchPaymentMethods({
    String? search,
    bool? isActive,
    int perPage = 15,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Coba ambil dari localStorage dulu jika tidak force refresh
      if (!forceRefresh && _localStorageService.isLocalStorageAvailable) {
        try {
          final cachedPaymentMethods = await _localStorageService.getPaymentMethods();
          if (cachedPaymentMethods != null && cachedPaymentMethods.isNotEmpty) {
            print('PaymentMethodProvider: Menggunakan data cached dari localStorage');
            
            // Validasi data integrity
            final validMethods = cachedPaymentMethods.where((method) => 
              method.id != null && 
              method.name != null && 
              method.name!.isNotEmpty &&
              method.code != null &&
              method.code!.isNotEmpty
            ).toList();
            
            if (validMethods.length != cachedPaymentMethods.length) {
              print('PaymentMethodProvider: Found ${cachedPaymentMethods.length - validMethods.length} corrupt payment methods, cleaning up...');
              await _localStorageService.savePaymentMethods(validMethods);
            }
            
            // Filter berdasarkan isActive jika diperlukan
            List<PaymentMethod> filteredMethods = validMethods;
            if (isActive != null) {
              filteredMethods = validMethods.where((method) => method.isActive == isActive).toList();
            }
            
            _paymentMethods = filteredMethods;
            _isLoading = false;
            notifyListeners();
            return true;
          }
        } catch (e) {
          print('PaymentMethodProvider: Error loading from localStorage: $e');
          // Clear corrupt data dan lanjut ke server
          try {
            await _localStorageService.clearPaymentMethods();
          } catch (clearError) {
            print('PaymentMethodProvider: Error clearing corrupt data: $clearError');
          }
        }
      }
      
      // Jika tidak ada cache atau force refresh, ambil dari server
      print('PaymentMethodProvider: Mengambil data dari server');
      final result = await _paymentMethodService.getPaymentMethods(
        search: search,
        isActive: isActive,
        perPage: perPage,
      );
      
      _isLoading = false;
      
      if (result['success']) {
        _paymentMethods = result['data']['payment_methods'];
        _pagination = result['data']['pagination'];
        
        // Simpan ke localStorage
        if (_localStorageService.isLocalStorageAvailable) {
          await _localStorageService.savePaymentMethods(_paymentMethods);
        }
        
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Refresh data metode pembayaran dari server
  Future<bool> refreshPaymentMethods({
    String? search,
    bool? isActive,
    int perPage = 15,
  }) async {
    return await fetchPaymentMethods(
      search: search,
      isActive: isActive,
      perPage: perPage,
      forceRefresh: true,
    );
  }
  
  // Mendapatkan metode pembayaran berdasarkan ID
  PaymentMethod? getPaymentMethodById(int id) {
    try {
      return _paymentMethods.firstWhere((method) => method.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Mendapatkan metode pembayaran berdasarkan kode
  PaymentMethod? getPaymentMethodByCode(String code) {
    try {
      return _paymentMethods.firstWhere((method) => method.code == code);
    } catch (e) {
      return null;
    }
  }
  
  // Membersihkan error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}