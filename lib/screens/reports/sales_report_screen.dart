import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/format_utils.dart';
import '../../widgets/loading_indicator.dart';

class SalesReportScreen extends StatefulWidget {
  static const String routeName = '/reports/sales';

  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  _SalesReportScreenState createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSalesReport();
  }

  Future<void> _fetchSalesReport() async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<TransactionProvider>(context, listen: false);
    await provider.fetchTransactions(
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate),
      status: _selectedStatus,
    );

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchSalesReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Pilih Rentang Tanggal',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (_isLoading || provider.isLoading) {
          return const Center(child: LoadingIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${provider.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchSalesReport,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final transactions = provider.transactions;
        if (transactions.isEmpty) {
          return const Center(child: Text('Tidak ada data transaksi'));
        }

        return Column(
          children: [
            _buildDateRangeInfo(),
            _buildSummaryCards(transactions),
            Expanded(
              child: _buildTransactionList(transactions),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateRangeInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_selectedStatus != null)
            Chip(
              label: Text(_selectedStatus!),
              onDeleted: () {
                setState(() {
                  _selectedStatus = null;
                });
                _fetchSalesReport();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> transactions) {
    // Hitung total penjualan
    int totalSales = 0;
    for (var transaction in transactions) {
      totalSales += FormatUtils.safeParseInt(transaction['total_amount']);
    }

    // Hitung transaksi per status
    Map<String, int> statusCounts = {};
    for (var transaction in transactions) {
      final status = transaction['status'] ?? 'unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Penjualan',
                  FormatUtils.formatCurrency(totalSales),
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Jumlah Transaksi',
                  transactions.length.toString(),
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Rata-rata Transaksi',
                  transactions.isEmpty
                      ? 'Rp 0'
                      : FormatUtils.formatCurrency(totalSales ~/ transactions.length),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final status = transaction['status'] ?? 'unknown';
          final date = transaction['created_at'] != null
              ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(transaction['created_at']))
              : 'Tanggal tidak tersedia';

          return ListTile(
            title: Text('Invoice #${transaction['invoice_number'] ?? 'N/A'}'),
            subtitle: Text('$date - ${transaction['customer_name'] ?? 'Pelanggan Umum'}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FormatUtils.formatCurrency(FormatUtils.safeParseInt(transaction['total_amount'])),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _buildStatusChip(status),
              ],
            ),
            onTap: () {
              // Navigate to transaction detail
              Navigator.pushNamed(
                context,
                '/transactions/${transaction['id']}',
                arguments: transaction['id'],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempStatus = _selectedStatus;
        return AlertDialog(
          title: const Text('Filter Laporan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Status Transaksi'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: tempStatus,
                hint: const Text('Semua Status'),
                items: const [
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  tempStatus = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = tempStatus;
                });
                Navigator.pop(context);
                _fetchSalesReport();
              },
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );
  }
}