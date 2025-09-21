import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../services/auth_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  final AuthService _authService = AuthService();
  
  List<Category> _categories = [];
  Category? _selectedCategory;
  Pagination? _pagination;
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
  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  Pagination? get pagination => _pagination;
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
  int get totalCategories => _pagination?.total ?? 0;

  // Initialize categories
  Future<void> initCategories() async {
    await fetchCategories();
  }

  // Current filters
  String? _currentSearch;
  bool? _currentIsActive;
  
  // Method untuk set filters
  void setFilters({String? search, bool? isActive}) {
    _currentSearch = search;
    _currentIsActive = isActive;
  }

  // Fetch categories from API
  Future<void> fetchCategories({
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
        // Set token to CategoryService
        _categoryService.setToken(token);
        
        // Get categories from API
        final response = await _categoryService.getCategories(
          search: search ?? _currentSearch ?? (_searchQuery.isEmpty ? null : _searchQuery),
          isActive: isActive ?? _currentIsActive ?? _isActiveFilter,
          page: _currentPage,
          perPage: _perPage,
        );
        
        if (page == 1 || _currentPage == 1) {
          _categories = response.categories;
        } else {
          _categories.addAll(response.categories);
        }
        _pagination = response.pagination;
        _error = null;
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
      }
    } catch (e) {
      _error = 'Gagal memuat kategori: ${e.toString()}';
      print('CategoryProvider: Error fetching categories - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Method untuk load more categories (infinite scroll)
  Future<void> loadMoreCategories() async {
    if (_pagination != null && _currentPage < _pagination!.lastPage) {
      await fetchCategories(page: _currentPage + 1);
    }
  }

  // Search categories
  Future<void> searchCategories(String query) async {
    _searchQuery = query;
    _currentPage = 1; // Reset to first page when searching
    await fetchCategories();
  }

  // Filter categories by active status
  Future<void> filterByActiveStatus(bool? isActive) async {
    _isActiveFilter = isActive;
    _currentPage = 1; // Reset to first page when filtering
    await fetchCategories();
  }

  // Load next page
  Future<void> loadNextPage() async {
    if (hasNextPage && !_isLoading) {
      await fetchCategories(page: _currentPage + 1);
    }
  }

  // Load previous page
  Future<void> loadPreviousPage() async {
    if (hasPreviousPage && !_isLoading) {
      await fetchCategories(page: _currentPage - 1);
    }
  }

  // Go to specific page
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= (_pagination?.lastPage ?? 1) && !_isLoading) {
      await fetchCategories(page: page);
    }
  }

  // Get category by ID
  Future<void> getCategoryById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _categoryService.setToken(token);
        
        final category = await _categoryService.getCategoryById(id);
        _selectedCategory = category;
        _error = null;
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
      }
    } catch (e) {
      _error = 'Gagal memuat detail kategori: ${e.toString()}';
      print('CategoryProvider: Error getting category by ID - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new category
  Future<bool> createCategory(Category category) async {
    _isCreating = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _categoryService.setToken(token);
        
        final createdCategory = await _categoryService.createCategory(category);
        
        // Add to local list if we're on the first page
        if (_currentPage == 1) {
          _categories.insert(0, createdCategory);
          // Update pagination total
          if (_pagination != null) {
            _pagination = Pagination(
              total: _pagination!.total + 1,
              perPage: _pagination!.perPage,
              currentPage: _pagination!.currentPage,
              lastPage: _pagination!.lastPage,
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
      _error = 'Gagal membuat kategori: ${e.toString()}';
      print('CategoryProvider: Error creating category - $e');
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // Update category
  Future<bool> updateCategory(int id, Category category) async {
    _isUpdating = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _categoryService.setToken(token);
        
        final updatedCategory = await _categoryService.updateCategory(id, category);
        
        // Update in local list
        final index = _categories.indexWhere((cat) => cat.id == id);
        if (index != -1) {
          _categories[index] = updatedCategory;
        }
        
        // Update selected category if it's the same
        if (_selectedCategory?.id == id) {
          _selectedCategory = updatedCategory;
        }
        
        _error = null;
        return true;
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
        return false;
      }
    } catch (e) {
      _error = 'Gagal mengupdate kategori: ${e.toString()}';
      print('CategoryProvider: Error updating category - $e');
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // Delete category
  Future<bool> deleteCategory(int id) async {
    _isDeleting = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _categoryService.setToken(token);
        
        final success = await _categoryService.deleteCategory(id);
        
        if (success) {
          // Remove from local list
          _categories.removeWhere((cat) => cat.id == id);
          
          // Clear selected category if it's the deleted one
          if (_selectedCategory?.id == id) {
            _selectedCategory = null;
          }
          
          // Update pagination total
          if (_pagination != null) {
            _pagination = Pagination(
              total: _pagination!.total - 1,
              perPage: _pagination!.perPage,
              currentPage: _pagination!.currentPage,
              lastPage: _pagination!.lastPage,
            );
          }
          
          _error = null;
          return true;
        } else {
          _error = 'Gagal menghapus kategori';
          return false;
        }
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
        return false;
      }
    } catch (e) {
      _error = 'Gagal menghapus kategori: ${e.toString()}';
      print('CategoryProvider: Error deleting category - $e');
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

  // Clear selected category
  void clearSelectedCategory() {
    _selectedCategory = null;
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

  // Refresh categories (reload current page)
  Future<void> refreshCategories() async {
    await fetchCategories(refresh: true);
  }

  // Get categories for dropdown (simple list without pagination)
  Future<List<Category>> getCategoriesForDropdown() async {
    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _categoryService.setToken(token);
        
        // Get all active categories for dropdown
        final response = await _categoryService.getCategories(
          isActive: true,
          page: 1,
          perPage: 100, // Get more items for dropdown
        );
        
        return response.categories;
      } else {
        throw Exception('Token tidak ditemukan');
      }
    } catch (e) {
      print('CategoryProvider: Error getting categories for dropdown - $e');
      return [];
    }
  }
}