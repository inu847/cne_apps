import 'dart:async';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../models/receipt_model.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/connectivity_provider.dart';
import '../screens/receipt_screen.dart';
import '../screens/transaction_detail_screen.dart';
import '../utils/format_utils.dart';
import '../widgets/keyboard_aware_widget.dart';
// import '../utils/responsive_helper.dart';

// Tema warna aplikasi

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFilterExpanded = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupProviders();
      _loadTransactions();
    });
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
  }

  // Setup providers untuk offline support
  void _setupProviders() async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);
    transactionProvider.setConnectivityProvider(connectivityProvider);
    
    // Inisialisasi provider dan migrasi data
    await transactionProvider.initialize();
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _customerNameController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Debounced search handler
  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _applyFilters();
    });
  }

  // Listener untuk infinite scroll
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      if (!transactionProvider.isLoading && !transactionProvider.isLoadingMore && transactionProvider.hasMoreData) {
        transactionProvider.loadMoreTransactions();
      }
    }
  }

  // Memuat daftar transaksi dengan dukungan offline
  Future<void> _loadTransactions() async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.fetchTransactionsWithOfflineSupport();
  }

  // Refresh daftar transaksi dengan dukungan offline
  Future<void> _refreshTransactions() async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.fetchTransactionsWithOfflineSupport();
  }
  
  // Menerapkan filter
  void _applyFilters() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    transactionProvider.setFilters(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      status: _selectedStatus,
      customerName: _customerNameController.text.isNotEmpty ? _customerNameController.text : null,
      startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      minAmount: _minAmountController.text.isNotEmpty ? int.tryParse(_minAmountController.text) : null,
      maxAmount: _maxAmountController.text.isNotEmpty ? int.tryParse(_maxAmountController.text) : null,
    );
    
    _loadTransactions();
    setState(() {
      _isFilterExpanded = false;
    });
  }
  
  // Reset filter
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _customerNameController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
    });
    
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    transactionProvider.resetFilters();
    _loadTransactions();
  }

  // Sinkronisasi transaksi yang belum tersinkronisasi
  Future<void> _syncTransactions() async {
    final connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    // Verifikasi koneksi internet
    if (connectivityProvider.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat melakukan sinkronisasi dalam mode offline'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Ambil transaksi yang belum tersinkronisasi dengan verifikasi status
    final unsyncedTransactions = await transactionProvider.getUnsyncedTransactions();

    // Verifikasi apakah ada transaksi yang perlu disinkronisasi
    if (unsyncedTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua transaksi offline sudah tersinkronisasi'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // Filter ulang untuk memastikan hanya transaksi dengan status "belum sync"
    final validUnsyncedTransactions = unsyncedTransactions.where((transaction) {
      return transaction['is_synced'] != true && transaction['source'] == 'offline';
    }).toList();

    if (validUnsyncedTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada transaksi offline yang perlu disinkronisasi'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // Tampilkan dialog konfirmasi dengan informasi detail
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Sinkronisasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Akan melakukan sinkronisasi ${validUnsyncedTransactions.length} transaksi offline yang belum tersinkronisasi.'),
            const SizedBox(height: 8),
            Text(
              'Proses ini akan mengirimkan data transaksi offline ke server menggunakan endpoint yang sama seperti pembuatan transaksi POS.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Lanjutkan?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ApiConfig.primaryColor,
            ),
            child: const Text('Sinkronisasi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Tampilkan loading dengan progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Melakukan sinkronisasi ${validUnsyncedTransactions.length} transaksi offline...'),
            const SizedBox(height: 8),
            Text(
              'Mohon tunggu, proses ini mungkin memerlukan waktu beberapa saat.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      int successCount = 0;
      int failedCount = 0;
      List<String> failedTransactions = [];
      
      // Proses sinkronisasi untuk setiap transaksi yang belum tersinkronisasi
      // Menggunakan endpoint yang sama seperti di halaman POS
      for (int i = 0; i < validUnsyncedTransactions.length; i++) {
        final transaction = validUnsyncedTransactions[i];
        
        // Verifikasi ulang status sebelum sinkronisasi
        if (transaction['is_synced'] == true) {
          print('Transaksi ${transaction['invoice_number']} sudah tersinkronisasi, skip');
          continue;
        }
        
        final result = await transactionProvider.syncIndividualTransaction(transaction);
        
        if (result['success']) {
          successCount++;
          print('Sinkronisasi berhasil untuk transaksi: ${transaction['invoice_number']}');
        } else {
          failedCount++;
          final invoiceNumber = transaction['invoice_number'] ?? transaction['id'].toString();
          failedTransactions.add(invoiceNumber);
          print('Sinkronisasi gagal untuk transaksi: $invoiceNumber - ${result['message']}');
        }
      }
      
      Navigator.of(context).pop(); // Tutup loading dialog
      
      // Tampilkan hasil sinkronisasi dengan detail
      if (successCount > 0 && failedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Berhasil melakukan sinkronisasi $successCount transaksi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (successCount > 0 && failedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Sinkronisasi selesai: $successCount berhasil, $failedCount gagal'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Detail',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Detail Sinkronisasi'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Berhasil: $successCount transaksi'),
                        Text('Gagal: $failedCount transaksi'),
                        if (failedTransactions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Transaksi yang gagal:'),
                          ...failedTransactions.map((invoice) => Text('• $invoice')),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Semua sinkronisasi gagal ($failedCount transaksi)'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      // Refresh data setelah sinkronisasi untuk memperbarui status
      _refreshTransactions();
      
    } catch (e) {
      Navigator.of(context).pop(); // Tutup loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal melakukan sinkronisasi: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Membangun widget filter tanggal
  Widget _buildDateFilter() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dari Tanggal'),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                    });
                  }
                },
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
                        _startDate != null
                            ? DateFormat('dd/MM/yyyy').format(_startDate!)
                            : 'Pilih Tanggal',
                        style: TextStyle(
                          color: _startDate != null ? Colors.black : Colors.grey,
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
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _endDate = picked;
                    });
                  }
                },
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
                        _endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : 'Pilih Tanggal',
                        style: TextStyle(
                          color: _endDate != null ? Colors.black : Colors.grey,
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
  
  // Membangun widget filter status
  Widget _buildStatusFilter() {
    return Column(
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
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedStatus,
              hint: const Text('Semua Status'),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
  
  // Membangun widget filter jumlah
  Widget _buildAmountFilter() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Jumlah Minimal'),
              const SizedBox(height: 4),
              PerformantTextField(
                controller: _minAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Min',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
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
              const Text('Jumlah Maksimal'),
              const SizedBox(height: 4),
              PerformantTextField(
                controller: _maxAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Max',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Membangun widget filter pelanggan
  Widget _buildCustomerFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nama Pelanggan'),
        const SizedBox(height: 4),
        TextField(
          controller: _customerNameController,
          autofocus: false,
          enableInteractiveSelection: false,
          decoration: const InputDecoration(
            hintText: 'Nama Pelanggan',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
  
  // Membangun widget filter
  Widget _buildFilterSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isFilterExpanded ? null : 0,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
        ),
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
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 8),
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
              Row(
                children: [
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
                      Icons.filter_alt,
                      color: ApiConfig.backgroundColor,
                      size: isMobile ? 18 : 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Filter Transaksi',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: ApiConfig.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDateFilter(),
              const SizedBox(height: 16),
              _buildStatusFilter(),
              const SizedBox(height: 16),
              _buildAmountFilter(),
              const SizedBox(height: 16),
              _buildCustomerFilter(),
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
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
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
                    child: Text(
                      'Terapkan',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dompet Kasir - POS | Daftar Transaksi',
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
          // Indikator status koneksi dan tombol switch mode
          Consumer<ConnectivityProvider>(
            builder: (context, connectivityProvider, child) {
              return PopupMenuButton<String>(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connectivityProvider.getStatusIcon(),
                      color: connectivityProvider.getStatusIconColor(),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: connectivityProvider.isOnline 
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        connectivityProvider.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: connectivityProvider.isOnline 
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                tooltip: 'Mode Koneksi',
                onSelected: (String value) {
                  if (value == 'toggle') {
                    connectivityProvider.toggleMode();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Row(
                      children: [
                        Icon(
                          connectivityProvider.getStatusIcon(),
                          color: connectivityProvider.getStatusIconColor(),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          connectivityProvider.statusMessage,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          connectivityProvider.isOnline 
                            ? Icons.wifi_off 
                            : Icons.wifi,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          connectivityProvider.isOnline 
                            ? 'Beralih ke Offline'
                            : 'Beralih ke Online',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Consumer<ConnectivityProvider>(
            builder: (context, connectivityProvider, child) {
              return Consumer<TransactionProvider>(
                builder: (context, transactionProvider, child) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: transactionProvider.getUnsyncedTransactions(),
                    builder: (context, snapshot) {
                      final unsyncedCount = snapshot.data?.length ?? 0;

                      return Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.sync,
                              color: connectivityProvider.isOffline 
                                ? Colors.grey 
                                : ApiConfig.backgroundColor,
                            ),
                            onPressed: connectivityProvider.isOffline 
                              ? null 
                              : () => _syncTransactions(),
                            tooltip: connectivityProvider.isOffline 
                              ? 'Sinkronisasi tidak tersedia (offline)' 
                              : 'Sinkronisasi Data',
                          ),
                          if (unsyncedCount > 0 && connectivityProvider.isOnline)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$unsyncedCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTransactions,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar dengan desain yang lebih menarik
          Container(
            margin: EdgeInsets.all(isMobile ? 12 : 16),
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ApiConfig.primaryColor.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: ApiConfig.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    enableInteractiveSelection: false,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(
                      color: ApiConfig.textColor,
                      fontSize: isMobile ? 14 : 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi berdasarkan invoice, pelanggan...',
                      hintStyle: TextStyle(
                        color: ApiConfig.textColor.withOpacity(0.6),
                        fontSize: isMobile ? 14 : 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: ApiConfig.primaryColor,
                        size: isMobile ? 20 : 24,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: ApiConfig.textColor.withOpacity(0.6),
                                size: isMobile ? 20 : 24,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                                transactionProvider.setFilters(search: null);
                                _loadTransactions();
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
                        horizontal: 16,
                        vertical: isMobile ? 12 : 16,
                      ),
                    ),
                    onSubmitted: (value) {
                      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                      transactionProvider.setFilters(search: value.isNotEmpty ? value : null);
                      _loadTransactions();
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _isFilterExpanded ? ApiConfig.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ApiConfig.primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
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
                    tooltip: _isFilterExpanded ? 'Tutup Filter' : 'Buka Filter',
                  ),
                ),
              ],
            ),
          ),
          
          // Filter section
          _buildFilterSection(),
          
          // Transaction list
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                if (transactionProvider.isLoading) {
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
                          'Memuat transaksi...',
                          style: TextStyle(
                            color: ApiConfig.textColor.withOpacity(0.7),
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (transactionProvider.error != null) {
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
                          transactionProvider.error!,
                          style: TextStyle(
                            color: ApiConfig.textColor.withOpacity(0.7),
                            fontSize: isMobile ? 14 : 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _refreshTransactions,
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

                if (transactionProvider.transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: ApiConfig.textColor.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada transaksi',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: ApiConfig.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Transaksi yang dibuat akan muncul di sini',
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
                  onRefresh: _refreshTransactions,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: transactionProvider.transactions.length + (transactionProvider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == transactionProvider.transactions.length) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(ApiConfig.primaryColor),
                                  strokeWidth: 2,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Memuat lebih banyak...',
                                  style: TextStyle(
                                    color: ApiConfig.textColor.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final transaction = transactionProvider.transactions[index];
                      return _buildTransactionItem(transaction);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Membuat objek Order dari data transaksi
  Order _createOrderFromTransaction(Map<String, dynamic> transaction) {
    final List<dynamic> itemsData = transaction['items'] as List<dynamic>;
    
    final List<OrderItem> orderItems = itemsData.map((item) {
      return OrderItem(
        productId: item['product_id'],
        productName: item['product_name'] ?? 'Produk',
        price: (item['unit_price'] ?? 0).toDouble(),
        quantity: item['quantity'] ?? 1,
        category: item['category'] ?? 'Umum',
        icon: Icons.inventory_2,
      );
    }).toList();
    
    return Order(
      orderNumber: transaction['invoice_number'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
      items: orderItems,
      subtotal: (transaction['total_amount'] ?? 0).toDouble() - (transaction['tax_amount'] ?? 0).toDouble(),
      tax: (transaction['tax_amount'] ?? 0).toDouble(),
      total: (transaction['final_amount'] ?? 0).toDouble(),
      createdAt: transaction['created_at'] != null ? DateTime.parse(transaction['created_at']) : DateTime.now(),
      status: transaction['status'] ?? 'pending',
    );
  }

  // Menampilkan receipt
  void _showReceipt(Map<String, dynamic> transaction) {
    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final order = _createOrderFromTransaction(transaction);
      
      // Buat objek Receipt dari data transaksi
      final receipt = Receipt.fromTransaction(
        transaction: transaction,
        order: order,
        receiptSettings: settingsProvider.receipt,
        cashierName: settingsProvider.general.cashierName ?? 'Kasir',
        storeName: settingsProvider.store.storeName ?? 'Toko',
        storeAddress: settingsProvider.store.storeAddress ?? 'Alamat Toko',
        storePhone: settingsProvider.store.storePhone ?? '-',
        storeEmail: settingsProvider.general.storeEmail ?? '-',
      );
      
      // Navigasi ke receipt screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(receipt: receipt),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menampilkan struk: ${e.toString()}'))
      );
    }
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    final status = transaction['status'] ?? 'pending';
    final paymentStatus = transaction['payment_status'] ?? 'pending';
    final createdAt = transaction['created_at'] ?? DateTime.now().toString();
    final invoiceNumber = transaction['invoice_number'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch}';
    final customerName = transaction['customer_name'] ?? 'Pelanggan Umum';
    final totalAmount = transaction['total_amount'] ?? 0;
    final id = transaction['id'] ?? 0;
    
    // Cek apakah transaksi belum tersinkronisasi berdasarkan field is_synced
    bool isUnsynced = transaction['is_synced'] != true;
    
    Color statusColor;
    String statusText;
    if (status == 'completed') {
      statusColor = ApiConfig.primaryColor;
      statusText = 'Selesai';
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
      statusText = 'Dibatalkan';
    } else {
      statusColor = Colors.orange;
      statusText = 'Pending';
    }
    
    Color paymentColor;
    String paymentText;
    if (paymentStatus == 'paid') {
      paymentColor = ApiConfig.primaryColor;
      paymentText = 'Lunas';
    } else {
      paymentColor = Colors.orange;
      paymentText = 'Belum Lunas';
    }
    
    String formattedDate;
    try {
      final date = DateTime.parse(createdAt);
      formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      formattedDate = DateTime.now().toString().substring(0, 10);
    }
    
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
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isUnsynced ? Colors.orange : ApiConfig.primaryColor.withOpacity(0.2),
          width: isUnsynced ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(transactionId: id),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan invoice dan tanggal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                invoiceNumber,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 16 : 18,
                                  color: ApiConfig.textColor,
                                ),
                              ),
                              if (isUnsynced) ...[
                                 const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.orange, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.sync_problem,
                                        size: 12,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Belum Sync',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: isMobile ? 14 : 16,
                                color: ApiConfig.textColor.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                  color: ApiConfig.textColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: ApiConfig.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ApiConfig.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        FormatUtils.formatCurrency(totalAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 16,
                          color: ApiConfig.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Customer info
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: isMobile ? 16 : 18,
                      color: ApiConfig.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customerName,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: ApiConfig.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Status badges dan action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 10,
                            vertical: isMobile ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 10,
                            vertical: isMobile ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: paymentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            paymentText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Lihat Detail',
                          style: TextStyle(
                            color: ApiConfig.primaryColor,
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: isMobile ? 12 : 14,
                          color: ApiConfig.primaryColor,
                        ),
                      ],
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
}