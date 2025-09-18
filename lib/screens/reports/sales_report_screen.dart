import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/loading_indicator.dart';
import '../transaction_detail_screen.dart';

// Theme colors - menggunakan warna dari ApiConfig

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dompet Kasir - POS | Laporan Penjualan',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (_isLoading || provider.isLoading) {
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
                  'Memuat laporan penjualan...',
                  style: TextStyle(
                    color: ApiConfig.textColor.withOpacity(0.7),
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.error != null) {
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
                  'Error: ${provider.error}',
                  style: TextStyle(
                    color: ApiConfig.textColor.withOpacity(0.7),
                    fontSize: isMobile ? 14 : 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _fetchSalesReport,
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

        final transactions = provider.transactions;
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assessment_outlined,
                  size: 80,
                  color: ApiConfig.textColor.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada data transaksi',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: ApiConfig.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada transaksi pada periode yang dipilih',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 16),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                      ApiConfig.primaryColor,
                      ApiConfig.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.date_range,
                  color: ApiConfig.backgroundColor,
                  size: isMobile ? 18 : 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Periode Laporan',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: ApiConfig.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Date range display
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ApiConfig.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: ApiConfig.primaryColor,
                  size: isMobile ? 20 : 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dari: ${DateFormat('dd MMM yyyy').format(_startDate)}',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: ApiConfig.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sampai: ${DateFormat('dd MMM yyyy').format(_endDate)}',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: ApiConfig.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: ApiConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.edit_calendar,
                      color: ApiConfig.primaryColor,
                      size: isMobile ? 20 : 24,
                    ),
                    onPressed: () => _selectDateRange(context),
                    tooltip: 'Ubah Periode',
                  ),
                ),
              ],
            ),
          ),
          
          // Status filter chip
          if (_selectedStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: ApiConfig.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_alt,
                    size: isMobile ? 14 : 16,
                    color: ApiConfig.backgroundColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Status: $_selectedStatus',
                    style: TextStyle(
                      color: ApiConfig.backgroundColor,
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStatus = null;
                      });
                      _fetchSalesReport();
                    },
                    child: Icon(
                      Icons.close,
                      size: isMobile ? 14 : 16,
                      color: ApiConfig.backgroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(
                  transactionId: transaction['id'] ?? 0,
                ),
              ),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(
                  transactionId: transaction['id'] ?? 0,
                ),
              ),
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