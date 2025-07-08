import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cne_pos_apps/models/daily_inventory_stock_model.dart';
import 'package:cne_pos_apps/providers/daily_inventory_stock_provider.dart';
import 'package:cne_pos_apps/screens/inventory_detail_screen.dart';
import 'package:cne_pos_apps/screens/create_inventory_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
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
    });
    
    final provider = Provider.of<DailyInventoryStockProvider>(context, listen: false);
    provider.resetFilters();
    provider.fetchDailyInventoryStocks();
  }
  
  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Persediaan'),
        backgroundColor: const Color(0xFF1E2A78),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DailyInventoryStockProvider>(context, listen: false).fetchDailyInventoryStocks();
            },
          ),
        ],
      ),
      // FloatingActionButton dipindahkan ke bagian bawah
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari persediaan...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onSubmitted: (value) {
                      // Implementasi pencarian dapat ditambahkan di sini
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                    color: _isFilterExpanded ? Colors.blue : null,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFilterExpanded = !_isFilterExpanded;
                    });
                  },
                  tooltip: 'Filter',
                ),
              ],
            ),
          ),
          
          // Filter section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isFilterExpanded ? null : 0,
            child: Card(
              margin: const EdgeInsets.all(0),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Persediaan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          child: const Text('Reset'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E2A78),
                            foregroundColor: Colors.white,
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
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${provider.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearError();
                            provider.fetchDailyInventoryStocks();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (provider.dailyInventoryStocks.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada data persediaan harian'),
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
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final stock = provider.dailyInventoryStocks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                'Stok #${stock.id}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tanggal: ${stock.stockDate}'),
                                  Text('Gudang: ${stock.warehouseName}'),
                                  Text('Jumlah Item: ${stock.itemsCount}'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: stock.statusColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          stock.statusText,
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Dibuat oleh: ${stock.createdBy}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const Text('Lihat Detail', style: TextStyle(color: Colors.blue, fontSize: 12)),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InventoryDetailScreen(stockId: stock.id),
                                  ),
                                );
                              },
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton(
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
        backgroundColor: const Color(0xFF1E2A78),
        child: const Icon(Icons.add),
      ),
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
  
  // Fungsi-fungsi yang tidak lagi digunakan telah dihapus
}