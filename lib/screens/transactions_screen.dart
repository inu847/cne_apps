import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/receipt_model.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../screens/receipt_screen.dart';
import '../screens/transaction_detail_screen.dart';
import '../utils/format_utils.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  // Memuat daftar transaksi
  Future<void> _loadTransactions() async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.fetchTransactions();
    setState(() {
      _isLoading = false;
    });
  }

  // Refresh daftar transaksi
  Future<void> _refreshTransactions() async {
    setState(() {
      _isLoading = true;
    });
    await _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                if (transactionProvider.error != null) {
                  return Center(child: Text(transactionProvider.error!));
                }

                if (transactionProvider.transactions.isEmpty) {
                  return const Center(child: Text('Tidak ada transaksi'));
                }

                return RefreshIndicator(
                  onRefresh: _refreshTransactions,
                  child: ListView.builder(
                    itemCount: transactionProvider.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactionProvider.transactions[index];
                      return _buildTransactionItem(transaction);
                    },
                  ),
                );
              },
            ),
    );
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
  void _showReceipt(Map<String, dynamic> transaction) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final order = _createOrderFromTransaction(transaction);
    
    // Buat objek Receipt dari data transaksi
    final receipt = Receipt.fromTransaction(
      transaction: transaction,
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

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              transaction['invoice_number'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal: ${transaction['created_at'].toString().substring(0, 10)}'),
                Text('Pelanggan: ${transaction['customer_name']}'),
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
                  FormatUtils.formatCurrency(transaction['final_amount']),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('Lihat Detail', style: TextStyle(color: Colors.blue, fontSize: 12)),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailScreen(transactionId: transaction['id']),
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