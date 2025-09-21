import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../services/auth_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();
  final AuthService _authService = AuthService();

  List<Expense> _expenses = [];
  ExpensePagination? _pagination;
  ExpenseStatistics? _statistics;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  String? _error;
  
  // Filter variables
  String _searchQuery = '';
  String? _startDate;
  String? _endDate;
  int? _selectedCategoryId;
  int? _selectedWarehouseId;
  String? _selectedPaymentMethod;
  bool? _isApprovedFilter;
  double? _minAmount;
  double? _maxAmount;
  
  // Selected items for bulk operations
  Set<int> _selectedExpenseIds = {};

  // Getters
  List<Expense> get expenses => _expenses;
  ExpensePagination? get pagination => _pagination;
  ExpenseStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  int? get selectedCategoryId => _selectedCategoryId;
  int? get selectedWarehouseId => _selectedWarehouseId;
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  bool? get isApprovedFilter => _isApprovedFilter;
  double? get minAmount => _minAmount;
  double? get maxAmount => _maxAmount;
  Set<int> get selectedExpenseIds => _selectedExpenseIds;
  bool get hasSelectedItems => _selectedExpenseIds.isNotEmpty;
  int get selectedItemsCount => _selectedExpenseIds.length;

  // Initialize provider
  Future<void> initialize() async {
    await _setAuthToken();
    await loadExpenses();
    await loadStatistics();
  }

  // Set authentication token
  Future<void> _setAuthToken() async {
    final token = await _authService.getToken();
    if (token != null) {
      _expenseService.setToken(token);
    }
  }

  // Load expenses with current filters
  Future<void> loadExpenses({bool refresh = false}) async {
    if (refresh) {
      _expenses.clear();
      _pagination = null;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _setAuthToken();
      
      final response = await _expenseService.getExpenses(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        startDate: _startDate,
        endDate: _endDate,
        expenseCategoryId: _selectedCategoryId,
        warehouseId: _selectedWarehouseId,
        paymentMethod: _selectedPaymentMethod,
        isApproved: _isApprovedFilter,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        page: 1,
      );

      _expenses = response.expenses;
      _pagination = response.pagination;
      
      print('ExpenseProvider: Loaded ${_expenses.length} expenses');
    } catch (e) {
      _setError(e.toString());
      print('ExpenseProvider: Error loading expenses - $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load more expenses (pagination)
  Future<void> loadMoreExpenses() async {
    if (_isLoadingMore || _pagination == null || _pagination!.currentPage >= _pagination!.lastPage) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      await _setAuthToken();
      
      final response = await _expenseService.getExpenses(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        startDate: _startDate,
        endDate: _endDate,
        expenseCategoryId: _selectedCategoryId,
        warehouseId: _selectedWarehouseId,
        paymentMethod: _selectedPaymentMethod,
        isApproved: _isApprovedFilter,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        page: _pagination!.currentPage + 1,
      );

      _expenses.addAll(response.expenses);
      _pagination = response.pagination;
      
      print('ExpenseProvider: Loaded ${response.expenses.length} more expenses');
    } catch (e) {
      _setError(e.toString());
      print('ExpenseProvider: Error loading more expenses - $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Create new expense
  Future<bool> createExpense(Expense expense) async {
    _isCreating = true;
    _setError(null);
    notifyListeners();

    try {
      await _setAuthToken();
      
      final newExpense = await _expenseService.createExpense(expense);
      _expenses.insert(0, newExpense);
      
      print('ExpenseProvider: Created expense with ID ${newExpense.id}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      print('ExpenseProvider: Error creating expense - $e');
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // Create multiple expenses at once with fallback mechanism
  Future<Map<String, dynamic>> createBulkExpenses(List<Expense> expenses, {Function(int, int)? onProgress}) async {
    _isCreating = true;
    _setError(null);
    notifyListeners();

    int successCount = 0;
    int failCount = 0;
    int currentIndex = 0;
    List<Expense> createdExpenses = [];
    List<String> failedReasons = [];

    try {
      await _setAuthToken();
      
      print('ExpenseProvider: Starting bulk creation of ${expenses.length} expenses');
      
      // Process each expense individually with retry mechanism
      for (var expense in expenses) {
        currentIndex++;
        bool itemCreated = false;
        int retryCount = 0;
        const maxRetries = 3;
        
        // Retry mechanism for each individual item
        while (!itemCreated && retryCount < maxRetries) {
          try {
            print('ExpenseProvider: Creating expense $currentIndex/${expenses.length} (attempt ${retryCount + 1})');
            
            final newExpense = await _expenseService.createExpense(expense);
            createdExpenses.add(newExpense);
            successCount++;
            itemCreated = true;
            
            print('ExpenseProvider: Successfully created expense with ID ${newExpense.id}');
            
            // Update progress callback if provided
            if (onProgress != null) {
              onProgress(currentIndex, expenses.length);
            }
            
            // Add the newly created expense to the list immediately for real-time feedback
            _expenses.insert(0, newExpense);
            notifyListeners();
            
          } catch (e) {
            retryCount++;
            String errorMessage = e.toString();
            
            if (retryCount < maxRetries) {
              print('ExpenseProvider: Attempt $retryCount failed for expense $currentIndex, retrying... Error: $errorMessage');
              // Wait a bit before retrying
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
            } else {
              failCount++;
              failedReasons.add('Item $currentIndex: $errorMessage');
              print('ExpenseProvider: Failed to create expense $currentIndex after $maxRetries attempts - $errorMessage');
              
              // Update progress callback even for failed items
              if (onProgress != null) {
                onProgress(currentIndex, expenses.length);
              }
            }
          }
        }
      }

      print('ExpenseProvider: Bulk creation completed - Success: $successCount, Failed: $failCount');
      
      return {
        'success': successCount,
        'failed': failCount,
        'total': expenses.length,
        'createdExpenses': createdExpenses,
        'failedReasons': failedReasons,
      };
    } catch (e) {
      _setError(e.toString());
      print('ExpenseProvider: Critical error in bulk create expenses - $e');
      return {
        'success': successCount,
        'failed': failCount,
        'total': expenses.length,
        'createdExpenses': createdExpenses,
        'failedReasons': failedReasons,
        'criticalError': e.toString(),
      };
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // Update expense
  Future<bool> updateExpense(int id, Expense expense) async {
    _isUpdating = true;
    _setError(null);
    notifyListeners();

    try {
      await _setAuthToken();
      
      final updatedExpense = await _expenseService.updateExpense(id, expense);
      
      final index = _expenses.indexWhere((e) => e.id == id);
      if (index != -1) {
        _expenses[index] = updatedExpense;
      }
      
      print('ExpenseProvider: Updated expense with ID $id');
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      print('ExpenseProvider: Error updating expense - $e');
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // Delete expense
  Future<bool> deleteExpense(int id) async {
    _setLoading(true);
    _setError(null);

    try {
      await _setAuthToken();
      
      final success = await _expenseService.deleteExpense(id);
      if (success) {
        _expenses.removeWhere((e) => e.id == id);
        _selectedExpenseIds.remove(id);
        
        print('ExpenseProvider: Deleted expense with ID $id');
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      print('ExpenseProvider: Error deleting expense - $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Approve expense
  Future<bool> approveExpense(int id) async {
    _setLoading(true);
    _setError(null);

    try {
      await _setAuthToken();
      
      final approvedExpense = await _expenseService.approveExpense(id);
      
      final index = _expenses.indexWhere((e) => e.id == id);
      if (index != -1) {
        _expenses[index] = approvedExpense;
      }
      
      print('ExpenseProvider: Approved expense with ID $id');
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      print('ExpenseProvider: Error approving expense - $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Bulk delete selected expenses
  Future<bool> bulkDeleteSelectedExpenses() async {
    if (_selectedExpenseIds.isEmpty) return false;

    _setLoading(true);
    _setError(null);

    try {
      await _setAuthToken();
      
      final success = await _expenseService.bulkDeleteExpenses(_selectedExpenseIds.toList());
      if (success) {
        _expenses.removeWhere((e) => _selectedExpenseIds.contains(e.id));
        _selectedExpenseIds.clear();
        
        print('ExpenseProvider: Bulk deleted expenses');
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      print('ExpenseProvider: Error bulk deleting expenses - $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load expense statistics
  Future<void> loadStatistics() async {
    try {
      await _setAuthToken();
      
      _statistics = await _expenseService.getExpenseStatistics(
        startDate: _startDate,
        endDate: _endDate,
      );
      
      print('ExpenseProvider: Loaded expense statistics');
      notifyListeners();
    } catch (e) {
      print('ExpenseProvider: Error loading statistics - $e');
    }
  }

  // Search expenses
  void searchExpenses(String query) {
    _searchQuery = query;
    loadExpenses(refresh: true);
  }

  // Set date filter
  void setDateFilter(String? startDate, String? endDate) {
    _startDate = startDate;
    _endDate = endDate;
    loadExpenses(refresh: true);
    loadStatistics();
  }

  // Set category filter
  void setCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    loadExpenses(refresh: true);
  }

  // Set warehouse filter
  void setWarehouseFilter(int? warehouseId) {
    _selectedWarehouseId = warehouseId;
    loadExpenses(refresh: true);
  }

  // Set payment method filter
  void setPaymentMethodFilter(String? paymentMethod) {
    _selectedPaymentMethod = paymentMethod;
    loadExpenses(refresh: true);
  }

  // Set approval status filter
  void setApprovalFilter(bool? isApproved) {
    _isApprovedFilter = isApproved;
    loadExpenses(refresh: true);
  }

  // Set amount range filter
  void setAmountRangeFilter(double? minAmount, double? maxAmount) {
    _minAmount = minAmount;
    _maxAmount = maxAmount;
    loadExpenses(refresh: true);
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _startDate = null;
    _endDate = null;
    _selectedCategoryId = null;
    _selectedWarehouseId = null;
    _selectedPaymentMethod = null;
    _isApprovedFilter = null;
    _minAmount = null;
    _maxAmount = null;
    loadExpenses(refresh: true);
    loadStatistics();
  }

  // Selection methods
  void toggleExpenseSelection(int expenseId) {
    if (_selectedExpenseIds.contains(expenseId)) {
      _selectedExpenseIds.remove(expenseId);
    } else {
      _selectedExpenseIds.add(expenseId);
    }
    notifyListeners();
  }

  void selectAllExpenses() {
    _selectedExpenseIds = _expenses.map((e) => e.id).toSet();
    notifyListeners();
  }

  void clearSelection() {
    _selectedExpenseIds.clear();
    notifyListeners();
  }

  bool isExpenseSelected(int expenseId) {
    return _selectedExpenseIds.contains(expenseId);
  }

  // Get expense by ID
  Expense? getExpenseById(int id) {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get payment methods
  List<Map<String, String>> getPaymentMethods() {
    return _expenseService.getPaymentMethods();
  }

  // Get recurring frequencies
  List<Map<String, String>> getRecurringFrequencies() {
    return _expenseService.getRecurringFrequencies();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadExpenses(refresh: true);
    await loadStatistics();
  }
}