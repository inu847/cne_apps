import 'package:flutter/foundation.dart';
import '../models/petty_cash_model.dart';
import '../services/petty_cash_service.dart';

class PettyCashProvider with ChangeNotifier {
  final PettyCashService _pettyCashService = PettyCashService();
  
  bool _isLoading = false;
  String? _error;
  PettyCash? _activePettyCash;
  List<PettyCash> _pettyCashList = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  PettyCash? get activePettyCash => _activePettyCash;
  List<PettyCash> get pettyCashList => _pettyCashList;
  
  // Helper getters
  bool get hasActivePettyCash => _activePettyCash != null && _activePettyCash!.isActive;
  bool get canMakeTransaction => hasActivePettyCash && _activePettyCash!.isOpening;
  String get pettyCashStatus {
    if (_activePettyCash == null) return 'closed';
    if (_activePettyCash!.isOpening && _activePettyCash!.isActive) return 'open';
    if (_activePettyCash!.isClosing) return 'closed';
    return 'closed';
  }
  
  // Mendapatkan status petty cash aktif
  Future<bool> fetchActivePettyCash() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _pettyCashService.getActivePettyCash();
      
      _isLoading = false;
      
      if (result['success']) {
        if (result['data'] != null && result['data']['petty_cash'] != null) {
          _activePettyCash = PettyCash.fromJson(result['data']['petty_cash']);
        } else {
          _activePettyCash = null;
        }
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        _activePettyCash = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Terjadi kesalahan: $e';
      _activePettyCash = null;
      notifyListeners();
      return false;
    }
  }
  
  // Membuka petty cash
  Future<bool> openPettyCash({
    required String name,
    required double amount,
    String? notes,
    int? warehouseId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final request = PettyCashRequest(
        name: name,
        amount: amount,
        type: 'opening',
        date: DateTime.now().toIso8601String().split('T')[0], // Format: YYYY-MM-DD
        notes: notes,
        warehouseId: warehouseId,
      );
      
      final result = await _pettyCashService.openPettyCash(request);
      
      _isLoading = false;
      
      if (result['success']) {
        if (result['data'] != null && result['data']['petty_cash'] != null) {
          _activePettyCash = PettyCash.fromJson(result['data']['petty_cash']);
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
  
  // Menutup petty cash
  Future<bool> closePettyCash({
    required String name,
    required double amount,
    String? notes,
    int? warehouseId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final request = PettyCashRequest(
        name: name,
        amount: amount,
        type: 'closing',
        date: DateTime.now().toIso8601String().split('T')[0], // Format: YYYY-MM-DD
        notes: notes,
        warehouseId: warehouseId,
      );
      
      final result = await _pettyCashService.closePettyCash(request);
      
      _isLoading = false;
      
      if (result['success']) {
        // Setelah closing, set active petty cash menjadi null
        _activePettyCash = null;
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
  
  // Mendapatkan daftar petty cash
  Future<bool> fetchPettyCashList({
    String? status,
    String? type,
    String? startDate,
    String? endDate,
    int? warehouseId,
    int page = 1,
    int perPage = 10,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _pettyCashService.getPettyCashList(
        status: status,
        type: type,
        startDate: startDate,
        endDate: endDate,
        warehouseId: warehouseId,
        page: page,
        perPage: perPage,
      );
      
      _isLoading = false;
      
      if (result['success']) {
        final data = result['data'];
        if (data != null && data['petty_cash'] != null) {
          final pettyCashData = List<Map<String, dynamic>>.from(data['petty_cash']);
          _pettyCashList = pettyCashData.map((item) => PettyCash.fromJson(item)).toList();
        } else {
          _pettyCashList = [];
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
  
  // Mendapatkan detail petty cash
  Future<PettyCash?> getPettyCashDetail(int pettyCashId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _pettyCashService.getPettyCashDetail(pettyCashId);
      
      _isLoading = false;
      
      if (result['success']) {
        if (result['data'] != null) {
          final pettyCash = PettyCash.fromJson(result['data']);
          notifyListeners();
          return pettyCash;
        }
        notifyListeners();
        return null;
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
  
  // Auto open petty cash berdasarkan settings
  Future<bool> autoOpenPettyCash({
    required double amount,
    int? warehouseId,
  }) async {
    return await openPettyCash(
      name: 'Auto Opening - ${DateTime.now().toString().split(' ')[0]}',
      amount: amount,
      notes: 'Pembukaan otomatis berdasarkan pengaturan sistem',
      warehouseId: warehouseId,
    );
  }
  
  // Membersihkan error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Reset state
  void reset() {
    _isLoading = false;
    _error = null;
    _activePettyCash = null;
    _pettyCashList = [];
    notifyListeners();
  }
}