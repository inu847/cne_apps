import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../models/receipt_model.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../screens/receipt_screen.dart';
import '../screens/transaction_detail_screen.dart';
import '../utils/format_utils.dart';
import '../utils/responsive_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    _customerNameController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
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

  // Memuat daftar transaksi
  Future<void> _loadTransactions() async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.fetchTransactions();
  }

  // Refresh daftar transaksi
  Future<void> _refreshTransactions() async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.fetchTransactions();
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
              TextField(
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
              TextField(
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
    return AnimatedContainer(
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
                'Filter Transaksi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
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
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Terapkan'),
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
        title: const Text('Daftar Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onSubmitted: (value) {
                      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                      transactionProvider.setFilters(search: value.isNotEmpty ? value : null);
                      _loadTransactions();
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
          _buildFilterSection(),
          
          // Transaction list
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                if (transactionProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (transactionProvider.error != null) {
                  return Center(child: Text(transactionProvider.error!));
                }

                if (transactionProvider.transactions.isEmpty) {
                  return const Center(child: Text('Tidak ada transaksi'));
                }

                return RefreshIndicator(
                  onRefresh: _refreshTransactions,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: transactionProvider.transactions.length + (transactionProvider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == transactionProvider.transactions.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
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
    final status = transaction['status'] ?? 'pending';
    final paymentStatus = transaction['payment_status'] ?? 'pending';
    final createdAt = transaction['created_at'] ?? DateTime.now().toString();
    final invoiceNumber = transaction['invoice_number'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch}';
    final customerName = transaction['customer_name'] ?? 'Pelanggan Umum';
    final finalAmount = transaction['final_amount'] ?? 0;
    final id = transaction['id'] ?? 0;
    
    Color statusColor;
    if (status == 'completed') {
      statusColor = Colors.green;
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }
    
    String formattedDate;
    try {
      formattedDate = createdAt.toString().substring(0, 10);
    } catch (e) {
      formattedDate = DateTime.now().toString().substring(0, 10);
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              invoiceNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal: $formattedDate'),
                Text('Pelanggan: $customerName'),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: paymentStatus == 'paid' ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        paymentStatus,
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
                  FormatUtils.formatCurrency(finalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('Lihat Detail', style: TextStyle(color: Colors.blue, fontSize: 12)),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailScreen(transactionId: id),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.receipt, size: 16),
                  label: const Text('Lihat Struk'),
                  onPressed: () => _showReceipt(transaction),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}