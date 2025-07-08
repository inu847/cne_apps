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
  
  @override
  void initState() {
    super.initState();
    // Fetch data saat screen pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DailyInventoryStockProvider>(context, listen: false).fetchDailyInventoryStocks();
    });
  }
  
  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
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
    final isDesktop = screenWidth >= 1100;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;
    final isMobile = screenWidth < 650;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Persediaan'),
        backgroundColor: const Color(0xFF1E2A78),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                isMobile || isTablet // Gunakan tampilan mobile untuk tablet juga
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDateFilter(context),
                          const SizedBox(height: 16),
                          _buildWarehouseAndStatusFilter(context),
                          const SizedBox(height: 16),
                          _buildFilterButtons(context),
                        ],
                      )
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildDateFilter(context)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildWarehouseAndStatusFilter(context)),
                            const SizedBox(width: 16),
                            SizedBox(width: 300, child: _buildFilterButtons(context)),
                          ],
                        ),
                      ),
              ],
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
                
                return Column(
                  children: [
                    Expanded(
                      child: isMobile
                          ? _buildMobileList(provider)
                          : isTablet
                              ? _buildMobileList(provider) // Gunakan tampilan mobile untuk tablet
                              : _buildDesktopTable(provider),
                    ),
                    // Pagination
                    if (provider.pagination != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Menampilkan ${provider.dailyInventoryStocks.length} dari ${provider.pagination!.total} data',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: provider.currentPage > 1
                                          ? () {
                                              provider.setPage(provider.currentPage - 1);
                                              provider.fetchDailyInventoryStocks();
                                            }
                                          : null,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    Text('${provider.currentPage} / ${provider.pagination!.lastPage}'),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: provider.currentPage < provider.pagination!.lastPage
                                          ? () {
                                              provider.setPage(provider.currentPage + 1);
                                              provider.fetchDailyInventoryStocks();
                                            }
                                          : null,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TextField(
                controller: _dateFromController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Awal',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: TextField(
                controller: _dateToController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Akhir',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, false),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Widget untuk filter gudang dan status
  Widget _buildWarehouseAndStatusFilter(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Gudang',
                  border: OutlineInputBorder(),
                ),
                value: _warehouseId,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua Gudang')),
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
            const SizedBox(width: 16),
            Flexible(
              child: DropdownButtonFormField<bool?>(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                value: _isLocked,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua Status')),
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
          ],
        );
      },
    );
  }
  
  // Widget untuk tombol filter
  Widget _buildFilterButtons(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.filter_list),
                label: const Text('Terapkan Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2A78),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E2A78),
                  side: const BorderSide(color: Color(0xFF1E2A78)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Widget untuk tampilan list pada mobile
  Widget _buildMobileList(DailyInventoryStockProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.dailyInventoryStocks.length,
      itemBuilder: (context, index) {
        final stock = provider.dailyInventoryStocks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              'Stok Tanggal: ${stock.stockDate}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Gudang: ${stock.warehouseName}'),
                Text('Jumlah Item: ${stock.itemsCount}'),
                Text('Dibuat oleh: ${stock.createdBy}'),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stock.statusIcon,
                      size: 16,
                      color: stock.statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stock.statusText,
                      style: TextStyle(color: stock.statusColor),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InventoryDetailScreen(stockId: stock.id),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  // Widget untuk tampilan tabel pada desktop
  Widget _buildDesktopTable(DailyInventoryStockProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Tanggal')),
                DataColumn(label: Text('Gudang')),
                DataColumn(label: Text('Jumlah Item')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Dibuat Oleh')),
                DataColumn(label: Text('Aksi')),
              ],
              rows: provider.dailyInventoryStocks.map((stock) {
                return DataRow(
                  cells: [
                    DataCell(Text('#${stock.id}')),
                    DataCell(Text(stock.stockDate)),
                    DataCell(Text(stock.warehouseName)),
                    DataCell(Text('${stock.itemsCount}')),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            stock.statusIcon,
                            size: 16,
                            color: stock.statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            stock.statusText,
                            style: TextStyle(color: stock.statusColor),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(stock.createdBy)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, size: 20),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InventoryDetailScreen(stockId: stock.id),
                                ),
                              );
                            },
                            tooltip: 'Lihat Detail',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          if (!stock.isLocked)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                // TODO: Navigasi ke edit persediaan
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Fitur edit akan segera tersedia')),
                                );
                              },
                              tooltip: 'Edit',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}