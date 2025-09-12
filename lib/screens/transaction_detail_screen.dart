import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/format_utils.dart';
import '../models/order_model.dart';
import '../models/receipt_model.dart';
import '../services/receipt_service.dart';
import 'receipt_screen.dart';

// Tema warna aplikasi
const Color primaryGreen = Color(0xFF03D26F);
const Color lightBlue = Color(0xFFEAF4F4);
const Color darkBlack = Color(0xFF161514);

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: lightBlue,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: lightBlue,
        elevation: 4,
        shadowColor: primaryGreen.withOpacity(0.3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          if (_transaction != null)
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Lihat Struk',
              onPressed: _showReceipt,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Memuat detail transaksi...',
              style: TextStyle(
                color: darkBlack.withOpacity(0.7),
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_error != null) {
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
                color: darkBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $_error',
              style: TextStyle(
                color: darkBlack.withOpacity(0.7),
                fontSize: isMobile ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchTransactionDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: lightBlue,
                elevation: 2,
                shadowColor: primaryGreen.withOpacity(0.3),
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
    
    if (_transaction == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: darkBlack.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Transaksi tidak ditemukan',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: darkBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaksi dengan ID ini tidak tersedia',
              style: TextStyle(
                color: darkBlack.withOpacity(0.7),
                fontSize: isMobile ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: lightBlue,
                elevation: 2,
                shadowColor: primaryGreen.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 24,
                  vertical: isMobile ? 12 : 14,
                ),
              ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final transaction = _transaction!;
    final status = transaction['status'] ?? 'pending';
    final paymentStatus = transaction['payment_status'] ?? 'pending';
    
    Color statusColor;
    String statusText;
    if (status == 'completed') {
      statusColor = primaryGreen;
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
      paymentColor = primaryGreen;
      paymentText = 'Lunas';
    } else {
      paymentColor = Colors.orange;
      paymentText = 'Belum Lunas';
    }
    
    String formattedDate;
    try {
      if (transaction['created_at'] != null) {
        final date = DateTime.parse(transaction['created_at']);
        formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
      } else {
        formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
      }
    } catch (e) {
      formattedDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    }
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lightBlue,
            lightBlue.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan icon dan title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryGreen,
                        primaryGreen.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: lightBlue,
                    size: isMobile ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Informasi Transaksi',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: darkBlack,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Invoice number
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryGreen.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice Number',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: darkBlack.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction['invoice_number'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: darkBlack,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Date and customer info
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryGreen.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: isMobile ? 14 : 16,
                              color: primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tanggal',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 14,
                                color: darkBlack.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: darkBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryGreen.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: isMobile ? 14 : 16,
                              color: primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pelanggan',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 14,
                                color: darkBlack.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction['customer_name'] ?? 'Pelanggan Umum',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: darkBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Status badges
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: isMobile ? 14 : 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: paymentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.payment,
                        size: isMobile ? 14 : 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        paymentText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItems() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final transaction = _transaction!;
    final items = transaction['items'] as List<dynamic>? ?? [];
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lightBlue,
            lightBlue.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan icon dan title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryGreen,
                        primaryGreen.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_cart,
                    color: lightBlue,
                    size: isMobile ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Daftar Item (${items.length} item)',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: darkBlack,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Table header
            if (!isMobile) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Produk',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkBlack,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Qty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkBlack,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Harga',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkBlack,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Subtotal',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkBlack,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Items list
            items.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 48,
                            color: darkBlack.withOpacity(0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tidak ada item',
                            style: TextStyle(
                              color: darkBlack.withOpacity(0.6),
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final productName = item['product_name']?.toString() ?? 'Produk tidak diketahui';
                      final quantity = FormatUtils.safeParseInt(item['quantity'], defaultValue: 1);
                      final unitPrice = FormatUtils.safeParseInt(item['unit_price']);
                      final subtotal = FormatUtils.safeParseInt(item['subtotal']) ?? (unitPrice * quantity);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryGreen.withOpacity(0.2),
                          ),
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryGreen.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: primaryGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          productName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: darkBlack,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${quantity}x @ ${FormatUtils.formatCurrency(unitPrice)}',
                                        style: TextStyle(
                                          color: darkBlack.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        FormatUtils.formatCurrency(subtotal),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryGreen,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryGreen.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: primaryGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            productName,
                                            style: TextStyle(
                                              color: darkBlack,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${quantity}x',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: darkBlack,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      FormatUtils.formatCurrency(unitPrice),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: darkBlack,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      FormatUtils.formatCurrency(subtotal),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryGreen,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      );
                    }).toList(),
                  ),
            
            if (items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryGreen.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(
                           'Subtotal',
                           style: TextStyle(
                             color: darkBlack,
                             fontSize: isMobile ? 14 : 16,
                           ),
                         ),
                         Text(
                           FormatUtils.formatCurrency(FormatUtils.safeParseInt(transaction['total_amount'])),
                           style: TextStyle(
                             color: darkBlack,
                             fontSize: isMobile ? 14 : 16,
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 8),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(
                           _taxName,
                           style: TextStyle(
                             color: darkBlack,
                             fontSize: isMobile ? 14 : 16,
                           ),
                         ),
                         Text(
                           FormatUtils.formatCurrency(FormatUtils.safeParseInt(transaction['tax_amount'])),
                           style: TextStyle(
                             color: darkBlack,
                             fontSize: isMobile ? 14 : 16,
                           ),
                         ),
                       ],
                     ),
                     if (FormatUtils.safeParseInt(transaction['discount_amount']) > 0) ...[
                       const SizedBox(height: 8),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(
                             'Diskon',
                             style: TextStyle(
                               color: darkBlack,
                               fontSize: isMobile ? 14 : 16,
                             ),
                           ),
                           Text(
                             FormatUtils.formatCurrency(FormatUtils.safeParseInt(transaction['discount_amount'])),
                             style: TextStyle(
                               color: Colors.red,
                               fontSize: isMobile ? 14 : 16,
                             ),
                           ),
                         ],
                       ),
                     ],
                   ],
                 ),
               ),
             ],
             
             // Total section
             const SizedBox(height: 16),
             Container(
               padding: EdgeInsets.all(isMobile ? 16 : 20),
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topLeft,
                   end: Alignment.bottomRight,
                   colors: [
                     primaryGreen,
                     primaryGreen.withOpacity(0.8),
                   ],
                 ),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(
                     'Total',
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       color: lightBlue,
                       fontSize: isMobile ? 16 : 18,
                     ),
                   ),
                   Text(
                     FormatUtils.formatCurrency(FormatUtils.safeParseInt(transaction['final_amount'])),
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       color: lightBlue,
                       fontSize: isMobile ? 16 : 18,
                     ),
                   ),
                 ],
               ),
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