import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_helper.dart';
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
        backgroundColor: const Color(0xFF1E2A78),
        foregroundColor: Colors.white,
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

        // Menggunakan SingleChildScrollView untuk memungkinkan scrolling
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildDateRangeInfo(),
              _buildSummaryCards(transactions),
              _buildTransactionList(transactions),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRangeInfo() {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (_selectedStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Chip(
                      label: Text(_selectedStatus!),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                      onDeleted: () {
                        // Use Future.microtask to avoid setState during build
                        Future.microtask(() {
                          setState(() {
                            _selectedStatus = null;
                          });
                          _fetchSalesReport();
                        });
                      },
                    ),
                  ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (_selectedStatus != null)
                  Chip(
                    label: Text(_selectedStatus!),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                    onDeleted: () {
                      // Use Future.microtask to avoid setState during build
                      Future.microtask(() {
                        setState(() {
                          _selectedStatus = null;
                        });
                        _fetchSalesReport();
                      });
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
    
    // Hitung persentase status
    final completedCount = statusCounts['completed'] ?? 0;
    final pendingCount = statusCounts['pending'] ?? 0;
    final cancelledCount = statusCounts['cancelled'] ?? 0;
    final totalCount = transactions.length;
    
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Ringkasan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                onPressed: _fetchSalesReport,
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          const SizedBox(height: 16),
          isMobile
              ? Column(
                  children: [
                    _buildSummaryCard(
                      'Total Penjualan',
                      FormatUtils.formatCurrency(totalSales),
                      Icons.attach_money,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      'Jumlah Transaksi',
                      transactions.length.toString(),
                      Icons.receipt_long,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      'Rata-rata Transaksi',
                      transactions.isEmpty
                          ? 'Rp 0'
                          : FormatUtils.formatCurrency(totalSales ~/ transactions.length),
                      Icons.trending_up,
                      Colors.orange,
                    ),
                  ],
                )
              : Row(
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
          
          // Status distribution section
          if (totalCount > 0) ...[  
            const SizedBox(height: 24),
            const Text(
              'Distribusi Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  if (completedCount > 0)
                    Expanded(
                      flex: completedCount,
                      child: Container(
                        color: Colors.green,
                        child: Center(
                          child: Text(
                            '${(completedCount / totalCount * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  if (pendingCount > 0)
                    Expanded(
                      flex: pendingCount,
                      child: Container(
                        color: Colors.orange,
                        child: Center(
                          child: Text(
                            '${(pendingCount / totalCount * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  if (cancelledCount > 0)
                    Expanded(
                      flex: cancelledCount,
                      child: Container(
                        color: Colors.red,
                        child: Center(
                          child: Text(
                            '${(cancelledCount / totalCount * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                _buildLegendItem('Completed', Colors.green, completedCount),
                _buildLegendItem('Pending', Colors.orange, pendingCount),
                _buildLegendItem('Cancelled', Colors.red, cancelledCount),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text('$label ($count)'),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withOpacity(0.1),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Daftar Transaksi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Search field could be added here in future updates
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            height: screenHeight * 0.5, // Tinggi tetap berdasarkan tinggi layar
            child: isMobile
                ? _buildMobileTransactionList(transactions)
                : _buildDesktopTransactionList(transactions),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTransactionList(List<Map<String, dynamic>> transactions) {
    return ListView.separated(
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final status = transaction['status'] ?? 'unknown';
        final date = transaction['created_at'] != null
            ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(transaction['created_at']))
            : 'Tanggal tidak tersedia';

        return InkWell(
          onTap: () {
            // Navigate to transaction detail
            Navigator.pushNamed(
              context,
              '/transactions/${transaction['id']}',
              arguments: transaction['id'],
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Invoice #${transaction['invoice_number'] ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        transaction['customer_name'] ?? 'Pelanggan Umum',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  FormatUtils.formatCurrency(FormatUtils.safeParseInt(transaction['total_amount'])),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTransactionList(List<Map<String, dynamic>> transactions) {
    return ListView.separated(
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final status = transaction['status'] ?? 'unknown';
        final date = transaction['created_at'] != null
            ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(transaction['created_at']))
            : 'Tanggal tidak tersedia';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          title: Text(
            'Invoice #${transaction['invoice_number'] ?? 'N/A'}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    transaction['customer_name'] ?? 'Pelanggan Umum',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          trailing: SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
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
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
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
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    String label;
    
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Selesai';
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.access_time;
        label = 'Pending';
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Dibatalkan';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? tempStatus = _selectedStatus;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Filter Laporan'),
                ],
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Transaksi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: tempStatus,
                        hint: const Text('Semua Status'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Semua Status')),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                const Text('Selesai'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                const Text('Pending'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Row(
                              children: [
                                const Icon(Icons.cancel, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                const Text('Dibatalkan'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            tempStatus = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedStatus = tempStatus;
                    });
                    Navigator.pop(dialogContext);
                    _fetchSalesReport();
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}