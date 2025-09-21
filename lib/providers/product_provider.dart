import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  
  List<Product> _products = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _isUpdatingStock = false;
  String? _error;
  
  // Search and filter state
  String _searchQuery = '';
  int? _categoryIdFilter;
  bool? _isActiveFilter;
  bool? _hasStockFilter;
  int _currentPage = 1;
  int _perPage = 15;
  int _totalProducts = 0;
  int _totalPages = 1;

  // Getters
  List<Product> get products => _products;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  bool get isUpdatingStock => _isUpdatingStock;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int? get categoryIdFilter => _categoryIdFilter;
  bool? get isActiveFilter => _isActiveFilter;
  bool? get hasStockFilter => _hasStockFilter;
  int get currentPage => _currentPage;
  int get perPage => _perPage;
  int get totalProducts => _totalProducts;
  int get totalPages => _totalPages;
  
  // Computed getters
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;
  bool get hasMore => hasNextPage;

  // Initialize products
  Future<void> initProducts() async {
    await fetchProducts();
  }

  // Current filters
  String? _currentSearch;
  int? _currentCategoryId;
  bool? _currentIsActive;
  bool? _currentHasStock;
  
  // Method untuk set filters
  void setFilters({
    String? search,
    String? status,
    int? categoryId,
    bool? isActive,
    bool? hasStock,
  }) {
    _currentSearch = search;
    _currentCategoryId = categoryId;
    _currentIsActive = isActive;
    _currentHasStock = hasStock;
    
    // Handle status filter
    if (status != null) {
      switch (status) {
        case 'available':
          _currentHasStock = true;
          _currentIsActive = null;
          break;
        case 'out_of_stock':
          _currentHasStock = false;
          _currentIsActive = null;
          break;
        default:
          _currentHasStock = null;
          _currentIsActive = null;
      }
    }
  }

  // Fetch products from API
  Future<void> fetchProducts({
    String? search,
    int? categoryId,
    bool? isActive,
    bool? hasStock,
    int? page,
    int? perPage,
    bool refresh = false,
  }) async {
    _isLoading = true;
    _error = null;
    
    // Update search and filter state if provided
    if (search != null) _searchQuery = search;
    if (categoryId != null) _categoryIdFilter = categoryId;
    if (isActive != null) _isActiveFilter = isActive;
    if (hasStock != null) _hasStockFilter = hasStock;
    if (page != null) _currentPage = page;
    if (perPage != null) _perPage = perPage;
    
    notifyListeners();

    try {
      // Get token from AuthService
      final token = await _authService.getToken();
      
      if (token != null) {
        // Set token to ProductService
        _productService.setToken(token);
        
        // Get products from API
        final products = await _productService.getProducts(
          search: search ?? _currentSearch ?? (_searchQuery.isEmpty ? null : _searchQuery),
          categoryId: categoryId ?? _currentCategoryId ?? _categoryIdFilter,
          isActive: isActive ?? _currentIsActive ?? _isActiveFilter,
          hasStock: hasStock ?? _currentHasStock ?? _hasStockFilter,
          page: _currentPage,
          perPage: _perPage,
        );
        
        if (page == 1 || _currentPage == 1) {
          _products = products;
        } else {
          _products.addAll(products);
        }
        
        // Calculate pagination info (since API doesn't return pagination object)
        _totalProducts = products.length;
        _totalPages = (_totalProducts / _perPage).ceil();
        
        _error = null;
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
      }
    } catch (e) {
      _error = 'Gagal memuat produk: ${e.toString()}';
      print('ProductProvider: Error fetching products - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Method untuk load more products (infinite scroll)
  Future<void> loadMoreProducts() async {
    if (hasNextPage && !_isLoading) {
      await fetchProducts(page: _currentPage + 1);
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    _searchQuery = query;
    _currentPage = 1; // Reset to first page when searching
    await fetchProducts();
  }

  // Filter products by category
  Future<void> filterByCategory(int? categoryId) async {
    _categoryIdFilter = categoryId;
    _currentPage = 1; // Reset to first page when filtering
    await fetchProducts();
  }

  // Filter products by active status
  Future<void> filterByActiveStatus(bool? isActive) async {
    _isActiveFilter = isActive;
    _currentPage = 1; // Reset to first page when filtering
    await fetchProducts();
  }

  // Filter products by stock availability
  Future<void> filterByStockAvailability(bool? hasStock) async {
    _hasStockFilter = hasStock;
    _currentPage = 1; // Reset to first page when filtering
    await fetchProducts();
  }

  // Load next page
  Future<void> loadNextPage() async {
    if (hasNextPage && !_isLoading) {
      await fetchProducts(page: _currentPage + 1);
    }
  }

  // Load previous page
  Future<void> loadPreviousPage() async {
    if (hasPreviousPage && !_isLoading) {
      await fetchProducts(page: _currentPage - 1);
    }
  }

  // Go to specific page
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _totalPages && !_isLoading) {
      await fetchProducts(page: page);
    }
  }

  // Get product by ID
  Future<void> getProductById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _productService.setToken(token);
        
        final product = await _productService.getProductById(id);
        _selectedProduct = product;
        _error = null;
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
      }
    } catch (e) {
      _error = 'Gagal memuat detail produk: ${e.toString()}';
      print('ProductProvider: Error getting product by ID - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new product
  Future<bool> createProduct({
    required String name,
    String? sku,
    String? barcode,
    String? description,
    required int price,
    int? cost,
    required int stock,
    required int categoryId,
    bool isActive = true,
    bool hasVariations = false,
    List<Map<String, dynamic>>? variations,
  }) async {
    _isCreating = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _productService.setToken(token);
        
        final createdProduct = await _productService.createProduct(
          name: name,
          sku: sku,
          barcode: barcode,
          description: description,
          price: price,
          cost: cost,
          stock: stock,
          categoryId: categoryId,
          isActive: isActive,
          hasVariations: hasVariations,
          variations: variations,
        );
        
        // Add to local list if we're on the first page
        if (_currentPage == 1) {
          _products.insert(0, createdProduct);
          _totalProducts++;
        }
        
        _error = null;
        return true;
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
        return false;
      }
    } catch (e) {
      _error = 'Gagal membuat produk: ${e.toString()}';
      print('ProductProvider: Error creating product - $e');
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // Update product
  Future<bool> updateProduct({
    required int id,
    required String name,
    String? sku,
    String? barcode,
    String? description,
    required int price,
    int? cost,
    required int stock,
    required int categoryId,
    bool isActive = true,
    bool hasVariations = false,
    List<Map<String, dynamic>>? variations,
  }) async {
    _isUpdating = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _productService.setToken(token);
        
        final updatedProduct = await _productService.updateProduct(
          id: id,
          name: name,
          sku: sku,
          barcode: barcode,
          description: description,
          price: price,
          cost: cost,
          stock: stock,
          categoryId: categoryId,
          isActive: isActive,
          hasVariations: hasVariations,
          variations: variations,
        );
        
        // Update in local list
        final index = _products.indexWhere((product) => product.id == id);
        if (index != -1) {
          _products[index] = updatedProduct;
        }
        
        // Update selected product if it's the same
        if (_selectedProduct?.id == id) {
          _selectedProduct = updatedProduct;
        }
        
        _error = null;
        return true;
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
        return false;
      }
    } catch (e) {
      _error = 'Gagal mengupdate produk: ${e.toString()}';
      print('ProductProvider: Error updating product - $e');
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // Delete product
  Future<bool> deleteProduct(int id) async {
    _isDeleting = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _productService.setToken(token);
        
        final success = await _productService.deleteProduct(id);
        
        if (success) {
          // Remove from local list
          _products.removeWhere((product) => product.id == id);
          
          // Clear selected product if it's the deleted one
          if (_selectedProduct?.id == id) {
            _selectedProduct = null;
          }
          
          _totalProducts--;
          
          _error = null;
          return true;
        } else {
          _error = 'Gagal menghapus produk';
          return false;
        }
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
        return false;
      }
    } catch (e) {
      _error = 'Gagal menghapus produk: ${e.toString()}';
      print('ProductProvider: Error deleting product - $e');
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // Update product stock
  Future<bool> updateProductStock({
    required int id,
    required int stock,
    String? reason,
  }) async {
    _isUpdatingStock = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _productService.setToken(token);
        
        final updatedProduct = await _productService.updateStock(
          id: id,
          stock: stock,
          reason: reason,
        );
        
        // Update in local list
        final index = _products.indexWhere((product) => product.id == id);
        if (index != -1) {
          _products[index] = updatedProduct;
        }
        
        // Update selected product if it's the same
        if (_selectedProduct?.id == id) {
          _selectedProduct = updatedProduct;
        }
        
        _error = null;
        return true;
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
        return false;
      }
    } catch (e) {
      _error = 'Gagal mengupdate stok: ${e.toString()}';
      print('ProductProvider: Error updating stock - $e');
      return false;
    } finally {
      _isUpdatingStock = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear selected product
  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  // Reset search and filters
  void resetFilters() {
    _searchQuery = '';
    _categoryIdFilter = null;
    _isActiveFilter = null;
    _hasStockFilter = null;
    _currentPage = 1;
    _currentSearch = null;
    _currentCategoryId = null;
    _currentIsActive = null;
    _currentHasStock = null;
    notifyListeners();
  }

  // Refresh products (reload current page)
  Future<void> refreshProducts() async {
    await fetchProducts(refresh: true);
  }

  // Get products for dropdown (simple list without pagination)
  Future<List<Product>> getProductsForDropdown({int? categoryId}) async {
    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _productService.setToken(token);
        
        // Get all active products for dropdown
        final products = await _productService.getProducts(
          categoryId: categoryId,
          isActive: true,
          page: 1,
          perPage: 100, // Get more items for dropdown
        );
        
        return products;
      } else {
        throw Exception('Token tidak ditemukan');
      }
    } catch (e) {
      print('ProductProvider: Error getting products for dropdown - $e');
      return [];
    }
  }

  // Get products for dropdown from current list
  List<Product> getProductsForDropdownFromList() {
    return _products.where((product) => product.stock > 0).toList();
  }

  // Load more products (pagination)
  Future<void> loadMore() async {
    if (_isLoading || !hasNextPage) return;

    _isLoading = true;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        _productService.setToken(token);
        
        final newProducts = await _productService.getProducts(
          search: _searchQuery.isEmpty ? null : _searchQuery,
          categoryId: _categoryIdFilter,
          isActive: _isActiveFilter,
          hasStock: _hasStockFilter,
          page: _currentPage + 1,
          perPage: _perPage,
        );

        if (newProducts.isNotEmpty) {
          _products.addAll(newProducts);
          _currentPage++;
        }
      }

      _error = null;
    } catch (e) {
      _error = 'Gagal memuat lebih banyak produk: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}