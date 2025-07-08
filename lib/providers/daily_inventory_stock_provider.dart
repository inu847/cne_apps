import 'package:flutter/foundation.dart';
import 'package:cne_pos_apps/services/daily_inventory_stock_service.dart';
import 'package:cne_pos_apps/models/daily_inventory_stock_model.dart';
import 'package:cne_pos_apps/models/daily_inventory_stock_item_model.dart';

class DailyInventoryStockProvider with ChangeNotifier {
  final DailyInventoryStockService _dailyInventoryStockService = DailyInventoryStockService();
  
  bool _isLoading = false;
  String? _error;
  List<DailyInventoryStock> _dailyInventoryStocks = [];
  Pagination? _pagination;
  DailyInventoryStock? _selectedStock;
  DailyInventoryStockDetail? _selectedStockDetail;
  
  // Filter state
  String? _dateFrom;
  String? _dateTo;
  int? _warehouseId;
  bool? _isLocked;
  int _currentPage = 1;
  int _perPage = 10;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DailyInventoryStock> get dailyInventoryStocks => _dailyInventoryStocks;
  Pagination? get pagination => _pagination;
  DailyInventoryStock? get selectedStock => _selectedStock;
  DailyInventoryStockDetail? get selectedStockDetail => _selectedStockDetail;
  
  // Filter getters
  String? get dateFrom => _dateFrom;
  String? get dateTo => _dateTo;
  int? get warehouseId => _warehouseId;
  bool? get isLocked => _isLocked;
  int get currentPage => _currentPage;
  int get perPage => _perPage;
  
  // Setter untuk filter
  void setFilters({
    String? dateFrom,
    String? dateTo,
    int? warehouseId,
    bool? isLocked,
  }) {
    _dateFrom = dateFrom;
    _dateTo = dateTo;
    _warehouseId = warehouseId;
    _isLocked = isLocked;
    _currentPage = 1; // Reset ke halaman pertama saat filter berubah
    notifyListeners();
  }
  
  // Setter untuk pagination
  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }
  
  void setPerPage(int perPage) {
    _perPage = perPage;
    _currentPage = 1; // Reset ke halaman pertama saat perPage berubah
    notifyListeners();
  }
  
  // Mendapatkan daftar persediaan harian
  Future<bool> fetchDailyInventoryStocks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _dailyInventoryStockService.getDailyInventoryStocks(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        warehouseId: _warehouseId,
        isLocked: _isLocked,
        page: _currentPage,
        perPage: _perPage,
      );
      
      _isLoading = false;
      
      if (result['success']) {
        final data = DailyInventoryStockData.fromJson(result['data']);
        _dailyInventoryStocks = data.dailyInventoryStocks;
        _pagination = data.pagination;
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
  
  // Mendapatkan detail persediaan harian berdasarkan ID
  Future<bool> fetchDailyInventoryStockDetail(int stockId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _dailyInventoryStockService.getDailyInventoryStockDetail(stockId);
      
      _isLoading = false;
      
      if (result['success']) {
        // Pastikan data ada sebelum parsing
        if (result['data'] != null && result['data']['daily_inventory_stock'] != null) {
          final stockData = result['data']['daily_inventory_stock'];
          
          // Debug: Cetak data yang diterima dari API
          print('DailyInventoryStockProvider: Received stock data: $stockData');
          
          // Periksa apakah items ada dalam data
          if (stockData['items'] == null) {
            print('DailyInventoryStockProvider: Warning - items is null in stock data');
          } else if (!(stockData['items'] is List)) {
            print('DailyInventoryStockProvider: Warning - items is not a List in stock data');
          } else {
            print('DailyInventoryStockProvider: Found ${(stockData['items'] as List).length} items in stock data');
          }
          
          // Simpan data dasar untuk kompatibilitas dengan kode yang sudah ada
          _selectedStock = DailyInventoryStock.fromJson(stockData);
          
          // Simpan data detail lengkap dengan items
          _selectedStockDetail = DailyInventoryStockDetail.fromJson(stockData);
          
          notifyListeners();
          return true;
        } else {
          _error = 'Data tidak ditemukan';
          notifyListeners();
          return false;
        }
      } else {
        _error = result['message'] ?? 'Gagal mendapatkan detail persediaan';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Terjadi kesalahan: $e';
      print('DailyInventoryStockProvider: Exception in fetchDailyInventoryStockDetail: $e');
      notifyListeners();
      return false;
    }
  }
  
  // Memperbarui persediaan harian
  Future<bool> updateDailyInventoryStock({
    required int stockId,
    String? stockDate,
    int? warehouseId,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _dailyInventoryStockService.updateDailyInventoryStock(
        stockId: stockId,
        stockDate: stockDate,
        warehouseId: warehouseId,
        notes: notes,
        items: items,
      );
      
      _isLoading = false;
      
      if (result['success']) {
        // Jika berhasil, perbarui data detail yang ada
        if (result['data'] != null && result['data']['daily_inventory_stock'] != null) {
          final stockData = result['data']['daily_inventory_stock'];
          _selectedStock = DailyInventoryStock.fromJson(stockData);
          _selectedStockDetail = DailyInventoryStockDetail.fromJson(stockData);
        }
        
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Gagal memperbarui persediaan harian';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Terjadi kesalahan: $e';
      print('DailyInventoryStockProvider: Exception in updateDailyInventoryStock: $e');
      notifyListeners();
      return false;
    }
  }
  
  // Membersihkan error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Membersihkan selected stock
  void clearSelectedStock() {
    _selectedStock = null;
    _selectedStockDetail = null;
    notifyListeners();
  }
  
  // Reset filter
  void resetFilters() {
    _dateFrom = null;
    _dateTo = null;
    _warehouseId = null;
    _isLocked = null;
    _currentPage = 1;
    notifyListeners();
  }
  
  // Mengunci persediaan harian
  Future<bool> lockDailyInventoryStock(int stockId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _dailyInventoryStockService.lockDailyInventoryStock(stockId);
      
      _isLoading = false;
      
      if (result['success']) {
        // Jika berhasil, perbarui data detail yang ada
        if (result['data'] != null && result['data']['daily_inventory_stock'] != null) {
          final stockData = result['data']['daily_inventory_stock'];
          _selectedStock = DailyInventoryStock.fromJson(stockData);
          _selectedStockDetail = DailyInventoryStockDetail.fromJson(stockData);
        }
        
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Gagal mengunci persediaan harian';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Terjadi kesalahan: $e';
      print('DailyInventoryStockProvider: Exception in lockDailyInventoryStock: $e');
      notifyListeners();
      return false;
    }
  }
  
  // Menghapus persediaan harian
  Future<bool> deleteDailyInventoryStock(int stockId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _dailyInventoryStockService.deleteDailyInventoryStock(stockId);
      
      _isLoading = false;
      
      if (result['success']) {
        // Jika berhasil, bersihkan data detail yang ada
        clearSelectedStock();
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Gagal menghapus persediaan harian';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Terjadi kesalahan: $e';
      print('DailyInventoryStockProvider: Exception in deleteDailyInventoryStock: $e');
      notifyListeners();
      return false;
    }
  }
}