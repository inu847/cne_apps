import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/transaction_service.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../providers/connectivity_provider.dart';

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
  final LocalStorageService _localStorageService = LocalStorageService();
  final AuthService _authService = AuthService();
  ConnectivityProvider? _connectivityProvider;
  
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
  
  // Inisialisasi provider dan migrasi data
  Future<void> initialize() async {
    try {
      // Lakukan migrasi data dari key lama jika ada
      await _localStorageService.migrateTransactionData();
      print('TransactionProvider: Inisialisasi dan migrasi data selesai');
    } catch (e) {
      print('TransactionProvider: Error during initialization: $e');
    }
  }
  
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
  
  // Membuat transaksi offline dan menyimpan ke local storage
  Future<bool> createOfflineTransaction(
    Map<String, dynamic> order, {
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
      // Generate ID unik untuk transaksi offline
      final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      
      // Ambil data order
      final orderItems = order['items'] as List<dynamic>? ?? [];
      final subtotal = order['subtotal'] ?? order['total_amount'] ?? 0;
      final taxAmount = order['tax_amount'] ?? 0;
      final discountAmount = order['discount_amount'] ?? 0;
      final totalAmount = order['total_amount'] ?? order['grand_total'] ?? 0;
      
      // Format items sesuai struktur API POST
      final List<Map<String, dynamic>> formattedItems = orderItems.map((item) {
        final itemMap = item as Map<String, dynamic>;
        final quantity = itemMap['quantity'] ?? 1;
        final unitPrice = itemMap['price'] ?? itemMap['unit_price'] ?? 0;
        final itemSubtotal = unitPrice * quantity;
        
        // Distribusi pajak per item berdasarkan proporsi subtotal
        final itemTaxAmount = subtotal > 0 
            ? (itemSubtotal * taxAmount / subtotal).round() 
            : 0;
        
        return {
          'product_id': itemMap['productId'] ?? itemMap['product_id'],
          'quantity': quantity,
          'unit_price': unitPrice,
          'discount_amount': 0, // Sesuaikan jika ada diskon per item
          'tax_amount': itemTaxAmount,
          'subtotal': itemSubtotal
        };
      }).toList();
      
      // Format payments sesuai struktur API POST
      final List<Map<String, dynamic>> formattedPayments = payments?.map((payment) {
        return {
          'payment_method_id': payment['payment_method_id'] ?? payment['paymentMethodId'] ?? 1,
          'amount': payment['amount'] ?? totalAmount,
          'reference_number': payment['reference_number'] ?? payment['referenceNumber'] ?? 'REF-OFFLINE-${now.millisecondsSinceEpoch}'
        };
      }).toList() ?? [
        {
          'payment_method_id': 1, // Default Cash
          'amount': totalAmount,
          'reference_number': 'REF-OFFLINE-${now.millisecondsSinceEpoch}'
        }
      ];
      
      // Buat struktur transaksi offline yang sesuai dengan API POST format
      final offlineTransaction = {
        // === PAYLOAD FIELDS UNTUK API POST (struktur yang sama dengan createTransaction) ===
        'items': formattedItems,
        'payments': formattedPayments,
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'discount_amount': discountAmount,
        'total_amount': totalAmount,
        'customer_name': customerName ?? 'Walk-in Customer',
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'notes': notes ?? '',
        'is_parked': isParked,
        'warehouse_id': warehouseId ?? 1, // Default warehouse
        'voucher_code': voucherCode,
        
        // === FIELDS TAMBAHAN UNTUK TRACKING DAN UI ===
        'id': offlineId, // ID unik untuk tracking lokal
        'invoice_number': 'INV-OFFLINE-${now.millisecondsSinceEpoch}',
        'transaction_date': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'status': isParked ? 'parked' : 'completed',
        'grand_total': totalAmount, // Alias untuk total_amount (untuk kompatibilitas UI)
        
        // === METADATA AKAN DITAMBAHKAN OLEH saveOfflineTransaction ===
        // 'is_synced': false, // Akan ditambahkan oleh LocalStorageService
        // 'is_offline': true, // Akan ditambahkan oleh LocalStorageService
        // 'source': 'offline', // Akan ditambahkan oleh LocalStorageService
        // 'offline_saved_at': timestamp, // Akan ditambahkan oleh LocalStorageService
      };
      
      // Cek batasan transaksi offline (maksimal 100)
      final existingOfflineTransactions = await _localStorageService.getOfflineTransactions();
      if (existingOfflineTransactions.length >= 100) {
        _isLoading = false;
        _error = 'Maksimal 100 transaksi offline. Silakan sinkronisasi terlebih dahulu.';
        notifyListeners();
        return false;
      }
      
      // Simpan transaksi offline ke localStorage
      final success = await _localStorageService.saveOfflineTransaction(offlineTransaction);
      
      if (success) {
        _lastTransaction = offlineTransaction;
        _isLoading = false;
        
        // Update daftar transaksi jika sedang menampilkan data offline
        if (_connectivityProvider?.isOffline == true) {
          await loadTransactionsFromLocal();
        }
        
        print('TransactionProvider: Transaksi offline berhasil disimpan dengan ID: $offlineId');
        notifyListeners();
        return true;
      } else {
        throw Exception('Gagal menyimpan transaksi offline ke local storage');
      }
      
    } catch (e) {
      _isLoading = false;
      _error = 'Gagal menyimpan transaksi offline: $e';
      print('TransactionProvider: Error creating offline transaction: $e');
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
    return fetchTransactionsWithOfflineSupport(loadMore: true);
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

  // Set connectivity provider untuk cek status online/offline
  void setConnectivityProvider(ConnectivityProvider connectivityProvider) {
    _connectivityProvider = connectivityProvider;
  }

  // Load transaksi dari local storage saat offline
  Future<bool> loadTransactionsFromLocal() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Lakukan migrasi data dari key lama jika ada
      await _localStorageService.migrateTransactionData();

      // Ambil data cache dari API
      final apiCache = await _localStorageService.getTransactionsCache() ?? [];
      
      // Ambil transaksi offline yang belum sync
      final offlineTransactions = await _localStorageService.getOfflineTransactions();
      
      // Ambil data dari key lama sebagai fallback (jika migrasi belum berjalan)
      final legacyTransactions = await _localStorageService.getTransactions() ?? [];
      
      // Gabungkan data dengan menghindari duplikasi
      final combinedTransactions = <Map<String, dynamic>>[];
      final seenIds = <String>{};
      
      // Tambahkan transaksi offline terlebih dahulu (paling baru)
      for (final transaction in offlineTransactions) {
        final id = transaction['id']?.toString();
        if (id != null && !seenIds.contains(id)) {
          combinedTransactions.add(transaction);
          seenIds.add(id);
        }
      }
      
      // Tambahkan data dari API cache
      for (final transaction in apiCache) {
        final id = transaction['id']?.toString();
        if (id != null && !seenIds.contains(id)) {
          combinedTransactions.add(transaction);
          seenIds.add(id);
        }
      }
      
      // Tambahkan data legacy sebagai fallback (hindari duplikasi)
      for (final transaction in legacyTransactions) {
        final id = transaction['id']?.toString();
        if (id != null && !seenIds.contains(id)) {
          // Tandai sebagai data legacy untuk tracking
          final legacyTransaction = Map<String, dynamic>.from(transaction);
          legacyTransaction['source'] = legacyTransaction['source'] ?? 'legacy';
          combinedTransactions.add(legacyTransaction);
          seenIds.add(id);
        }
      }
      
      // Urutkan berdasarkan created_at (terbaru di atas)
      combinedTransactions.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      
      _transactions = combinedTransactions;
      _currentPage = 1;
      _hasMoreData = false; // Local data tidak support pagination
      
      print('TransactionProvider: ${offlineTransactions.length} transaksi offline + ${apiCache.length} transaksi cache + ${legacyTransactions.length} transaksi legacy dimuat dari local storage');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('TransactionProvider: Error loading from local storage: $e');
      _isLoading = false;
      _error = 'Gagal memuat data offline: $e';
      notifyListeners();
      return false;
    }
  }

  // Simpan transaksi ke local storage setelah fetch dari API
  Future<void> saveTransactionsToLocal(List<Map<String, dynamic>> transactions) async {
    try {
      await _localStorageService.saveTransactionsCache(transactions);
      print('TransactionProvider: ${transactions.length} transaksi disimpan ke API cache');
    } catch (e) {
      print('TransactionProvider: Error saving to API cache: $e');
    }
  }

  // Update status sync transaksi di local storage
  Future<bool> updateTransactionSyncStatus(List<String> transactionIds, bool isSynced) async {
    try {
      if (isSynced) {
        // Jika transaksi berhasil sync, update status dan cleanup
        final success = await _localStorageService.updateOfflineTransactionSyncStatus(transactionIds, isSynced);
        
        if (success) {
          // Cleanup transaksi yang sudah sync dari offline storage
          await _localStorageService.cleanupSyncedOfflineTransactions();
          
          // Update data di memory juga
          for (final transaction in _transactions) {
            final id = transaction['id']?.toString();
            if (id != null && transactionIds.contains(id)) {
              transaction['is_synced'] = true;
              transaction['synced_at'] = DateTime.now().toIso8601String();
            }
          }
          
          notifyListeners();
          print('TransactionProvider: ${transactionIds.length} transaksi berhasil disync dan dibersihkan dari offline storage');
        }
        
        return success;
      } else {
        // Fallback ke method lama untuk kasus lain
        final success = await _localStorageService.updateOfflineTransactionSyncStatus(transactionIds, isSynced);
        if (success) {
          // Update data di memory juga
          for (final transaction in _transactions) {
            final id = transaction['id']?.toString();
            if (id != null && transactionIds.contains(id)) {
              transaction['is_synced'] = isSynced;
              transaction['synced_at'] = isSynced ? DateTime.now().toIso8601String() : null;
            }
          }
          notifyListeners();
          print('TransactionProvider: Status sync ${transactionIds.length} transaksi berhasil diperbarui');
        }
        return success;
      }
    } catch (e) {
      print('TransactionProvider: Error updating sync status: $e');
      return false;
    }
  }

  // Ambil transaksi yang belum tersinkronisasi
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    try {
      return await _localStorageService.getUnsyncedTransactions();
    } catch (e) {
      print('TransactionProvider: Error getting unsynced transactions: $e');
      return [];
    }
  }

  // Cek apakah sedang offline dan load data sesuai kondisi
  Future<bool> fetchTransactionsWithOfflineSupport({
    bool loadMore = false,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    try {
      if (loadMore) {
        if (!_hasMoreData || _isLoadingMore) return false;
        _isLoadingMore = true;
      } else {
        _isLoading = true;
      }
      _error = null;
      notifyListeners();
      
      // Cek koneksi internet
      final isOnline = _connectivityProvider?.isOnline ?? true;
      
      if (isOnline) {
        // Mode online: ambil dari API
        final result = await _transactionService.getTransactions(
          search: _search,
          status: _status,
          customerName: _customerName,
          startDate: startDate ?? _startDate,
          endDate: endDate ?? _endDate,
          minAmount: _minAmount,
          maxAmount: _maxAmount,
          page: loadMore ? _currentPage : 1,
          perPage: _perPage,
        );
        
        if (result['success']) {
          final newTransactions = List<Map<String, dynamic>>.from(result['data']['transactions']);
          
          // Update pagination info
          _pagination = Pagination.fromJson(result['data']['pagination']);
          _hasMoreData = _pagination!.currentPage < _pagination!.lastPage;
          
          if (loadMore) {
            // Load more: tambahkan data baru ke cache dan gabungkan ulang
            final existingCache = await _localStorageService.getTransactionsCache() ?? [];
            final combinedCache = [...existingCache, ...newTransactions];
            await saveTransactionsToLocal(combinedCache);
            
            // Gabungkan ulang dengan transaksi offline
            await _combineTransactionsData();
            
            if (_hasMoreData) {
              _currentPage++;
            }
            _isLoadingMore = false;
          } else {
            // Load pertama: simpan ke cache dan gabungkan dengan offline
            await saveTransactionsToLocal(newTransactions);
            _currentPage = 1;
            
            // Auto-sync transaksi offline jika ada
            await _autoSyncOfflineTransactions();
            
            // Gabungkan data cache API dengan transaksi offline
            await _combineTransactionsData();
            
            _isLoading = false;
          }
          
          notifyListeners();
          return true;
        } else {
          _error = result['message'];
          if (loadMore) {
            _isLoadingMore = false;
          } else {
            _isLoading = false;
          }
          notifyListeners();
          return false;
        }
      } else {
        // Mode offline: ambil dari localStorage (cache + offline)
        print('TransactionProvider: Mode offline - memuat data dari local storage');
        final success = await loadTransactionsFromLocal();
        if (loadMore) {
          _isLoadingMore = false;
        } else {
          _isLoading = false;
        }
        notifyListeners();
        return success;
      }
    } catch (e) {
      _error = 'Error mengambil transaksi: $e';
      print('TransactionProvider: Error in fetchTransactionsWithOfflineSupport: $e');
      // Fallback ke data lokal jika ada error
      await loadTransactionsFromLocal();
      if (loadMore) {
        _isLoadingMore = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
      return false;
    }
  }
  
  // Method untuk menggabungkan data cache API dengan transaksi offline
   Future<void> _combineTransactionsData() async {
     try {
       // Lakukan migrasi data dari key lama jika ada
       await _localStorageService.migrateTransactionData();
       
       // Ambil data cache dari API
       final apiCache = await _localStorageService.getTransactionsCache() ?? [];
       
       // Ambil transaksi offline yang belum sync
       final offlineTransactions = await _localStorageService.getOfflineTransactions();
       
       // Ambil data dari key lama sebagai fallback (jika migrasi belum berjalan)
       final legacyTransactions = await _localStorageService.getTransactions() ?? [];
       
       // Gabungkan data
       final combinedTransactions = <Map<String, dynamic>>[];
       final seenIds = <String>{};
       
       // Tambahkan transaksi offline terlebih dahulu (paling baru)
       for (final transaction in offlineTransactions) {
         final id = transaction['id']?.toString();
         if (id != null && !seenIds.contains(id)) {
           combinedTransactions.add(transaction);
           seenIds.add(id);
         }
       }
       
       // Tambahkan data dari API cache
       for (final transaction in apiCache) {
         final id = transaction['id']?.toString();
         if (id != null && !seenIds.contains(id)) {
           combinedTransactions.add(transaction);
           seenIds.add(id);
         }
       }
       
       // Tambahkan data legacy sebagai fallback (hindari duplikasi)
       for (final transaction in legacyTransactions) {
         final id = transaction['id']?.toString();
         if (id != null && !seenIds.contains(id)) {
           // Tandai sebagai data legacy untuk tracking
           final legacyTransaction = Map<String, dynamic>.from(transaction);
           legacyTransaction['source'] = legacyTransaction['source'] ?? 'legacy';
           combinedTransactions.add(legacyTransaction);
           seenIds.add(id);
         }
       }
       
       // Urutkan berdasarkan created_at (terbaru di atas)
       combinedTransactions.sort((a, b) {
         final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
         final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
         return dateB.compareTo(dateA);
       });
       
       _transactions = combinedTransactions;
       notifyListeners();
       
       print('TransactionProvider: Berhasil menggabungkan ${offlineTransactions.length} transaksi offline, ${apiCache.length} transaksi dari API cache, dan ${legacyTransactions.length} transaksi legacy');
     } catch (e) {
       print('TransactionProvider: Error combining transactions data: $e');
     }
   }

  // Sinkronisasi otomatis transaksi offline saat online
  Future<void> _autoSyncOfflineTransactions() async {
    try {
      print('TransactionProvider: Memulai sinkronisasi otomatis transaksi offline...');
      
      // Ambil transaksi yang belum tersinkronisasi
      final unsyncedTransactions = await getUnsyncedTransactions();
      
      if (unsyncedTransactions.isEmpty) {
        print('TransactionProvider: Tidak ada transaksi offline yang perlu disinkronisasi');
        return;
      }

      print('TransactionProvider: Ditemukan ${unsyncedTransactions.length} transaksi offline yang perlu disinkronisasi');
      
      int successCount = 0;
      int errorCount = 0;
      List<String> syncedTransactionIds = [];
      
      // Sinkronisasi setiap transaksi
      for (final transaction in unsyncedTransactions) {
        try {
          final result = await _transactionService.syncTransaction(transaction);
          
          if (result['success'] == true) {
            successCount++;
            syncedTransactionIds.add(transaction['id']);
            print('TransactionProvider: Berhasil sinkronisasi transaksi ${transaction['invoice_number']}');
          } else {
            errorCount++;
            final errorMessage = result['message'] ?? 'Unknown error';
            print('TransactionProvider: Gagal sinkronisasi transaksi ${transaction['invoice_number']}: $errorMessage');
            
            // Jika ada masalah autentikasi atau server, hentikan proses sync
            if (errorMessage.contains('autentikasi') || errorMessage.contains('Server error')) {
              print('TransactionProvider: Menghentikan auto-sync karena masalah autentikasi/server');
              break;
            }
          }
        } catch (e) {
          errorCount++;
          print('TransactionProvider: Error sinkronisasi transaksi ${transaction['invoice_number']}: $e');
        }
      }
      
      // Update status sync untuk transaksi yang berhasil
      if (syncedTransactionIds.isNotEmpty) {
        await updateTransactionSyncStatus(syncedTransactionIds, true);
        print('TransactionProvider: Berhasil mengupdate status sync untuk ${syncedTransactionIds.length} transaksi');
      }
      
      if (successCount > 0) {
        print('TransactionProvider: Sinkronisasi selesai. $successCount dari ${unsyncedTransactions.length} transaksi berhasil disinkronisasi');
      } else if (errorCount > 0) {
        print('TransactionProvider: Sinkronisasi gagal. Kemungkinan ada masalah koneksi atau autentikasi');
      }
      
    } catch (e) {
      print('TransactionProvider: Error dalam proses auto-sync: $e');
    }
  }

  // Sinkronisasi transaksi individual ke server
  Future<Map<String, dynamic>> syncIndividualTransaction(Map<String, dynamic> transaction) async {
    try {
      final result = await _transactionService.syncTransaction(transaction);
      
      if (result['success']) {
        print('TransactionProvider: Transaksi ${transaction['invoice_number']} berhasil disinkronisasi');
        
        // Update status sync di local storage
        final transactionId = transaction['id']?.toString();
        if (transactionId != null) {
          await updateTransactionSyncStatus([transactionId], true);
        }
      } else {
        print('TransactionProvider: Gagal sinkronisasi transaksi ${transaction['invoice_number']}: ${result['message']}');
      }
      
      return result;
    } catch (e) {
      print('TransactionProvider: Exception saat sinkronisasi transaksi: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }
}