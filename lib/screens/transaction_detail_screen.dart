import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/format_utils.dart';
import '../models/order_model.dart';
import '../models/receipt_model.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetail();
  }

  Future<void> _fetchTransactionDetail() async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final result = await transactionProvider.getTransactionDetail(widget.transactionId);
      
      setState(() {
        _transaction = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Membuat objek Order dari data transaksi
  Order _createOrderFromTransaction(Map<String, dynamic> transaction) {
    final List<dynamic> itemsData = transaction['items'] as List<dynamic>;
    
    final List<OrderItem> orderItems = itemsData.map((item) {
      return OrderItem(
        productId: item['product_id'],
        productName: item['product_name'],
        price: item['unit_price'].toDouble(),
        quantity: item['quantity'],
        category: item['category'] ?? 'Umum',
        icon: Icons.inventory_2,
      );
    }).toList();
    
    return Order(
      orderNumber: transaction['invoice_number'],
      items: orderItems,
      subtotal: transaction['total_amount'].toDouble() - transaction['tax_amount'].toDouble(),
      tax: transaction['tax_amount'].toDouble(),
      total: transaction['final_amount'].toDouble(),
      createdAt: DateTime.parse(transaction['created_at']),
      status: transaction['status'],
    );
  }

  // Menampilkan receipt
  void _showReceipt() {
    if (_transaction == null) return;
    
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final order = _createOrderFromTransaction(_transaction!);
    
    // Buat objek Receipt dari data transaksi
    final receipt = Receipt.fromTransaction(
      transaction: _transaction!,
      order: order,
      receiptSettings: settingsProvider.receipt,
      cashierName: settingsProvider.general.cashierName,
      storeName: settingsProvider.store.storeName,
      storeAddress: settingsProvider.store.storeAddress,
      storePhone: settingsProvider.store.storePhone,
    );
    
    // Navigasi ke receipt screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptScreen(receipt: receipt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_transaction == null) {
      return const Center(child: Text('Transaksi tidak ditemukan'));
    }

    return SingleChildScrollView(
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
            child: ElevatedButton.icon(
              icon: const Icon(Icons.receipt),
              label: const Text('Lihat Struk'),
              onPressed: _showReceipt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final transaction = _transaction!;
    final status = transaction['status'];
    final paymentStatus = transaction['payment_status'];
    
    Color statusColor;
    if (status == 'completed') {
      statusColor = Colors.green;
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
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
                  transaction['invoice_number'],
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
            Text('Tanggal: ${transaction['created_at'].toString().substring(0, 10)}'),
            Text('Pelanggan: ${transaction['customer_name']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildItems() {
    final transaction = _transaction!;
    final items = transaction['items'] as List<dynamic>;
    
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(item['product_name']),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text('${item['quantity']}x'),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          FormatUtils.formatCurrency(item['unit_price']),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          FormatUtils.formatCurrency(item['subtotal']),
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
                Text(FormatUtils.formatCurrency(transaction['total_amount'])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pajak'),
                Text(FormatUtils.formatCurrency(transaction['tax_amount'])),
              ],
            ),
            if (transaction['discount_amount'] > 0) ...[  
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Diskon'),
                  Text(FormatUtils.formatCurrency(transaction['discount_amount'])),
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
                  FormatUtils.formatCurrency(transaction['final_amount']),
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
    final payments = transaction['payments'] as List<dynamic>;
    
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(payment['payment_method']),
                      Text(FormatUtils.formatCurrency(payment['amount'])),
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