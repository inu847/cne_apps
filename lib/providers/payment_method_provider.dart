import 'package:flutter/foundation.dart';
import '../models/payment_method_model.dart';
import '../services/payment_method_service.dart';

class PaymentMethodProvider with ChangeNotifier {
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  
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
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _paymentMethodService.getPaymentMethods(
        search: search,
        isActive: isActive,
        perPage: perPage,
      );
      
      _isLoading = false;
      
      if (result['success']) {
        _paymentMethods = result['data']['payment_methods'];
        _pagination = result['data']['pagination'];
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