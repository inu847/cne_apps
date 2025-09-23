import 'package:flutter/material.dart';
import '../models/stock_movement_model.dart';
import '../services/stock_movement_service.dart';
import '../services/auth_service.dart';

class StockMovementProvider extends ChangeNotifier {
  final StockMovementService _stockMovementService = StockMovementService();
  final AuthService _authService = AuthService();
  
  List<StockMovement> _stockMovements = [];
  StockMovement? _selectedStockMovement;
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  String? _error;
  
  // Filter state
  int? _productIdFilter;
  String? _typeFilter;
  String? _referenceTypeFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  int _currentPage = 1;
  int _perPage = 20;
  int _totalStockMovements = 0;
  int _totalPages = 1;

  // Getters
  List<StockMovement> get stockMovements => _stockMovements;
  StockMovement? get selectedStockMovement => _selectedStockMovement;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  String? get error => _error;
  int? get productIdFilter => _productIdFilter;
  String? get typeFilter => _typeFilter;
  String? get referenceTypeFilter => _referenceTypeFilter;
  DateTime? get startDateFilter => _startDateFilter;
  DateTime? get endDateFilter => _endDateFilter;
  int get currentPage => _currentPage;
  int get perPage => _perPage;
  int get totalStockMovements => _totalStockMovements;
  int get totalPages => _totalPages;
  
  // Computed getters
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;
  bool get hasMore => hasNextPage;

  // Initialize stock movements
  Future<void> initStockMovements() async {
    await fetchStockMovements();
  }

