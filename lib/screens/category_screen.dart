import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cne_pos_apps/models/category_model.dart';
import 'package:cne_pos_apps/providers/category_provider.dart';
import 'package:cne_pos_apps/screens/category_form_screen.dart';
import '../config/api_config.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
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
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
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
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      
      // Periksa apakah masih ada halaman berikutnya
      if (provider.pagination != null && 
          provider.currentPage < provider.pagination!.lastPage) {
        setState(() {
          _isLoadingMore = true;
        });
        
        // Muat halaman berikutnya
        await provider.loadMoreCategories();
        
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }
  
  // Fungsi untuk menerapkan filter
  void _applyFilters() {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    provider.setFilters(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      isActive: _isActiveFilter,
    );
    provider.fetchCategories();
  }
  
  // Fungsi untuk mereset filter
  void _resetFilters() {
    setState(() {
      _isActiveFilter = null;
      _searchController.clear();
      _searchQuery = '';
      _quickFilter = 'all';
    });
    
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    provider.resetFilters();
    provider.fetchCategories();
  }
  
  // Fungsi untuk melakukan pencarian
  void _performSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      provider.setFilters(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        isActive: _isActiveFilter,
      );
      provider.fetchCategories();
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
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    setState(() {
      _selectedItems = provider.categories.map((category) => category.id).toList();
    });
  }
  
  // Fungsi untuk bulk delete
  void _bulkDelete() {
    if (_selectedItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori Terpilih'),
        content: Text('Apakah Anda yakin ingin menghapus ${_selectedItems.length} kategori?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<CategoryProvider>(context, listen: false);
              
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
                final success = await provider.deleteCategory(categoryId);
                if (!success) {
                  allSuccess = false;
                  break;
                }
              }
              
              Navigator.pop(context); // Close loading dialog
              
              if (allSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kategori berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
                _toggleSelectionMode();
                provider.fetchCategories();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus beberapa kategori'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
   
   // Widget untuk quick filter chip
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
               fontSize: 12,
               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
             ),
           ),
         ],
       ),
       selectedColor: ApiConfig.primaryColor,
       backgroundColor: ApiConfig.backgroundColor,
       checkmarkColor: ApiConfig.backgroundColor,
       onSelected: (selected) {
         setState(() {
           _quickFilter = value;
         });
         _applyQuickFilter(value);
       },
     );
   }
   
   // Fungsi untuk menerapkan quick filter
   void _applyQuickFilter(String filter) {
     final provider = Provider.of<CategoryProvider>(context, listen: false);
     
     switch (filter) {
       case 'active':
         setState(() {
           _isActiveFilter = true;
         });
         break;
       case 'inactive':
         setState(() {
           _isActiveFilter = false;
         });
         break;
       default:
         setState(() {
           _isActiveFilter = null;
         });
     }
     
     provider.setFilters(
       search: _searchQuery.isNotEmpty ? _searchQuery : null,
       isActive: _isActiveFilter,
     );
     provider.fetchCategories();
   }
   
   // Widget untuk menampilkan item kategori
   Widget _buildCategoryItem(Category category) {
     final isSelected = _selectedItems.contains(category.id);
     
     return Card(
       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
       elevation: 2,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(12),
         side: BorderSide(
           color: isSelected ? ApiConfig.primaryColor : Colors.transparent,
           width: 2,
         ),
       ),
       child: ListTile(
         leading: _isSelectionMode
             ? Checkbox(
                 value: isSelected,
                 onChanged: (value) => _toggleItemSelection(category.id),
                 activeColor: ApiConfig.primaryColor,
               )
             : CircleAvatar(
                 backgroundColor: category.isActive 
                     ? ApiConfig.primaryColor.withOpacity(0.1)
                     : Colors.grey.withOpacity(0.1),
                 child: Icon(
                   Icons.category,
                   color: category.isActive ? ApiConfig.primaryColor : Colors.grey,
                 ),
               ),
         title: Text(
           category.name,
           style: TextStyle(
             fontWeight: FontWeight.bold,
             color: ApiConfig.textColor,
           ),
         ),
         subtitle: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             if (category.description != null && category.description!.isNotEmpty)
               Text(
                 category.description!,
                 style: TextStyle(
                   color: ApiConfig.textColor.withOpacity(0.7),
                   fontSize: 12,
                 ),
                 maxLines: 2,
                 overflow: TextOverflow.ellipsis,
               ),
             const SizedBox(height: 4),
             Row(
               children: [
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                   decoration: BoxDecoration(
                     color: category.isActive ? Colors.green : Colors.red,
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Text(
                     category.isActive ? 'Aktif' : 'Nonaktif',
                     style: const TextStyle(
                       color: Colors.white,
                       fontSize: 10,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
                 const SizedBox(width: 8),
                 Text(
                   'Kode: ${category.code}',
                   style: TextStyle(
                     color: ApiConfig.textColor.withOpacity(0.6),
                     fontSize: 10,
                   ),
                 ),
                 const Spacer(),
                 Text(
                   '${category.productsCount} produk',
                   style: TextStyle(
                     color: ApiConfig.primaryColor,
                     fontSize: 10,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ],
             ),
           ],
         ),
         trailing: _isSelectionMode
             ? null
             : PopupMenuButton<String>(
                 onSelected: (value) async {
                   switch (value) {
                     case 'edit':
                       final result = await Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => CategoryFormScreen(category: category),
                         ),
                       );
                       if (result == true) {
                         Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
                       }
                       break;
                     case 'delete':
                       _showDeleteDialog(category);
                       break;
                   }
                 },
                 itemBuilder: (context) => [
                   const PopupMenuItem(
                     value: 'edit',
                     child: Row(
                       children: [
                         Icon(Icons.edit, size: 16),
                         SizedBox(width: 8),
                         Text('Edit'),
                       ],
                     ),
                   ),
                   const PopupMenuItem(
                     value: 'delete',
                     child: Row(
                       children: [
                         Icon(Icons.delete, size: 16, color: Colors.red),
                         SizedBox(width: 8),
                         Text('Hapus', style: TextStyle(color: Colors.red)),
                       ],
                     ),
                   ),
                 ],
               ),
         onTap: _isSelectionMode
             ? () => _toggleItemSelection(category.id)
             : () async {
                 final result = await Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => CategoryFormScreen(category: category),
                   ),
                 );
                 if (result == true) {
                   Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
                 }
               },
       ),
     );
   }
   
   // Dialog konfirmasi hapus
   void _showDeleteDialog(Category category) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Hapus Kategori'),
         content: Text('Apakah Anda yakin ingin menghapus kategori "${category.name}"?'),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Batal'),
           ),
           ElevatedButton(
             onPressed: () async {
               Navigator.pop(context);
               
               // Show loading
               showDialog(
                 context: context,
                 barrierDismissible: false,
                 builder: (context) => const Center(
                   child: CircularProgressIndicator(),
                 ),
               );
               
               final provider = Provider.of<CategoryProvider>(context, listen: false);
               final success = await provider.deleteCategory(category.id);
               
               Navigator.pop(context); // Close loading dialog
               
               if (success) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(
                     content: Text('Kategori berhasil dihapus'),
                     backgroundColor: Colors.green,
                   ),
                 );
                 provider.fetchCategories();
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text(provider.error ?? 'Gagal menghapus kategori'),
                     backgroundColor: Colors.red,
                   ),
                 );
               }
             },
             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
             child: const Text('Hapus'),
           ),
         ],
       ),
     );
   }
   
   @override
   Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dompet Kasir - POS | Manajemen Kategori',
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
                 _selectedItems.length == Provider.of<CategoryProvider>(context).categories.length
                     ? Icons.deselect
                     : Icons.select_all,
                 color: ApiConfig.backgroundColor,
               ),
               onPressed: () {
                 if (_selectedItems.length == Provider.of<CategoryProvider>(context, listen: false).categories.length) {
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
                 Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
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
                      hintText: 'Cari nama atau kode kategori...',
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
                  _buildQuickFilterChip('active', 'Aktif', Icons.check_circle),
                  const SizedBox(width: 8),
                  _buildQuickFilterChip('inactive', 'Nonaktif', Icons.cancel),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Content
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.categories.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (provider.error != null && provider.categories.isEmpty) {
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
                          onPressed: () => provider.fetchCategories(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (provider.categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: ApiConfig.textColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada kategori',
                          style: TextStyle(
                            fontSize: 18,
                            color: ApiConfig.textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan kategori pertama Anda',
                          style: TextStyle(
                            color: ApiConfig.textColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () => provider.fetchCategories(),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: provider.categories.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.categories.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      return _buildCategoryItem(provider.categories[index]);
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
              builder: (context) => const CategoryFormScreen(),
            ),
          );
          if (result == true) {
            Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
          }
        },
        backgroundColor: ApiConfig.primaryColor,
        foregroundColor: ApiConfig.backgroundColor,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kategori'),
      ),
    );
  }
}