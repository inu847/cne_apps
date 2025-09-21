import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../models/product_model.dart';
import '../config/api_config.dart';
import 'product_form_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  bool _isFilterExpanded = false;
  bool _isSelectionMode = false;
  bool _isLoadingMore = false;
  Set<String> _selectedItems = {};
  String _quickFilter = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).initProducts();
      Provider.of<CategoryProvider>(context, listen: false).getCategoriesForDropdown();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading && !_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });
        provider.loadMore().then((_) {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  void _applyFilters() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    provider.setFilters(
      search: _searchQuery,
      status: _quickFilter == 'all' ? null : _quickFilter,
    );
    provider.fetchProducts();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _quickFilter = 'all';
      _isFilterExpanded = false;
    });
    _searchController.clear();
    _applyFilters();
  }

  void _performSearch() {
    _applyFilters();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedItems.clear();
    });
  }

  void _toggleItemSelection(String productId) {
    setState(() {
      if (_selectedItems.contains(productId)) {
        _selectedItems.remove(productId);
      } else {
        _selectedItems.add(productId);
      }
    });
  }

  void _selectAllItems() {
    setState(() {
      _selectedItems.addAll(
        Provider.of<ProductProvider>(context, listen: false)
            .products
            .map((product) => product.id.toString()),
      );
    });
  }

  void _bulkDelete() async {
    if (_selectedItems.isEmpty) return;

    final confirmed = await _showDeleteDialog(
      title: 'Hapus ${_selectedItems.length} Produk',
      content: 'Apakah Anda yakin ingin menghapus ${_selectedItems.length} produk yang dipilih?',
    );

    if (confirmed == true) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      
      for (String productId in _selectedItems) {
        await provider.deleteProduct(int.parse(productId));
      }
      
      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildQuickFilterChip(String value, String label, IconData icon) {
    final isSelected = _quickFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? ApiConfig.backgroundColor : ApiConfig.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? ApiConfig.backgroundColor : ApiConfig.primaryColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      selectedColor: ApiConfig.primaryColor,
      backgroundColor: ApiConfig.backgroundColor,
      onSelected: (selected) {
        _applyQuickFilter(value);
      },
    );
  }

  void _applyQuickFilter(String filter) {
    setState(() {
      _quickFilter = filter;
    });
    _applyFilters();
  }

  Widget _buildProductItem(Product product) {
    final isSelected = _selectedItems.contains(product.id);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ApiConfig.backgroundColor,
            ApiConfig.backgroundColor.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ApiConfig.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
        border: isSelected
            ? Border.all(color: ApiConfig.primaryColor, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSelectionMode
              ? () => _toggleItemSelection(product.id.toString())
              : () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductFormScreen(product: product),
                    ),
                  );
                  if (result == true) {
                    Provider.of<ProductProvider>(context, listen: false).fetchProducts();
                  }
                },
          onLongPress: () {
            if (!_isSelectionMode) {
              _toggleSelectionMode();
              _toggleItemSelection(product.id.toString());
            }
          },
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              children: [
                if (_isSelectionMode)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? ApiConfig.primaryColor : Colors.grey,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                
                // Product Icon
                Container(
                  width: isMobile ? 48 : 56,
                  height: isMobile ? 48 : 56,
                  decoration: BoxDecoration(
                    color: ApiConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    product.icon,
                    color: ApiConfig.primaryColor,
                    size: isMobile ? 24 : 28,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: ApiConfig.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: ApiConfig.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: isMobile ? 14 : 16,
                            color: ApiConfig.textColor.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stok: ${product.stock}',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: ApiConfig.textColor.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: product.stock > 0 
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.stock > 0 ? 'Tersedia' : 'Habis',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 12,
                                color: product.stock > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                if (!_isSelectionMode)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: ApiConfig.textColor.withOpacity(0.6),
                      size: isMobile ? 20 : 24,
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductFormScreen(product: product),
                            ),
                          );
                          if (result == true) {
                            Provider.of<ProductProvider>(context, listen: false).fetchProducts();
                          }
                          break;
                        case 'delete':
                          final confirmed = await _showDeleteDialog(
                            title: 'Hapus Produk',
                            content: 'Apakah Anda yakin ingin menghapus produk "${product.name}"?',
                          );
                          if (confirmed == true) {
                            final provider = Provider.of<ProductProvider>(context, listen: false);
                            await provider.deleteProduct(product.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Produk berhasil dihapus'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog({
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dompet Kasir - POS | Manajemen Produk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ApiConfig.backgroundColor,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: ApiConfig.primaryColor,
        foregroundColor: ApiConfig.backgroundColor,
        elevation: 4,
        shadowColor: ApiConfig.primaryColor.withOpacity(0.3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(
                _selectedItems.length == Provider.of<ProductProvider>(context).products.length
                    ? Icons.deselect
                    : Icons.select_all,
                color: ApiConfig.backgroundColor,
              ),
              onPressed: () {
                if (_selectedItems.length == Provider.of<ProductProvider>(context, listen: false).products.length) {
                  setState(() {
                    _selectedItems.clear();
                  });
                } else {
                  _selectAllItems();
                }
              },
              tooltip: 'Select All',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: ApiConfig.backgroundColor),
              onPressed: _selectedItems.isNotEmpty ? _bulkDelete : null,
              tooltip: 'Delete Selected',
            ),
            IconButton(
              icon: Icon(Icons.close, color: ApiConfig.backgroundColor),
              onPressed: _toggleSelectionMode,
              tooltip: 'Cancel Selection',
            ),
          ] else ...[
            IconButton(
              icon: Icon(
                Icons.checklist,
                color: ApiConfig.backgroundColor,
              ),
              onPressed: _toggleSelectionMode,
              tooltip: 'Bulk Actions',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                Provider.of<ProductProvider>(context, listen: false).fetchProducts();
              },
              tooltip: 'Refresh Data',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ApiConfig.backgroundColor,
                  ApiConfig.backgroundColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ApiConfig.primaryColor.withOpacity(0.1),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari nama produk...',
                      hintStyle: TextStyle(
                        color: ApiConfig.textColor.withOpacity(0.6),
                        fontSize: isMobile ? 14 : 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: ApiConfig.primaryColor,
                        size: isMobile ? 20 : 24,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: ApiConfig.textColor.withOpacity(0.6),
                                size: isMobile ? 18 : 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                _performSearch();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12 : 16,
                        horizontal: 16,
                      ),
                    ),
                    style: TextStyle(
                      color: ApiConfig.textColor,
                      fontSize: isMobile ? 14 : 16,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _performSearch();
                    },
                    onSubmitted: (value) {
                      _performSearch();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _isFilterExpanded ? ApiConfig.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: ApiConfig.primaryColor.withOpacity(0.2),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                      color: _isFilterExpanded ? ApiConfig.backgroundColor : ApiConfig.primaryColor,
                      size: isMobile ? 20 : 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFilterExpanded = !_isFilterExpanded;
                      });
                    },
                    tooltip: 'Filter',
                  ),
                ),
              ],
            ),
          ),
          
          // Quick filters
          if (!_isSelectionMode)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildQuickFilterChip('all', 'Semua', Icons.list_alt),
                  const SizedBox(width: 8),
                  _buildQuickFilterChip('available', 'Tersedia', Icons.check_circle),
                  const SizedBox(width: 8),
                  _buildQuickFilterChip('out_of_stock', 'Habis', Icons.cancel),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Content
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.products.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (provider.error != null && provider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.fetchProducts(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (provider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: ApiConfig.textColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada produk',
                          style: TextStyle(
                            fontSize: 18,
                            color: ApiConfig.textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan produk pertama Anda',
                          style: TextStyle(
                            color: ApiConfig.textColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () => provider.fetchProducts(),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: provider.products.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.products.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      return _buildProductItem(provider.products[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductFormScreen(),
            ),
          );
          if (result == true) {
            Provider.of<ProductProvider>(context, listen: false).fetchProducts();
          }
        },
        backgroundColor: ApiConfig.primaryColor,
        foregroundColor: ApiConfig.backgroundColor,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }
}