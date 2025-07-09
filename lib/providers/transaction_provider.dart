import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/transaction_service.dart';

class Pagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  Pagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      lastPage: json['last_page'],
    );
  }
}

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  Map<String, dynamic>? _lastTransaction;
  List<Map<String, dynamic>> _transactions = [];
  Pagination? _pagination;
  
  // Filter state
  String? _search;
  String? _status;
  String? _customerName;
  String? _startDate;
  String? _endDate;
  int? _minAmount;
  int? _maxAmount;
  int _currentPage = 1;
  int _perPage = 10;
  bool _hasMoreData = true;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  Map<String, dynamic>? get lastTransaction => _lastTransaction;
  List<Map<String, dynamic>> get transactions => _transactions;
  Pagination? get pagination => _pagination;
  bool get hasMoreData => _hasMoreData;
  
  // Filter getters
  String? get search => _search;
  String? get status => _status;
  String? get customerName => _customerName;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  int? get minAmount => _minAmount;
  int? get maxAmount => _maxAmount;
  int get currentPage => _currentPage;
  int get perPage => _perPage;
  
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
        // Tambahkan log untuk debugging
        print('Transaksi berhasil dibuat');
        print('lastTransaction: $_lastTransaction');
        print('invoice_number: ${_lastTransaction?["invoice_number"]}');
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        // Tambahkan log untuk debugging
        print('Gagal membuat transaksi: $_error');
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
  
  // Setter untuk filter
  void setFilters({
    String? search,
    String? status,
    String? customerName,
    String? startDate,
    String? endDate,
    int? minAmount,
    int? maxAmount,
  }) {
    _search = search;
    _status = status;
    _customerName = customerName;
    _startDate = startDate;
    _endDate = endDate;
    _minAmount = minAmount;
    _maxAmount = maxAmount;
    _currentPage = 1; // Reset ke halaman pertama saat filter berubah
    _transactions = []; // Reset daftar transaksi
    _hasMoreData = true; // Reset status data
    notifyListeners();
  }
  
  // Reset filter
  void resetFilters() {
    _search = null;
    _status = null;
    _customerName = null;
    _startDate = null;
    _endDate = null;
    _minAmount = null;
    _maxAmount = null;
    _currentPage = 1;
    _transactions = [];
    _hasMoreData = true;
    notifyListeners();
  }
  
  // Mendapatkan daftar transaksi
  Future<bool> fetchTransactions({
    bool loadMore = false,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    if (loadMore) {
      if (!_hasMoreData || _isLoadingMore) return false;
      _isLoadingMore = true;
    } else {
      _isLoading = true;
      _currentPage = 1;
      _transactions = [];
    }
    
    _error = null;
    
    // Update filter jika parameter diberikan
    if (startDate != null) _startDate = startDate;
    if (endDate != null) _endDate = endDate;
    if (status != null) _status = status;
    
    notifyListeners();
    
    try {
      final result = await _transactionService.getTransactions(
        search: _search,
        status: _status,
        customerName: _customerName,
        startDate: _startDate,
        endDate: _endDate,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        page: _currentPage,
        perPage: _perPage,
      );
      
      if (loadMore) {
        _isLoadingMore = false;
      } else {
        _isLoading = false;
      }
      
      if (result['success']) {
        final newTransactions = List<Map<String, dynamic>>.from(result['data']['transactions']);
        
        if (loadMore) {
          _transactions.addAll(newTransactions);
        } else {
          _transactions = newTransactions;
        }
        
        _pagination = Pagination.fromJson(result['data']['pagination']);
        
        // Periksa apakah masih ada data yang bisa dimuat
        _hasMoreData = _pagination!.currentPage < _pagination!.lastPage;
        
        // Jika loadMore, increment halaman untuk request berikutnya
        if (loadMore && _hasMoreData) {
          _currentPage++;
        }
        
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (loadMore) {
        _isLoadingMore = false;
      } else {
        _isLoading = false;
      }
      _error = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Memuat lebih banyak transaksi (untuk infinite scroll)
  Future<bool> loadMoreTransactions() async {
    return fetchTransactions(loadMore: true);
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
  
  // Mendapatkan detail transaksi berdasarkan ID
  Future<Map<String, dynamic>?> getTransactionDetail(int transactionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _transactionService.getTransactionDetail(transactionId);
      
      _isLoading = false;
      
      if (result['success']) {
        final transactionData = result['data']['transaction'];
        notifyListeners();
        return transactionData;
      } else {
        _error = result['message'];
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Terjadi kesalahan: $e';
      notifyListeners();
      return null;
    }
  }
  
  // State untuk rekapitulasi harian
  bool _isLoadingDailyRecap = false;
  Map<String, dynamic>? _dailyRecapData;
  
  // State untuk detail rekapitulasi harian
  bool _isLoadingDailyRecapDetails = false;
  Map<String, dynamic>? _dailyRecapDetailsData;
  
  // Getters untuk rekapitulasi harian
  bool get isLoadingDailyRecap => _isLoadingDailyRecap;
  Map<String, dynamic>? get dailyRecapData => _dailyRecapData;
  
  // Getters untuk detail rekapitulasi harian
  bool get isLoadingDailyRecapDetails => _isLoadingDailyRecapDetails;
  Map<String, dynamic>? get dailyRecapDetailsData => _dailyRecapDetailsData;
  
  // Mendapatkan rekapitulasi harian
  Future<bool> fetchDailyRecap({
    String? date,
    int? warehouseId,
  }) async {
    _isLoadingDailyRecap = true;
    _error = null;
    notifyListeners();
    
    try {
      print('TransactionProvider: Fetching daily recap with date: $date, warehouseId: $warehouseId');
      final result = await _transactionService.getDailyRecap(
        date: date,
        warehouseId: warehouseId,
      );
      
      _isLoadingDailyRecap = false;
      print('TransactionProvider: Daily recap API response success: ${result['success']}');
      
      if (result['success']) {
        print('TransactionProvider: Data structure: ${result.keys}');
        if (result.containsKey('data')) {
          print('TransactionProvider: Data content type: ${result['data'].runtimeType}');
          print('TransactionProvider: Data content: ${result['data']}');
          _dailyRecapData = result['data'];
          notifyListeners();
          return true;
        } else {
          print('TransactionProvider: No data key in result');
          _error = 'Data rekapitulasi tidak ditemukan';
          notifyListeners();
          return false;
        }
      } else {
        print('TransactionProvider: Error message: ${result['message']}');
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('TransactionProvider: Exception in fetchDailyRecap: $e');
      _isLoadingDailyRecap = false;
      _error = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Membersihkan data rekapitulasi harian
  void clearDailyRecapData() {
    _dailyRecapData = null;
    notifyListeners();
  }
  
  // Mendapatkan detail rekapitulasi harian
  Future<bool> fetchDailyRecapDetails({
    required String date,
    int? warehouseId,
    int? pettyCashId,
  }) async {
    _isLoadingDailyRecapDetails = true;
    _error = null;
    notifyListeners();
    
    try {
      print('TransactionProvider: Fetching daily recap details with date: $date, warehouseId: $warehouseId, pettyCashId: $pettyCashId');
      final result = await _transactionService.getDailyRecapDetails(
        date: date,
        warehouseId: warehouseId,
        pettyCashId: pettyCashId,
      );
      
      _isLoadingDailyRecapDetails = false;
      print('TransactionProvider: Daily recap details API response success: ${result['success']}');
      
      if (result['success']) {
        print('TransactionProvider: Data structure: ${result.keys}');
        if (result.containsKey('data')) {
          print('TransactionProvider: Data content type: ${result['data'].runtimeType}');
          print('TransactionProvider: Data content: ${result['data']}');
          _dailyRecapDetailsData = result['data'];
          notifyListeners();
          return true;
        } else {
          print('TransactionProvider: No data key in result');
          _error = 'Data detail rekapitulasi tidak ditemukan';
          notifyListeners();
          return false;
        }
      } else {
        print('TransactionProvider: Error message: ${result['message']}');
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('TransactionProvider: Exception in fetchDailyRecapDetails: $e');
      _isLoadingDailyRecapDetails = false;
      _error = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Membersihkan data detail rekapitulasi harian
  void clearDailyRecapDetailsData() {
    _dailyRecapDetailsData = null;
    notifyListeners();
  }
}