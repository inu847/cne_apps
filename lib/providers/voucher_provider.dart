import 'package:flutter/foundation.dart';
import '../services/voucher_service.dart';

class VoucherProvider with ChangeNotifier {
  final VoucherService _voucherService = VoucherService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _activeVoucher;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get activeVoucher => _activeVoucher;
  
  // Getter untuk nilai diskon
  double get discountValue {
    if (_activeVoucher == null || !_activeVoucher!.containsKey('voucher')) return 0.0;
    
    final voucherData = _activeVoucher!['voucher'];
    if (voucherData == null) return 0.0;
    
    // Menggunakan discount_amount sebagai nilai diskon sesuai dengan respons API
    final discountAmount = voucherData['discount_amount'];
    
    if (discountAmount == null) return 0.0;
    
    // Handle jika discount_amount adalah String
    if (discountAmount is String) {
      try {
        return double.parse(discountAmount);
      } catch (e) {
        print('Error parsing discount_amount: $discountAmount - $e');
        return 0.0;
      }
    }
    
    // Handle jika discount_amount adalah num
    if (discountAmount is num) {
      return discountAmount.toDouble();
    }
    
    return 0.0; // Default jika tipe data tidak dikenali
  }
  
  // Getter untuk tipe diskon (percentage atau fixed)
  String get discountType {
    if (_activeVoucher == null || !_activeVoucher!.containsKey('voucher')) return '';
    
    final voucherData = _activeVoucher!['voucher'];
    if (voucherData == null) return '';
    
    final type = voucherData['discount_type'];
    if (type == null) return '';
    
    // Pastikan nilai yang dikembalikan adalah String
    return type.toString();
  }
  
  // Getter untuk kode voucher
  String get voucherCode {
    if (_activeVoucher == null || !_activeVoucher!.containsKey('voucher')) return '';
    
    final voucherData = _activeVoucher!['voucher'];
    if (voucherData == null) return '';
    
    final code = voucherData['code'];
    if (code == null) return '';
    
    // Pastikan nilai yang dikembalikan adalah String
    return code.toString();
  }
  
  // Getter untuk nama voucher
  String get voucherName {
    if (_activeVoucher == null || !_activeVoucher!.containsKey('voucher')) return '';
    
    final voucherData = _activeVoucher!['voucher'];
    if (voucherData == null) return '';
    
    final name = voucherData['name'];
    if (name == null) return '';
    
    // Pastikan nilai yang dikembalikan adalah String
    return name.toString();
  }
  
  // Memvalidasi voucher
  Future<bool> validateVoucher({
    required String code,
    required double orderAmount,
    int? customerId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _voucherService.validateVoucher(
        code: code,
        orderAmount: orderAmount,
        customerId: customerId,
      );
      
      _isLoading = false;
      
      if (result['success']) {
        _activeVoucher = result['data'];
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
  
  // Membersihkan voucher aktif
  void clearVoucher() {
    _activeVoucher = null;
    notifyListeners();
  }
  
  // Membersihkan error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}