  // Set filters
  void setFilters({
    int? productId,
    String? type,
    String? referenceType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _productIdFilter = productId;
    _typeFilter = type;
    _referenceTypeFilter = referenceType;
    _startDateFilter = startDate;
    _endDateFilter = endDate;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _productIdFilter = null;
    _typeFilter = null;
    _referenceTypeFilter = null;
    _startDateFilter = null;
    _endDateFilter = null;
    notifyListeners();
  }

  // Fetch stock movements from API
  Future<void> fetchStockMovements({
    int? productId,
    String? type,
    String? referenceType,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _stockMovements.clear();
      }
      
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Set token from auth service
      final token = await _authService.getToken();
      if (token != null) {
        _stockMovementService.setToken(token);
      } else {
        throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
      }

      final fetchedStockMovements = await _stockMovementService.getStockMovements(
        productId: productId ?? _productIdFilter,
        type: type ?? _typeFilter,
        referenceType: referenceType ?? _referenceTypeFilter,
        startDate: startDate ?? _startDateFilter,
        endDate: endDate ?? _endDateFilter,
        page: page ?? _currentPage,
        perPage: _perPage,
      );

      if (refresh || page == 1) {
        _stockMovements = fetchedStockMovements;
      } else {
        _stockMovements.addAll(fetchedStockMovements);
      }

      // Update pagination info (assuming API returns this info)
      _totalStockMovements = fetchedStockMovements.length;
      _totalPages = (_totalStockMovements / _perPage).ceil();
      
      if (page != null) {
        _currentPage = page;
      }

      print('StockMovementProvider: Fetched ${fetchedStockMovements.length} stock movements');
    } catch (e) {
      _error = e.toString();
      print('StockMovementProvider: Error fetching stock movements - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more stock movements (pagination)
  Future<void> loadMoreStockMovements() async {
    if (!hasNextPage || _isLoading) return;
    
    await fetchStockMovements(page: _currentPage + 1);
  }

  // Refresh stock movements
  Future<void> refreshStockMovements() async {
    await fetchStockMovements(refresh: true);
  }

  // Get stock movement by ID
  Future<void> getStockMovementById(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Set token from auth service
      final token = await _authService.getToken();
      if (token != null) {
        _stockMovementService.setToken(token);
      } else {
        throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
      }

      final stockMovement = await _stockMovementService.getStockMovementById(id);
      _selectedStockMovement = stockMovement;

      print('StockMovementProvider: Fetched stock movement with ID $id');
    } catch (e) {
      _error = e.toString();
      print('StockMovementProvider: Error fetching stock movement by ID - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new stock movement
  Future<bool> createStockMovement(CreateStockMovementRequest request) async {
    try {
      _isCreating = true;
      _error = null;
      notifyListeners();

      // Set token from auth service
      final token = await _authService.getToken();
      if (token != null) {
        _stockMovementService.setToken(token);
      } else {
        throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
      }

      final newStockMovement = await _stockMovementService.createStockMovement(request);
      
      // Add to the beginning of the list
      _stockMovements.insert(0, newStockMovement);
      _totalStockMovements++;

      print('StockMovementProvider: Created new stock movement');
      return true;
    } catch (e) {
      _error = e.toString();
      print('StockMovementProvider: Error creating stock movement - $e');
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // Create bulk stock movements
  Future<bool> createBulkStockMovements(BulkCreateStockMovementRequest request) async {
    try {
      _isCreating = true;
      _error = null;
      notifyListeners();

      // Set token from auth service
      final token = await _authService.getToken();
      if (token != null) {
        _stockMovementService.setToken(token);
      } else {
        throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
      }

      final newStockMovements = await _stockMovementService.createBulkStockMovements(request);
      
      // Add to the beginning of the list
      for (int i = newStockMovements.length - 1; i >= 0; i--) {
        _stockMovements.insert(0, newStockMovements[i]);
      }
      _totalStockMovements += newStockMovements.length;

      print('StockMovementProvider: Created ${newStockMovements.length} stock movements');
      return true;
    } catch (e) {
      _error = e.toString();
      print('StockMovementProvider: Error creating bulk stock movements - $e');
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // Update stock movement
  Future<bool> updateStockMovement(int id, CreateStockMovementRequest request) async {
    try {
      _isUpdating = true;
      _error = null;
      notifyListeners();

      // Set token from auth service
      final token = await _authService.getToken();
      if (token != null) {
        _stockMovementService.setToken(token);
      } else {
        throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
      }

      final updatedStockMovement = await _stockMovementService.updateStockMovement(id, request);
      
      // Update in the list
      final index = _stockMovements.indexWhere((movement) => movement.id == id);
      if (index != -1) {
        _stockMovements[index] = updatedStockMovement;
      }

      // Update selected stock movement if it's the same
      if (_selectedStockMovement?.id == id) {
        _selectedStockMovement = updatedStockMovement;
      }

      print('StockMovementProvider: Updated stock movement with ID $id');
      return true;
    } catch (e) {
      _error = e.toString();
      print('StockMovementProvider: Error updating stock movement - $e');
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // Delete stock movement
  Future<bool> deleteStockMovement(int id) async {
    try {
      _isDeleting = true;
      _error = null;
      notifyListeners();

      // Set token from auth service
      final token = await _authService.getToken();
      if (token != null) {
        _stockMovementService.setToken(token);
      } else {
        throw Exception('Token tidak tersedia. Silakan login terlebih dahulu.');
      }

      await _stockMovementService.deleteStockMovement(id);
      
      // Remove from the list
      _stockMovements.removeWhere((movement) => movement.id == id);
      _totalStockMovements--;

      // Clear selected stock movement if it's the same
      if (_selectedStockMovement?.id == id) {
        _selectedStockMovement = null;
      }

      print('StockMovementProvider: Deleted stock movement with ID $id');
      return true;
    } catch (e) {
      _error = e.toString();
      print('StockMovementProvider: Error deleting stock movement - $e');
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear selected stock movement
  void clearSelectedStockMovement() {
    _selectedStockMovement = null;
    notifyListeners();
  }

  // Set selected stock movement
  void setSelectedStockMovement(StockMovement stockMovement) {
    _selectedStockMovement = stockMovement;
    notifyListeners();
  }

  // Get stock movements by product ID
  List<StockMovement> getStockMovementsByProductId(int productId) {
    return _stockMovements.where((movement) => movement.productId == productId).toList();
  }

  // Get stock movements by type
  List<StockMovement> getStockMovementsByType(String type) {
    return _stockMovements.where((movement) => movement.type == type).toList();
  }

  // Get stock movements by reference type
  List<StockMovement> getStockMovementsByReferenceType(String referenceType) {
    return _stockMovements.where((movement) => movement.referenceType == referenceType).toList();
  }

  // Get stock movements by date range
  List<StockMovement> getStockMovementsByDateRange(DateTime startDate, DateTime endDate) {
    return _stockMovements.where((movement) {
      return movement.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
             movement.createdAt.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
}