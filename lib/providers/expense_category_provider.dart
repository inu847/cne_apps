import 'package:flutter/material.dart';
import '../models/expense_category_model.dart';
import '../services/expense_category_service.dart';
import '../services/auth_service.dart';

class ExpenseCategoryProvider extends ChangeNotifier {
  final ExpenseCategoryService _expenseCategoryService = ExpenseCategoryService();
  final AuthService _authService = AuthService();
  
  List<ExpenseCategory> _expenseCategories = [];
  ExpenseCategory? _selectedExpenseCategory;
  ExpenseCategoryPagination? _pagination;
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  String? _error;
  
  // Search and filter state
  String _searchQuery = '';
  bool? _isActiveFilter;
  int _currentPage = 1;
  int _perPage = 15;

  // Getters
  List<ExpenseCategory> get expenseCategories => _expenseCategories;
  ExpenseCategory? get selectedExpenseCategory => _selectedExpenseCategory;
  ExpenseCategoryPagination? get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool? get isActiveFilter => _isActiveFilter;
  int get currentPage => _currentPage;
  int get perPage => _perPage;
  
  // Computed getters
  bool get hasNextPage => _pagination != null && _currentPage < _pagination!.lastPage;
  bool get hasPreviousPage => _currentPage > 1;
  int get totalExpenseCategories => _pagination?.total ?? 0;

  // Initialize expense categories
  Future<void> initExpenseCategories() async {
    await fetchExpenseCategories();
  }

  // Current filters
  String? _currentSearch;
  bool? _currentIsActive;
  
  // Method untuk set filters
  void setFilters({String? search, bool? isActive}) {
    _currentSearch = search;
    _currentIsActive = isActive;
  }

