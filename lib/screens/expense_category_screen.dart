import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cne_pos_apps/models/expense_category_model.dart';
import 'package:cne_pos_apps/providers/expense_category_provider.dart';
import 'package:cne_pos_apps/screens/expense_category_form_screen.dart';
import '../config/api_config.dart';

class ExpenseCategoryScreen extends StatefulWidget {
  const ExpenseCategoryScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseCategoryScreen> createState() => _ExpenseCategoryScreenState();
}

class _ExpenseCategoryScreenState extends State<ExpenseCategoryScreen> {
  // State untuk search dan bulk operations
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<int> _selectedItems = [];
  bool _isSelectionMode = false;
  
  // State untuk filter
  bool _isFilterExpanded = false;
  bool? _isActiveFilter;
  
  // State untuk quick filters
  String _quickFilter = 'all'; // all, active, inactive
  
  // Scroll controller untuk infinite scroll
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  
  // Debounce timer untuk search
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    // Fetch data saat screen pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseCategoryProvider>(context, listen: false).fetchExpenseCategories();
    });
    
    // Tambahkan listener untuk infinite scroll
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  // Listener untuk infinite scroll
  void _scrollListener() async {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      final provider = Provider.of<ExpenseCategoryProvider>(context, listen: false);
      
      // Periksa apakah masih ada halaman berikutnya
      if (provider.pagination != null && 
          provider.currentPage < provider.pagination!.lastPage) {
        setState(() {
          _isLoadingMore = true;
        });
        
        // Muat halaman berikutnya
        await provider.loadMoreExpenseCategories();
        
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }
  
  // Fungsi untuk menerapkan filter
  void _applyFilters() {
    final provider = Provider.of<ExpenseCategoryProvider>(context, listen: false);
    provider.setFilters(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      isActive: _isActiveFilter,
    );
    provider.fetchExpenseCategories();
  }
  
  // Fungsi untuk mereset filter
  void _resetFilters() {
    setState(() {
      _isActiveFilter = null;
      _searchController.clear();
      _searchQuery = '';
      _quickFilter = 'all';
    });
    
    final provider = Provider.of<ExpenseCategoryProvider>(context, listen: false);
    provider.resetFilters();
    provider.fetchExpenseCategories();
  }
  
  // Fungsi untuk melakukan pencarian
  void _performSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final provider = Provider.of<ExpenseCategoryProvider>(context, listen: false);
      provider.setFilters(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        isActive: _isActiveFilter,
      );
      provider.fetchExpenseCategories();
    });
  }
  
  // Fungsi untuk toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItems.clear();
      }
    });
  }
  
  // Fungsi untuk select/deselect item
  void _toggleItemSelection(int categoryId) {
    setState(() {
      if (_selectedItems.contains(categoryId)) {
        _selectedItems.remove(categoryId);
      } else {
        _selectedItems.add(categoryId);
      }
    });
  }
  
  // Fungsi untuk select all items
  void _selectAllItems() {
    final provider = Provider.of<ExpenseCategoryProvider>(context, listen: false);
    setState(() {
      _selectedItems = provider.expenseCategories.map((category) => category.id).toList();
    });
  }
  
  // Fungsi untuk bulk delete
  void _bulkDelete() {
    if (_selectedItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori Pengeluaran Terpilih'),
        content: Text('Apakah Anda yakin ingin menghapus ${_selectedItems.length} kategori pengeluaran?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<ExpenseCategoryProvider>(context, listen: false);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Delete selected categories
              bool allSuccess = true;
              for (int categoryId in _selectedItems) {
                final success = await provider.deleteExpenseCategory(categoryId);
                if (!success) {
                  allSuccess = false;
                  break;
                }
              }
              
              Navigator.pop(context); // Close loading dialog
              
              if (allSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kategori pengeluaran berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
                _toggleSelectionMode();
                provider.fetchExpenseCategories();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus beberapa kategori pengeluaran'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: _isSelectionMode 
          ? Text('${_selectedItems.length} dipilih')
          : const Text('Kategori Pengeluaran'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAllItems,
              tooltip: 'Pilih Semua',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedItems.isNotEmpty ? _bulkDelete : null,
              tooltip: 'Hapus Terpilih',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
              tooltip: 'Batal',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: 'Mode Pilih',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                Provider.of<ExpenseCategoryProvider>(context, listen: false).refreshExpenseCategories();
              },
              tooltip: 'Refresh',
            ),
          ],
        ],
      ),
      body: Consumer<ExpenseCategoryProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search dan Filter Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari kategori pengeluaran...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
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
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        _performSearch();
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Quick Filters
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildQuickFilterChip('all', 'Semua', null),
                                const SizedBox(width: 8),
                                _buildQuickFilterChip('active', 'Aktif', true),
                                const SizedBox(width: 8),
                                _buildQuickFilterChip('inactive', 'Tidak Aktif', false),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isFilterExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _isFilterExpanded = !_isFilterExpanded;
                            });
                          },
                          tooltip: 'Filter Lanjutan',
                        ),
                      ],
                    ),
                    
                    // Advanced Filters (Expandable)
                    if (_isFilterExpanded) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filter Lanjutan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<bool?>(
                                    value: _isActiveFilter,
                                    decoration: const InputDecoration(
                                      labelText: 'Status',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: null, child: Text('Semua Status')),
                                      DropdownMenuItem(value: true, child: Text('Aktif')),
                                      DropdownMenuItem(value: false, child: Text('Tidak Aktif')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _isActiveFilter = value;
                                        _quickFilter = value == null ? 'all' : (value ? 'active' : 'inactive');
                                      });
                                      _applyFilters();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _resetFilters,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[600],
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Reset'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Content Section
              Expanded(
                child: _buildContent(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExpenseCategoryFormScreen(),
            ),
          ).then((_) {
            // Refresh data setelah kembali dari form
            Provider.of<ExpenseCategoryProvider>(context, listen: false).refreshExpenseCategories();
          });
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickFilterChip(String key, String label, bool? isActive) {
    final isSelected = _quickFilter == key;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _quickFilter = key;
            _isActiveFilter = isActive;
          });
          _applyFilters();
        }
      },
      selectedColor: Colors.green.withOpacity(0.2),
      checkmarkColor: Colors.green,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildContent(ExpenseCategoryProvider provider) {
    if (provider.isLoading && provider.expenseCategories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      );
    }

    if (provider.error != null && provider.expenseCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.refreshExpenseCategories();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (provider.expenseCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Kategori Pengeluaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan kategori pengeluaran pertama Anda',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExpenseCategoryFormScreen(),
                  ),
                ).then((_) {
                  provider.refreshExpenseCategories();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kategori'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await provider.refreshExpenseCategories();
      },
      color: Colors.green,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: provider.expenseCategories.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.expenseCategories.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            );
          }

          final category = provider.expenseCategories[index];
          final isSelected = _selectedItems.contains(category.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isSelected 
                ? const BorderSide(color: Colors.green, width: 2)
                : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _isSelectionMode
                ? () => _toggleItemSelection(category.id)
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExpenseCategoryFormScreen(category: category),
                      ),
                    ).then((_) {
                      provider.refreshExpenseCategories();
                    });
                  },
              onLongPress: !_isSelectionMode
                ? () {
                    _toggleSelectionMode();
                    _toggleItemSelection(category.id);
                  }
                : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_isSelectionMode)
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.green : Colors.grey,
                        ),
                      ),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: category.isActive ? Colors.green : Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  category.isActive ? 'Aktif' : 'Tidak Aktif',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          Text(
                            'Kode: ${category.code}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          if (category.description != null && category.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              category.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${category.expensesCount ?? 0} pengeluaran',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.attach_money,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Total: ${category.totalExpenses ?? "Rp 0"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    if (!_isSelectionMode)
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          switch (value) {
                            case 'edit':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExpenseCategoryFormScreen(category: category),
                                ),
                              ).then((_) {
                                provider.refreshExpenseCategories();
                              });
                              break;
                            case 'delete':
                              _showDeleteDialog(category, provider);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Hapus'),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(ExpenseCategory category, ExpenseCategoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori Pengeluaran'),
        content: Text('Apakah Anda yakin ingin menghapus kategori "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await provider.deleteExpenseCategory(category.id);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kategori pengeluaran berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Gagal menghapus kategori pengeluaran'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}