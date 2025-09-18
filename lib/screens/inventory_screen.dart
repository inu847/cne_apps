import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cne_pos_apps/models/daily_inventory_stock_model.dart';
import 'package:cne_pos_apps/providers/daily_inventory_stock_provider.dart';
import 'package:cne_pos_apps/screens/inventory_detail_screen.dart';
import 'package:cne_pos_apps/screens/create_inventory_screen.dart';
import '../config/api_config.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // Theme colors - menggunakan warna dari ApiConfig
  
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _displayDateFormat = DateFormat('dd MMM yyyy');
  
  // Controller untuk date picker
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  
  // State untuk filter
  String? _dateFrom;
  String? _dateTo;
  int? _warehouseId;
  bool? _isLocked;
  bool _isFilterExpanded = false;
  
  // State untuk search dan bulk operations
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<int> _selectedItems = [];
  bool _isSelectionMode = false;
  
  // State untuk quick filters
  String _quickFilter = 'all'; // all, locked, unlocked, today, week
  
  // Scroll controller untuk infinite scroll
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    // Fetch data saat screen pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DailyInventoryStockProvider>(context, listen: false).fetchDailyInventoryStocks();
    });
    
    // Tambahkan listener untuk infinite scroll
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Listener untuk infinite scroll
  void _scrollListener() async {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      final provider = Provider.of<DailyInventoryStockProvider>(context, listen: false);
      
      // Periksa apakah masih ada halaman berikutnya
      if (provider.pagination != null && 
          provider.currentPage < provider.pagination!.lastPage) {
        setState(() {
          _isLoadingMore = true;
        });
        
        // Muat halaman berikutnya
        await provider.loadMoreDailyInventoryStocks();
        
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }
  
  // Fungsi untuk menampilkan date picker
  Future<void> _selectDate(BuildContext context, bool isDateFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    
    if (picked != null) {
      final formattedDate = _dateFormat.format(picked);
      setState(() {
        if (isDateFrom) {
          _dateFrom = formattedDate;
          _dateFromController.text = _displayDateFormat.format(picked);
        } else {
          _dateTo = formattedDate;
          _dateToController.text = _displayDateFormat.format(picked);
        }
      });
    }
  }
  
  // Fungsi untuk menerapkan filter
  void _applyFilters() {
    final provider = Provider.of<DailyInventoryStockProvider>(context, listen: false);
    provider.setFilters(
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      warehouseId: _warehouseId,
      isLocked: _isLocked,
    );
    provider.fetchDailyInventoryStocks();
  }
  
  // Fungsi untuk mereset filter
  void _resetFilters() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _warehouseId = null;
      _isLocked = null;
      _dateFromController.clear();
      _dateToController.clear();
      _searchController.clear();
      _searchQuery = '';
      _quickFilter = 'all';
    });
    
    final provider = Provider.of<DailyInventoryStockProvider>(context, listen: false);
    provider.resetFilters();
    provider.fetchDailyInventoryStocks();
  }
  
  // Fungsi untuk melakukan pencarian
  void _performSearch() {
    final provider = Provider.of<DailyInventoryStockProvider>(context, listen: false);
    // Implementasi search logic di sini
    provider.fetchDailyInventoryStocks();
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
  void _toggleItemSelection(int stockId) {
    setState(() {
      if (_selectedItems.contains(stockId)) {
        _selectedItems.remove(stockId);
      } else {
        _selectedItems.add(stockId);
      }
    });
  }
  
  // Fungsi untuk select all items
  void _selectAllItems() {
    final provider = Provider.of<DailyInventoryStockProvider>(context, listen: false);
    setState(() {
      _selectedItems = provider.dailyInventoryStocks.map((stock) => stock.id).toList();
    });
  }
  
  // Fungsi untuk bulk delete
  void _bulkDelete() {
    if (_selectedItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item Terpilih'),
        content: Text('Apakah Anda yakin ingin menghapus ${_selectedItems.length} item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implementasi bulk delete
              Navigator.pop(context);
              _toggleSelectionMode();
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
     final provider = Provider.of<DailyInventoryStockProvider>(context, listen: false);
     final now = DateTime.now();
     
     switch (filter) {
       case 'today':
         setState(() {
           _dateFrom = DateFormat('yyyy-MM-dd').format(now);
           _dateTo = DateFormat('yyyy-MM-dd').format(now);
         });
         break;
       case 'week':
         final weekStart = now.subtract(Duration(days: now.weekday - 1));
         setState(() {
           _dateFrom = DateFormat('yyyy-MM-dd').format(weekStart);
           _dateTo = DateFormat('yyyy-MM-dd').format(now);
         });
         break;
       case 'locked':
         setState(() {
           _isLocked = true;
         });
         break;
       case 'unlocked':
         setState(() {
           _isLocked = false;
         });
         break;
       default:
         setState(() {
           _dateFrom = null;
           _dateTo = null;
           _isLocked = null;
         });
     }
     
     provider.setFilters(
       dateFrom: _dateFrom,
       dateTo: _dateTo,
       warehouseId: _warehouseId,
       isLocked: _isLocked,
     );
     provider.fetchDailyInventoryStocks();
   }
   
   @override
   Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dompet Kasir - POS | Manajemen Persediaan',
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
                 _selectedItems.length == Provider.of<DailyInventoryStockProvider>(context).dailyInventoryStocks.length
                     ? Icons.deselect
                     : Icons.select_all,
                 color: ApiConfig.backgroundColor,
               ),
               onPressed: () {
                 if (_selectedItems.length == Provider.of<DailyInventoryStockProvider>(context, listen: false).dailyInventoryStocks.length) {
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
                 Provider.of<DailyInventoryStockProvider>(context, listen: false).fetchDailyInventoryStocks();
               },
               tooltip: 'Refresh Data',
             ),
           ],
         ],
      ),
      // FloatingActionButton dipindahkan ke bagian bawah
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
                      hintText: 'Cari ID, gudang, atau tanggal...',
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
                      // Debounce search untuk performa yang lebih baik
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_searchQuery == value) {
                          _performSearch();
                        }
                      });
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
          
          // Quick filters untuk stock opname
          if (!_isSelectionMode)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildQuickFilterChip('all', 'Semua', Icons.list_alt),
                  const SizedBox(width: 8),
                  _buildQuickFilterChip('today', 'Hari Ini', Icons.today),
                  const SizedBox(width: 8),
                  _buildQuickFilterChip('week', 'Minggu Ini', Icons.date_range),
                  const SizedBox(width: 8),
                  _buildQuickFilterChip('locked', 'Terkunci', Icons.lock),
                  const SizedBox(width: 8),
                  _buildQuickFilterChip('unlocked', 'Belum Terkunci', Icons.lock_open),
                ],
              ),
            ),
          
          // Filter section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isFilterExpanded ? null : 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                border: Border.all(
                  color: ApiConfig.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Persediaan',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: ApiConfig.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDateFilter(context),
                    const SizedBox(height: 16),
                    _buildWarehouseAndStatusFilter(context),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _resetFilters,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: ApiConfig.primaryColor, width: 2),
                            foregroundColor: ApiConfig.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 20,
                              vertical: isMobile ? 12 : 14,
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ApiConfig.primaryColor,
                            foregroundColor: ApiConfig.backgroundColor,
                            elevation: 2,
                            shadowColor: ApiConfig.primaryColor.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 20,
                              vertical: isMobile ? 12 : 14,
                            ),
                          ),
                          child: const Text('Terapkan'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content section
          Expanded(
            child: Consumer<DailyInventoryStockProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(ApiConfig.primaryColor),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Memuat data persediaan...',
                          style: TextStyle(
                            color: ApiConfig.textColor.withOpacity(0.7),
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal memuat data',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: ApiConfig.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          style: TextStyle(
                            color: ApiConfig.textColor.withOpacity(0.7),
                            fontSize: isMobile ? 14 : 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearError();
                            provider.fetchDailyInventoryStocks();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ApiConfig.primaryColor,
                            foregroundColor: ApiConfig.backgroundColor,
                            elevation: 2,
                            shadowColor: ApiConfig.primaryColor.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 20 : 24,
                              vertical: isMobile ? 12 : 14,
                            ),
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (provider.dailyInventoryStocks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: ApiConfig.textColor.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data persediaan',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: ApiConfig.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada data persediaan harian yang tersedia',
                          style: TextStyle(
                            color: ApiConfig.textColor.withOpacity(0.7),
                            fontSize: isMobile ? 14 : 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.fetchDailyInventoryStocks();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: provider.dailyInventoryStocks.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.dailyInventoryStocks.length && _isLoadingMore) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(ApiConfig.primaryColor),
                              strokeWidth: 2.5,
                            ),
                          ),
                        );
                      }
                      
                      final stock = provider.dailyInventoryStocks[index];
                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16, 
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              ApiConfig.backgroundColor.withOpacity(0.3),
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
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: ApiConfig.primaryColor.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleItemSelection(stock.id);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InventoryDetailScreen(stockId: stock.id),
                                ),
                              );
                            }
                          },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              _toggleSelectionMode();
                              _toggleItemSelection(stock.id);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row
                                Row(
                                  children: [
                                    if (_isSelectionMode)
                                      Container(
                                        margin: const EdgeInsets.only(right: 12),
                                        child: Checkbox(
                                          value: _selectedItems.contains(stock.id),
                                          onChanged: (value) {
                                            _toggleItemSelection(stock.id);
                                          },
                                          activeColor: ApiConfig.primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            ApiConfig.primaryColor,
                                            ApiConfig.primaryColor.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2,
                                        color: ApiConfig.backgroundColor,
                                        size: isMobile ? 20 : 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Stok #${stock.id}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: isMobile ? 16 : 18,
                                                    color: ApiConfig.textColor,
                                                  ),
                                                ),
                                              ),
                                              if (!_isSelectionMode)
                                                Icon(
                                                  Icons.more_vert,
                                                  color: ApiConfig.textColor.withOpacity(0.5),
                                                  size: 16,
                                                ),
                                            ],
                                          ),
                                          Text(
                                            stock.stockDate,
                                            style: TextStyle(
                                              color: ApiConfig.textColor.withOpacity(0.7),
                                              fontSize: isMobile ? 12 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12, 
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: stock.statusColor,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: stock.statusColor.withOpacity(0.3),
                                            blurRadius: 4,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        stock.statusText,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isMobile ? 10 : 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Info row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: ApiConfig.backgroundColor.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.warehouse,
                                              size: isMobile ? 14 : 16,
                                              color: ApiConfig.primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                stock.warehouseName,
                                                style: TextStyle(
                                                  fontSize: isMobile ? 11 : 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: ApiConfig.textColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: ApiConfig.backgroundColor.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.inventory,
                                              size: isMobile ? 14 : 16,
                                              color: ApiConfig.primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '${stock.itemsCount} item',
                                                style: TextStyle(
                                                  fontSize: isMobile ? 11 : 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: ApiConfig.textColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Creator info
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: isMobile ? 14 : 16,
                                      color: ApiConfig.textColor.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Dibuat oleh: ${stock.createdBy}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 11 : 12,
                                        color: ApiConfig.textColor.withOpacity(0.6),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: isMobile ? 12 : 14,
                                      color: ApiConfig.primaryColor,
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
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode || Provider.of<DailyInventoryStockProvider>(context).dailyInventoryStocks.isNotEmpty
          ? Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ApiConfig.backgroundColor,
                    ApiConfig.backgroundColor.withOpacity(0.8),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: ApiConfig.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: _isSelectionMode
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedItems.length} item dipilih',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ApiConfig.textColor,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _selectedItems.isNotEmpty ? _bulkDelete : null,
                              icon: Icon(Icons.delete, size: isMobile ? 16 : 18),
                              label: Text(
                                'Hapus',
                                style: TextStyle(fontSize: isMobile ? 12 : 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Consumer<DailyInventoryStockProvider>(
                      builder: (context, provider, child) {
                        final totalItems = provider.dailyInventoryStocks.length;
                        final lockedItems = provider.dailyInventoryStocks.where((stock) => stock.isLocked ?? false).length;
                        final unlockedItems = totalItems - lockedItems;
                        
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem('Total', totalItems.toString(), Icons.inventory_2, ApiConfig.primaryColor),
                            _buildSummaryItem('Terkunci', lockedItems.toString(), Icons.lock, Colors.orange),
                            _buildSummaryItem('Belum Terkunci', unlockedItems.toString(), Icons.lock_open, Colors.blue),
                          ],
                        );
                      },
                    ),
            )
          : null,
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateInventoryScreen(),
                  ),
                ).then((result) {
                  // Refresh data jika ada perubahan
                  if (result == true) {
                    Provider.of<DailyInventoryStockProvider>(context, listen: false).fetchDailyInventoryStocks();
                  }
                });
              },
              backgroundColor: ApiConfig.primaryColor,
              foregroundColor: ApiConfig.backgroundColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  // Widget untuk filter tanggal
  Widget _buildDateFilter(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dari Tanggal'),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dateFrom != null
                            ? _displayDateFormat.format(DateTime.parse(_dateFrom!))
                            : 'Pilih Tanggal',
                        style: TextStyle(
                          color: _dateFrom != null ? Colors.black : Colors.grey,
                        ),
                      ),
                      const Icon(Icons.calendar_today, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sampai Tanggal'),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dateTo != null
                            ? _displayDateFormat.format(DateTime.parse(_dateTo!))
                            : 'Pilih Tanggal',
                        style: TextStyle(
                          color: _dateTo != null ? Colors.black : Colors.grey,
                        ),
                      ),
                      const Icon(Icons.calendar_today, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Widget untuk filter gudang dan status
  Widget _buildWarehouseAndStatusFilter(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gudang'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _warehouseId,
                    hint: const Text('Semua Gudang'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Gudang Pusat')),
                      // TODO: Tambahkan daftar gudang dari API
                    ],
                    onChanged: (value) {
                      setState(() {
                        _warehouseId = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool?>(
                    isExpanded: true,
                    value: _isLocked,
                    hint: const Text('Semua Status'),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('Terkunci')),
                      DropdownMenuItem(value: false, child: Text('Belum Terkunci')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _isLocked = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Widget untuk tombol filter telah dihapus karena sudah digantikan dengan tombol di filter section
  
  // Widget untuk summary item di bottom navigation
  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: isMobile ? 20 : 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : 18,
            color: ApiConfig.textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: ApiConfig.textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  // Fungsi-fungsi yang tidak lagi digunakan telah dihapus
}