  // Fetch expense categories from API
  Future<void> fetchExpenseCategories({
    String? search,
    bool? isActive,
    int? page,
    int? perPage,
    bool refresh = false,
  }) async {
    _isLoading = true;
    _error = null;
    
    // Update search and filter state if provided
    if (search != null) _searchQuery = search;
    if (isActive != null) _isActiveFilter = isActive;
    if (page != null) _currentPage = page;
    if (perPage != null) _perPage = perPage;
    
    notifyListeners();

    try {
      // Get token from AuthService
      final token = await _authService.getToken();
      
      if (token != null) {
        // Set token to ExpenseCategoryService
        _expenseCategoryService.setToken(token);
        
        // Get expense categories from API
        final response = await _expenseCategoryService.getExpenseCategories(
          search: search ?? _currentSearch ?? (_searchQuery.isEmpty ? null : _searchQuery),
          isActive: isActive ?? _currentIsActive ?? _isActiveFilter,
          page: _currentPage,
          perPage: _perPage,
        );
        
        if (page == 1 || _currentPage == 1) {
          _expenseCategories = response.categories;
        } else {
          _expenseCategories.addAll(response.categories);
        }
        _pagination = response.pagination;
        _error = null;
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
      }
    } catch (e) {
      _error = 'Gagal memuat kategori pengeluaran: ${e.toString()}';
      print('ExpenseCategoryProvider: Error fetching expense categories - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Method untuk load more expense categories (infinite scroll)
  Future<void> loadMoreExpenseCategories() async {
    if (_pagination != null && _currentPage < _pagination!.lastPage) {
      await fetchExpenseCategories(page: _currentPage + 1);
    }
  }

  // Search expense categories
  Future<void> searchExpenseCategories(String query) async {
    _searchQuery = query;
    _currentPage = 1; // Reset to first page when searching
    await fetchExpenseCategories();
  }

  // Filter expense categories by active status
  Future<void> filterByActiveStatus(bool? isActive) async {
    _isActiveFilter = isActive;
    _currentPage = 1; // Reset to first page when filtering
    await fetchExpenseCategories();
  }

  // Load next page
  Future<void> loadNextPage() async {
    if (hasNextPage && !_isLoading) {
      await fetchExpenseCategories(page: _currentPage + 1);
    }
  }

  // Load previous page
  Future<void> loadPreviousPage() async {
    if (hasPreviousPage && !_isLoading) {
      await fetchExpenseCategories(page: _currentPage - 1);
    }
  }

  // Go to specific page
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= (_pagination?.lastPage ?? 1) && !_isLoading) {
      await fetchExpenseCategories(page: page);
    }
  }

  // Get expense category by ID
  Future<void> getExpenseCategoryById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _expenseCategoryService.setToken(token);
        
        final expenseCategory = await _expenseCategoryService.getExpenseCategoryById(id);
        _selectedExpenseCategory = expenseCategory;
        _error = null;
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
      }
    } catch (e) {
      _error = 'Gagal memuat detail kategori pengeluaran: ${e.toString()}';
      print('ExpenseCategoryProvider: Error getting expense category by ID - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new expense category
  Future<bool> createExpenseCategory(ExpenseCategory expenseCategory) async {
    _isCreating = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _expenseCategoryService.setToken(token);
        
        final createdExpenseCategory = await _expenseCategoryService.createExpenseCategory(expenseCategory);
        
        // Add to local list if we're on the first page
        if (_currentPage == 1) {
          _expenseCategories.insert(0, createdExpenseCategory);
          // Update pagination total
          if (_pagination != null) {
            _pagination = ExpenseCategoryPagination(
              total: _pagination!.total + 1,
              perPage: _pagination!.perPage,
              currentPage: _pagination!.currentPage,
              lastPage: _pagination!.lastPage,
              from: _pagination!.from,
              to: _pagination!.to,
            );
          }
        }
        
        _error = null;
        return true;
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
        return false;
      }
    } catch (e) {
      _error = 'Gagal membuat kategori pengeluaran: ${e.toString()}';
      print('ExpenseCategoryProvider: Error creating expense category - $e');
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // Update expense category
  Future<bool> updateExpenseCategory(int id, ExpenseCategory expenseCategory) async {
    _isUpdating = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _expenseCategoryService.setToken(token);
        
        final updatedExpenseCategory = await _expenseCategoryService.updateExpenseCategory(id, expenseCategory);
        
        // Update in local list
        final index = _expenseCategories.indexWhere((cat) => cat.id == id);
        if (index != -1) {
          _expenseCategories[index] = updatedExpenseCategory;
        }
        
        // Update selected expense category if it's the same
        if (_selectedExpenseCategory?.id == id) {
          _selectedExpenseCategory = updatedExpenseCategory;
        }
        
        _error = null;
        return true;
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
        return false;
      }
    } catch (e) {
      _error = 'Gagal mengupdate kategori pengeluaran: ${e.toString()}';
      print('ExpenseCategoryProvider: Error updating expense category - $e');
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // Delete expense category
  Future<bool> deleteExpenseCategory(int id) async {
    _isDeleting = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _expenseCategoryService.setToken(token);
        
        final success = await _expenseCategoryService.deleteExpenseCategory(id);
        
        if (success) {
          // Remove from local list
          _expenseCategories.removeWhere((cat) => cat.id == id);
          
          // Clear selected expense category if it's the deleted one
          if (_selectedExpenseCategory?.id == id) {
            _selectedExpenseCategory = null;
          }
          
          // Update pagination total
          if (_pagination != null) {
            _pagination = ExpenseCategoryPagination(
              total: _pagination!.total - 1,
              perPage: _pagination!.perPage,
              currentPage: _pagination!.currentPage,
              lastPage: _pagination!.lastPage,
              from: _pagination!.from,
              to: _pagination!.to,
            );
          }
          
          _error = null;
          return true;
        } else {
          _error = 'Gagal menghapus kategori pengeluaran';
          return false;
        }
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
        return false;
      }
    } catch (e) {
      _error = 'Gagal menghapus kategori pengeluaran: ${e.toString()}';
      print('ExpenseCategoryProvider: Error deleting expense category - $e');
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

  // Clear selected expense category
  void clearSelectedExpenseCategory() {
    _selectedExpenseCategory = null;
    notifyListeners();
  }

  // Reset search and filters
  void resetFilters() {
    _searchQuery = '';
    _isActiveFilter = null;
    _currentPage = 1;
    _currentSearch = null;
    _currentIsActive = null;
    notifyListeners();
  }

  // Refresh expense categories (reload current page)
  Future<void> refreshExpenseCategories() async {
    await fetchExpenseCategories(refresh: true);
  }

  // Get expense categories for dropdown (simple list without pagination)
  Future<List<ExpenseCategory>> getExpenseCategoriesForDropdown() async {
    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _expenseCategoryService.setToken(token);
        
        // Get all active expense categories for dropdown
        final response = await _expenseCategoryService.getExpenseCategories(
          isActive: true,
          page: 1,
          perPage: 100, // Get more items for dropdown
        );
        
        return response.categories;
      } else {
        throw Exception('Token tidak ditemukan');
      }
    } catch (e) {
      print('ExpenseCategoryProvider: Error getting expense categories for dropdown - $e');
      return [];
    }
  }
}