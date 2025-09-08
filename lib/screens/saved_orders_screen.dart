import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../utils/format_utils.dart';

class SavedOrdersScreen extends StatefulWidget {
  const SavedOrdersScreen({super.key});

  @override
  State<SavedOrdersScreen> createState() => _SavedOrdersScreenState();
}

class _SavedOrdersScreenState extends State<SavedOrdersScreen> {
  final Color _primaryColor = Colors.blue.shade800;
  final Color _lightColor = Colors.blue.shade50;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedOrders();
  }

  Future<void> _loadSavedOrders() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.fetchSavedOrders();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Tersimpan'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadSavedOrders();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildOrdersList(),
    );
  }

  Widget _buildOrdersList() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final savedOrders = orderProvider.savedOrders;

        if (savedOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Belum ada pesanan tersimpan',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Buat Pesanan Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: savedOrders.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final order = savedOrders[index];
            return _buildOrderCard(order, orderProvider);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Order order, OrderProvider orderProvider) {
    // Menentukan warna status
    Color statusColor;
    switch (order.status) {
      case 'saved':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Menentukan teks status
    String statusText;
    switch (order.status) {
      case 'saved':
        statusText = 'Tersimpan';
        break;
      case 'completed':
        statusText = 'Selesai';
        break;
      case 'cancelled':
        statusText = 'Dibatalkan';
        break;
      default:
        statusText = 'Tidak Diketahui';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header pesanan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _lightColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dibuat: ${_formatDate(order.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Informasi pesanan
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Jumlah item
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jumlah Item:'),
                    Text(
                      '${order.totalItems}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text(
                      '${FormatUtils.formatCurrency(order.subtotal.toInt())}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Pajak
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pajak:'),
                    Text(
                      '${FormatUtils.formatCurrency(order.tax.toInt())}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
                    ),
                    Text(
                      '${FormatUtils.formatCurrency(order.total.toInt())}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tombol aksi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Tombol detail
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showOrderDetails(order);
                    },
                    icon: const Icon(Icons.receipt, size: 16),
                    label: const Text('Detail'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: BorderSide(color: _primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Tombol edit jika status masih tersimpan
                if (order.status == 'saved')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _editOrder(order, orderProvider);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                
                // Tombol checkout jika status masih tersimpan
                if (order.status == 'saved')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _checkoutOrder(order, orderProvider);
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Selesai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                
                // Tombol hapus
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _confirmDeleteOrder(order, orderProvider);
                  },
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Menampilkan dialog detail pesanan
  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Pesanan ${order.orderNumber}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Tanggal pembuatan
              ListTile(
                title: const Text('Tanggal Pembuatan'),
                subtitle: Text(_formatDate(order.createdAt)),
                leading: const Icon(Icons.calendar_today),
              ),
              const Divider(),
              
              // Daftar item
              const ListTile(
                title: Text('Daftar Item'),
                leading: Icon(Icons.shopping_cart),
              ),
              ...order.items.map((item) => ListTile(
                title: Text(item.productName),
                subtitle: Text('${item.quantity} x ${FormatUtils.formatCurrency(item.price)}'),
                trailing: Text('${FormatUtils.formatCurrency(item.total)}'),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(item.icon, size: 16, color: _primaryColor),
                ),
              )),
              const Divider(),
              
              // Informasi total
              ListTile(
                title: const Text('Subtotal'),
                trailing: Text('${FormatUtils.formatCurrency(order.subtotal.toInt())}'),
              ),
              ListTile(
                title: const Text('Pajak'),
                trailing: Text('${FormatUtils.formatCurrency(order.tax.toInt())}'),
              ),
              ListTile(
                title: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                trailing: Text(
                  '${FormatUtils.formatCurrency(order.total.toInt())}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // Konfirmasi hapus pesanan
  void _confirmDeleteOrder(Order order, OrderProvider orderProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pesanan'),
        content: Text('Apakah Anda yakin ingin menghapus pesanan ${order.orderNumber}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await orderProvider.deleteOrder(order.orderNumber);
              if (orderProvider.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(orderProvider.error!)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pesanan berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Checkout pesanan
  void _checkoutOrder(Order order, OrderProvider orderProvider) async {
    // Ubah status pesanan menjadi 'completed'
    final result = await orderProvider.updateOrderStatus(order.orderNumber, 'completed');
    
    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan ${order.orderNumber} berhasil di-checkout'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Gagal melakukan checkout pesanan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Format tanggal
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  // Edit pesanan
  void _editOrder(Order order, OrderProvider orderProvider) async {
    // Navigasi ke halaman POS dengan membawa data order untuk diedit
    final result = await Navigator.pushNamed(
      context, 
      '/pos',
      arguments: {
        'edit_mode': true,
        'order': order,
      },
    );
    
    // Refresh daftar pesanan setelah kembali dari halaman POS
    if (result == true) {
      setState(() {
        _isLoading = true;
      });
      _loadSavedOrders();
    }
  }
}