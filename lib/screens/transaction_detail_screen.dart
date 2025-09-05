import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/format_utils.dart';
import '../models/order_model.dart';
import '../models/receipt_model.dart';
import '../services/receipt_service.dart';
import 'receipt_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;

  const TransactionDetailScreen({Key? key, required this.transactionId}) : super(key: key);

  @override
  _TransactionDetailScreenState createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _transaction;
  String? _error;
  String _taxName = 'Pajak'; // Default value

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetail();
    _loadTaxName();
  }

  Future<void> _loadTaxName() async {
    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      
      // Fetch settings if not already loaded
      if (settingsProvider.settings == null) {
        await settingsProvider.fetchSettings();
      }
      
      // Get tax name from settings
      final taxName = settingsProvider.tax.taxName;
      if (taxName.isNotEmpty) {
        setState(() {
          _taxName = taxName;
        });
      }
    } catch (e) {
      print('Error loading tax name: $e');
      // Keep default value if error occurs
    }
  }

  Future<void> _fetchTransactionDetail() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final result = await transactionProvider.getTransactionDetail(widget.transactionId);
      
      if (!mounted) return;
      
      if (result == null) {
        setState(() {
          _error = 'Transaksi tidak ditemukan';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _transaction = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
      
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail transaksi: ${e.toString()}'))
      );
    }
  }

  // Membuat objek Order dari data transaksi
  Order _createOrderFromTransaction(Map<String, dynamic> transaction) {
    final itemsList = transaction['items'] as List<dynamic>? ?? [];
    final items = itemsList.map((item) {
      int productId = 0;
      String productName = '';
      int price = 0;
      int quantity = 0;
      String category = '';
      
      try {
        productId = int.tryParse(item['product_id']?.toString() ?? '0') ?? 0;
      } catch (e) {
        productId = 0;
      }
      
      try {
        productName = item['product_name']?.toString() ?? 'Produk tidak diketahui';
      } catch (e) {
        productName = 'Produk tidak diketahui';
      }
      
      try {
        // Konversi ke int karena OrderItem.price adalah int
        price = (double.parse((item['unit_price'] ?? '0').toString())).round();
      } catch (e) {
        price = 0;
      }
      
      try {
        quantity = int.parse((item['quantity'] ?? '0').toString());
      } catch (e) {
        quantity = 0;
      }
      
      try {
        category = item['category']?.toString() ?? 'Umum';
      } catch (e) {
        category = 'Umum';
      }
      
      // Menentukan icon berdasarkan kategori
      IconData getIconForCategory(String category) {
        switch (category.toLowerCase()) {
          case 'elektronik':
            return Icons.devices;
          case 'pakaian':
            return Icons.checkroom;
          case 'makanan':
            return Icons.restaurant;
          case 'minuman':
            return Icons.local_drink;
          case 'kesehatan':
            return Icons.health_and_safety;
          case 'kecantikan':
            return Icons.face;
          case 'rumah tangga':
            return Icons.home;
          case 'olahraga':
            return Icons.sports_soccer;
          case 'mainan':
            return Icons.toys;
          case 'buku':
            return Icons.book;
          default:
            return Icons.inventory_2;
        }
      }
      
      return OrderItem(
        id: int.tryParse(item['id']?.toString() ?? '0') ?? 0,
        productId: productId,
        productName: productName,
        price: price,
        quantity: quantity,
        category: category,
        icon: getIconForCategory(category),
      );
    }).toList();
    
    String invoiceNumber = '';
    double totalAmount = 0;
    double taxAmount = 0;
    double finalAmount = 0;
    DateTime createdAt = DateTime.now();
    String status = '';
    
    try {
      invoiceNumber = transaction['invoice_number']?.toString() ?? 'INV-${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    }
    
    try {
      totalAmount = double.parse((transaction['total_amount'] ?? '0').toString());
    } catch (e) {
      totalAmount = 0;
    }
    
    try {
      taxAmount = double.parse((transaction['tax_amount'] ?? '0').toString());
    } catch (e) {
      taxAmount = 0;
    }
    
    try {
      finalAmount = double.parse((transaction['final_amount'] ?? '0').toString());
    } catch (e) {
      finalAmount = 0;
    }
    
    try {
      if (transaction['created_at'] != null) {
        createdAt = DateTime.tryParse(transaction['created_at'].toString()) ?? DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    try {
      status = transaction['status']?.toString() ?? 'pending';
    } catch (e) {
      status = 'pending';
    }
    
    return Order(
      id: int.tryParse(transaction['id']?.toString() ?? '0') ?? 0,
      orderNumber: invoiceNumber,
      items: items,
      subtotal: totalAmount,
      tax: taxAmount,
      total: finalAmount,
      createdAt: createdAt,
      status: status,
    );
  }

  // Menampilkan receipt
  void _showReceipt() {
    if (_transaction == null) return;
    
    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final order = _createOrderFromTransaction(_transaction!);
      
      // Buat objek Receipt dari data transaksi
      final receipt = Receipt.fromTransaction(
        transaction: _transaction!,
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

  // Mencetak receipt
  void _printReceipt() async {
    if (_transaction == null) return;
    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final order = _createOrderFromTransaction(_transaction!);
      final receipt = Receipt.fromTransaction(
        transaction: _transaction!,
        order: order,
        receiptSettings: settingsProvider.receipt,
        cashierName: settingsProvider.general.cashierName ?? 'Kasir',
        storeName: settingsProvider.store.storeName ?? 'Toko',
        storeAddress: settingsProvider.store.storeAddress ?? 'Alamat Toko',
        storePhone: settingsProvider.store.storePhone ?? '-',
        storeEmail: settingsProvider.general.storeEmail ?? '-',
      );
      // Panggil ReceiptService untuk cetak struk
      final receiptService = ReceiptService();
      await receiptService.printReceipt(context, receipt);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencetak struk: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        backgroundColor: const Color(0xFF1E2A78),
        foregroundColor: Colors.white,
        actions: [
          if (_transaction != null)
            IconButton(
              icon: const Icon(Icons.receipt),
              tooltip: 'Lihat Struk',
              onPressed: _showReceipt,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat detail transaksi...'),
          ],
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchTransactionDetail,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    
    if (_transaction == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.orange),
            SizedBox(height: 16),
            Text('Transaksi tidak ditemukan', textAlign: TextAlign.center),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _fetchTransactionDetail,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildItems(),
            const SizedBox(height: 24),
            _buildPaymentInfo(),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  // ElevatedButton.icon(
                  //   icon: const Icon(Icons.receipt),
                  //   label: const Text('Lihat Struk'),
                  //   onPressed: _showReceipt,
                  // ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Cetak Struk'),
                    onPressed: _printReceipt,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final transaction = _transaction!;
    final status = transaction['status'] ?? 'pending';
    final paymentStatus = transaction['payment_status'] ?? 'pending';
    
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
      formattedDate = transaction['created_at'] != null 
          ? transaction['created_at'].toString().substring(0, 10)
          : DateTime.now().toString().substring(0, 10);
    } catch (e) {
      formattedDate = DateTime.now().toString().substring(0, 10);
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction['invoice_number'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: paymentStatus == 'paid' ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        paymentStatus,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Tanggal: $formattedDate'),
            Text('Pelanggan: ${transaction['customer_name'] ?? 'Pelanggan Umum'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildItems() {
    final transaction = _transaction!;
    final items = transaction['items'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Item',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(),
            items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text('Tidak ada item')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final productName = item['product_name']?.toString() ?? 'Produk tidak diketahui';
                      final quantity = FormatUtils.safeParseInt(item['quantity'], defaultValue: 1);
                      final unitPrice = FormatUtils.safeParseInt(item['unit_price']);
                      final subtotal = FormatUtils.safeParseInt(item['subtotal']) ?? (unitPrice * quantity);
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(productName),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('${quantity}x'),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                FormatUtils.formatCurrency(unitPrice),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                FormatUtils.formatCurrency(subtotal),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(FormatUtils.formatCurrency(FormatUtils.safeParseInt(transaction['total_amount']))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_taxName),
                Text(FormatUtils.formatCurrency(FormatUtils.safeParseInt(transaction['tax_amount']))),
              ],
            ),
            if (FormatUtils.safeParseInt(transaction['discount_amount']) > 0) ...[  
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Diskon'),
                  Text(FormatUtils.formatCurrency(FormatUtils.safeParseInt(transaction['discount_amount']))),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  FormatUtils.formatCurrency(FormatUtils.safeParseInt(transaction['final_amount'])),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final transaction = _transaction!;
    final payments = transaction['payments'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(),
            payments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text('Tidak ada informasi pembayaran')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      final paymentMethod = payment['payment_method']?.toString() ?? 'Metode tidak diketahui';
                      final amount = FormatUtils.safeParseInt(payment['amount']);
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(paymentMethod),
                            Text(FormatUtils.formatCurrency(amount)),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}