import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/transaction_service.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _lastTransaction;
  List<Map<String, dynamic>> _transactions = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get lastTransaction => _lastTransaction;
  List<Map<String, dynamic>> get transactions => _transactions;
  
  // Membuat transaksi baru
  Future<bool> createTransaction(Order order, {
    bool isParked = false,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? notes,
    int? warehouseId,
    String? voucherCode,
    List<Map<String, dynamic>>? payments,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _transactionService.createTransaction(
        order,
        isParked: isParked,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        notes: notes,
        warehouseId: warehouseId,
        voucherCode: voucherCode,
        payments: payments,
      );
      
      _isLoading = false;
      
      if (result['success']) {
        _lastTransaction = result['data']['transaction'];
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
  
  // Mendapatkan daftar transaksi
  Future<bool> fetchTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _transactionService.getTransactions();
      
      _isLoading = false;
      
      if (result['success']) {
        _transactions = List<Map<String, dynamic>>.from(result['data']['transactions']);
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
  
  // Membersihkan error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Membersihkan transaksi terakhir
  void clearLastTransaction() {
    _lastTransaction = null;
    notifyListeners();
  }
}