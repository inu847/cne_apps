import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/format_utils.dart';
import '../../widgets/loading_indicator.dart';
import '../../config/api_config.dart';

// Theme colors - menggunakan warna dari ApiConfig

class DailyRecapScreen extends StatefulWidget {
  static const String routeName = '/reports/daily-recap';

  const DailyRecapScreen({Key? key}) : super(key: key);

  @override
  _DailyRecapScreenState createState() => _DailyRecapScreenState();
}

class _DailyRecapScreenState extends State<DailyRecapScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedWarehouseId;
  int? _selectedPettyCashId;
  bool _isInitialized = false;
  bool _isShowingDetails = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Gunakan Future.microtask untuk menghindari setState selama build
      Future.microtask(() => _fetchDailyRecap());
      _isInitialized = true;
    }
  }

  Future<void> _fetchDailyRecap() async {
    try {
      print('Fetching daily recap...');
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      await provider.fetchDailyRecap(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        warehouseId: _selectedWarehouseId,
      );
      print('Daily recap data fetched successfully');
      
      // Reset detail view when fetching new daily recap data
      setState(() {
        _isShowingDetails = false;
        _selectedPettyCashId = null;
      });
    } catch (e) {
      print('Error fetching daily recap data: $e');
    }
  }
  
  Future<void> _fetchDailyRecapDetails({int? pettyCashId}) async {
    try {
      print('Fetching daily recap details with pettyCashId: $pettyCashId');
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final success = await provider.fetchDailyRecapDetails(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        warehouseId: _selectedWarehouseId,
        pettyCashId: pettyCashId,
      );
      
      if (success) {
        setState(() {
          _isShowingDetails = true;
          _selectedPettyCashId = pettyCashId;
        });
        print('Daily recap details fetched successfully');
      } else {
        print('Failed to fetch daily recap details');
      }
    } catch (e) {
      print('Error fetching daily recap details: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchDailyRecap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isShowingDetails ? 'Detail Rekapitulasi Harian' : 'Rekapitulasi Harian',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ApiConfig.backgroundColor,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        leading: _isShowingDetails
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isShowingDetails = false;
                    _selectedPettyCashId = null;
                  });
                },
              )
            : null,
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
            onPressed: () => _selectDate(context),
            tooltip: 'Pilih Tanggal',
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          // Tampilkan loading indicator jika sedang memuat data
          if (_isShowingDetails) {
            if (provider.isLoadingDailyRecapDetails) {
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
                      'Memuat detail rekapitulasi...',
                      style: TextStyle(
                        color: ApiConfig.textColor.withOpacity(0.7),
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              );
            }
          } else {
            if (provider.isLoadingDailyRecap) {
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
                      'Memuat rekapitulasi harian...',
                      style: TextStyle(
                        color: ApiConfig.textColor.withOpacity(0.7),
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              );
            }
          }

          // Tampilkan pesan error jika ada
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
                    onPressed: _isShowingDetails ? () => _fetchDailyRecapDetails(pettyCashId: _selectedPettyCashId) : _fetchDailyRecap,
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

          // Tampilkan detail rekapitulasi harian jika _isShowingDetails true
          if (_isShowingDetails) {
            final detailsData = provider.dailyRecapDetailsData;
            if (detailsData == null) {
              print('Daily recap details data is null');
              return const Center(child: Text('Tidak ada data detail rekapitulasi'));
            }
            
            return _buildDailyRecapDetailsView(detailsData);
          }
          
          // Tampilkan rekapitulasi harian biasa
          final recapData = provider.dailyRecapData;
          if (recapData == null) {
            print('Recap data is null');
            return const Center(child: Text('Tidak ada data rekapitulasi'));
          }
          
          print('DailyRecapScreen: recapData type: ${recapData.runtimeType}');
          print('DailyRecapScreen: recapData keys: ${recapData.keys}');
          
          // Periksa apakah kunci yang dibutuhkan ada
          if (!recapData.containsKey('summary') || 
              !recapData.containsKey('payment_methods') || 
              !recapData.containsKey('top_products') || 
              !recapData.containsKey('hourly_sales')) {
            print('DailyRecapScreen: Missing required keys in recapData');
            print('DailyRecapScreen: Available keys: ${recapData.keys}');
            return Center(child: Text('Data rekapitulasi tidak lengkap'));
          }
          
          final summary = recapData['summary'];
          print('DailyRecapScreen: summary type: ${summary.runtimeType}');
          
          final paymentMethods = recapData['payment_methods'] is List 
              ? List<Map<String, dynamic>>.from(recapData['payment_methods'])
              : <Map<String, dynamic>>[];
          print('DailyRecapScreen: paymentMethods length: ${paymentMethods.length}');
          
          final topProducts = recapData['top_products'] is List 
              ? List<Map<String, dynamic>>.from(recapData['top_products'])
              : <Map<String, dynamic>>[];
          print('DailyRecapScreen: topProducts length: ${topProducts.length}');
          
          final hourlySales = recapData['hourly_sales'];
          print('DailyRecapScreen: hourlySales type: ${hourlySales.runtimeType}');

          // Ekstrak data Petty Cash dan transaksi dari recapData
          final pettyCashWithoutTransactions = recapData.containsKey('petty_cash_without_transactions') 
              ? List<Map<String, dynamic>>.from(recapData['petty_cash_without_transactions'])
              : <Map<String, dynamic>>[];
          print('DailyRecapScreen: pettyCashWithoutTransactions length: ${pettyCashWithoutTransactions.length}');
          
          final transactionsWithPettyCash = recapData.containsKey('transactions_with_petty_cash') 
              ? List<Map<String, dynamic>>.from(recapData['transactions_with_petty_cash'])
              : <Map<String, dynamic>>[];
          print('DailyRecapScreen: transactionsWithPettyCash length: ${transactionsWithPettyCash.length}');
          
          final transactionsWithoutPettyCash = recapData.containsKey('transactions_without_petty_cash') 
              ? recapData['transactions_without_petty_cash'] as Map<String, dynamic>
              : <String, dynamic>{};
          print('DailyRecapScreen: transactionsWithoutPettyCash: $transactionsWithoutPettyCash');
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateAndWarehouseInfo(recapData),
                const SizedBox(height: 24),
                _buildSummaryCards(summary),
                const SizedBox(height: 24),
                _buildSectionTitle('Metode Pembayaran'),
                _buildPaymentMethodsChart(paymentMethods),
                const SizedBox(height: 24),
                _buildSectionTitle('Produk Terlaris'),
                _buildTopProductsList(topProducts),
                const SizedBox(height: 24),
                _buildSectionTitle('Penjualan per Jam'),
                _buildHourlySalesChart(hourlySales),
                const SizedBox(height: 24),
                _buildSectionTitle('Petty Cash Tanpa Transaksi'),
                _buildPettyCashWithoutTransactionsList(pettyCashWithoutTransactions),
                const SizedBox(height: 24),
                _buildSectionTitle('Transaksi dengan Petty Cash'),
                _buildTransactionsWithPettyCashList(transactionsWithPettyCash),
                const SizedBox(height: 24),
                _buildSectionTitle('Transaksi Tanpa Petty Cash'),
                _buildTransactionsWithoutPettyCashSummary(transactionsWithoutPettyCash),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateAndWarehouseInfo(Map<String, dynamic> recapData) {
    print('DailyRecapScreen: Building date and warehouse info');
    print('DailyRecapScreen: recapData contains warehouse key: ${recapData.containsKey('warehouse')}');
    
    String warehouseName = 'Tidak diketahui';
    
    if (recapData.containsKey('warehouse')) {
      final warehouse = recapData['warehouse'];
      print('DailyRecapScreen: warehouse type: ${warehouse.runtimeType}');
      
      if (warehouse is Map && warehouse.containsKey('name')) {
        warehouseName = warehouse['name'];
      } else {
        print('DailyRecapScreen: warehouse does not contain name key or is not a Map');
      }
    } else {
      print('DailyRecapScreen: warehouse key not found in recapData');
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tanggal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Gudang',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(warehouseName),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    print('DailyRecapScreen: Building summary cards with data: $summary');
    
    // Periksa apakah semua kunci yang dibutuhkan ada
    final requiredKeys = [
      'total_sales', 'total_transactions', 'average_transaction',
      'total_items_sold', 'total_profit', 'profit_margin'
    ];
    
    for (final key in requiredKeys) {
      if (!summary.containsKey(key)) {
        print('DailyRecapScreen: Missing key in summary: $key');
      }
    }
    
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(
          'Total Penjualan',
          summary.containsKey('total_sales') 
              ? FormatUtils.formatCurrency(summary['total_sales'])
              : 'N/A',
          Icons.attach_money,
          Colors.green,
        ),
        _buildSummaryCard(
          'Jumlah Transaksi',
          summary.containsKey('total_transactions') 
              ? summary['total_transactions'].toString()
              : 'N/A',
          Icons.receipt_long,
          Colors.blue,
        ),
        _buildSummaryCard(
          'Rata-rata Transaksi',
          summary.containsKey('average_transaction') 
              ? FormatUtils.formatCurrency(summary['average_transaction'])
              : 'N/A',
          Icons.trending_up,
          Colors.orange,
        ),
        _buildSummaryCard(
          'Item Terjual',
          summary.containsKey('total_items_sold') 
              ? summary['total_items_sold'].toString()
              : 'N/A',
          Icons.shopping_cart,
          Colors.purple,
        ),
        _buildSummaryCard(
          'Total Profit',
          summary.containsKey('total_profit') 
              ? FormatUtils.formatCurrency(summary['total_profit'])
              : 'N/A',
          Icons.savings,
          Colors.teal,
        ),
        _buildSummaryCard(
          'Margin Profit',
          summary.containsKey('profit_margin') 
              ? '${summary['profit_margin']}%'
              : 'N/A',
          Icons.pie_chart,
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPaymentMethodsChart(List<Map<String, dynamic>> paymentMethods) {
    print('DailyRecapScreen: Building payment methods chart with ${paymentMethods.length} methods');
    
    if (paymentMethods.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Tidak ada data metode pembayaran')),
        ),
      );
    }
    
    // Validasi data metode pembayaran
    bool isValidData = true;
    for (var method in paymentMethods) {
      if (!method.containsKey('method') || !method.containsKey('total') || !method.containsKey('percentage')) {
        print('DailyRecapScreen: Invalid payment method data: $method');
        print('DailyRecapScreen: Missing keys: ${['method', 'total', 'percentage'].where((key) => !method.containsKey(key)).toList()}');
        isValidData = false;
        break;
      }
    }
    
    if (!isValidData) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Data metode pembayaran tidak valid')),
        ),
      );
    }
    
    return SizedBox(
      height: 300,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sections: paymentMethods.map((method) {
                      final color = _getColorForPaymentMethod(method['method']);
                      final double percentage = method['percentage'] is num 
                          ? method['percentage'].toDouble() 
                          : double.tryParse(method['percentage'].toString()) ?? 0.0;
                      
                      print('DailyRecapScreen: Payment method ${method['method']}: ${method['total']} ($percentage%)');
                      
                      return PieChartSectionData(
                        color: color,
                        value: percentage,
                        title: '$percentage%',
                        radius: 100,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: paymentMethods.map((method) {
                    final color = _getColorForPaymentMethod(method['method']);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            color: color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              method['method']?.toString() ?? 'Tidak diketahui',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            FormatUtils.formatCurrency(method['total']),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'transfer':
        return Colors.blue;
      case 'qris':
        return Colors.orange;
      case 'credit card':
        return Colors.red;
      case 'debit card':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTopProductsList(List<Map<String, dynamic>> topProducts) {
    print('DailyRecapScreen: Building top products list with ${topProducts.length} products');
    
    if (topProducts.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Tidak ada data produk terlaris')),
        ),
      );
    }
    
    // Validasi data produk terlaris
    bool isValidData = true;
    for (var product in topProducts) {
      if (!product.containsKey('name') || !product.containsKey('quantity_sold') || !product.containsKey('total_sales')) {
        print('DailyRecapScreen: Invalid product data: $product');
        print('DailyRecapScreen: Missing keys: ${['name', 'quantity_sold', 'total_sales'].where((key) => !product.containsKey(key)).toList()}');
        isValidData = false;
        break;
      }
    }
    
    if (!isValidData) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Data produk terlaris tidak valid')),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: topProducts.map((product) {
            final name = product['name']?.toString() ?? 'Produk tidak diketahui';
            final quantitySold = product['quantity_sold'] is num 
                ? product['quantity_sold'].toString() 
                : product['quantity_sold']?.toString() ?? '0';
            final totalSales = product['total_sales'];
            
            print('DailyRecapScreen: Product $name: sold $quantitySold units, total sales: $totalSales');
            
            return ListTile(
              title: Text(name),
              subtitle: Text('Terjual: $quantitySold unit'),
              trailing: Text(
                FormatUtils.formatCurrency(totalSales),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHourlySalesChart(Map<String, dynamic> hourlySales) {
    print('DailyRecapScreen: Building hourly sales chart');
    print('DailyRecapScreen: hourlySales keys: ${hourlySales.keys}');
    
    // Validasi data penjualan per jam
    if (!hourlySales.containsKey('labels') || !hourlySales.containsKey('data')) {
      print('DailyRecapScreen: Missing required keys in hourlySales');
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Data penjualan per jam tidak lengkap')),
        ),
      );
    }
    
    List<String> labels;
    List<double> data;
    
    try {
      labels = hourlySales['labels'] is List 
          ? List<String>.from(hourlySales['labels']) 
          : [];
      
      data = hourlySales['data'] is List 
          ? List<double>.from(hourlySales['data'].map((value) => 
              value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0)) 
          : [];
      
      print('DailyRecapScreen: labels length: ${labels.length}, data length: ${data.length}');
      
      if (labels.isEmpty || data.isEmpty) {
        return const Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('Tidak ada data penjualan per jam')),
          ),
        );
      }
    } catch (e) {
      print('DailyRecapScreen: Error parsing hourly sales data: $e');
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(child: Text('Error: $e')),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        FormatUtils.formatCurrency(value.toInt(), showSymbol: false),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            labels[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value);
                  }).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPettyCashWithoutTransactionsList(List<Map<String, dynamic>> pettyCashList) {
    print('DailyRecapScreen: Building petty cash without transactions list with ${pettyCashList.length} items');
    
    if (pettyCashList.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Tidak ada data kas kecil tanpa transaksi')),
        ),
      );
    }
    
    // Validasi data kas kecil
    bool isValidData = true;
    for (var pettyCash in pettyCashList) {
      if (!pettyCash.containsKey('name') || !pettyCash.containsKey('amount') || !pettyCash.containsKey('user')) {
        print('DailyRecapScreen: Invalid petty cash data: $pettyCash');
        print('DailyRecapScreen: Missing keys: ${['name', 'amount', 'user'].where((key) => !pettyCash.containsKey(key)).toList()}');
        isValidData = false;
        break;
      }
    }
    
    if (!isValidData) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Data kas kecil tidak valid')),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: pettyCashList.map((pettyCash) {
            final name = pettyCash['name']?.toString() ?? 'Kas kecil tidak diketahui';
            final amount = pettyCash['amount'];
            final user = pettyCash['user'] is Map ? pettyCash['user']['name']?.toString() ?? 'Pengguna tidak diketahui' : 'Pengguna tidak diketahui';
            final date = pettyCash['date']?.toString() ?? '-';
            final id = pettyCash['id'];
            
            print('DailyRecapScreen: Petty cash $name: amount $amount, user: $user, date: $date, id: $id');
            
            return ListTile(
              title: Text(name),
              subtitle: Text('Oleh: $user | Tanggal: $date'),
              trailing: Text(
                FormatUtils.formatCurrency(amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                if (id != null) {
                  _fetchDailyRecapDetails(pettyCashId: id);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildTransactionsWithPettyCashList(List<Map<String, dynamic>> transactionsList) {
    print('DailyRecapScreen: Building transactions with petty cash list with ${transactionsList.length} items');
    
    if (transactionsList.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Tidak ada data transaksi dengan kas kecil')),
        ),
      );
    }
    
    // Validasi data transaksi dengan kas kecil
    bool isValidData = true;
    for (var transaction in transactionsList) {
      if (!transaction.containsKey('petty_cash_name') || 
          !transaction.containsKey('user_name') || 
          !transaction.containsKey('transaction_count') || 
          !transaction.containsKey('total_amount')) {
        print('DailyRecapScreen: Invalid transaction with petty cash data: $transaction');
        print('DailyRecapScreen: Missing keys: ${['petty_cash_name', 'user_name', 'transaction_count', 'total_amount'].where((key) => !transaction.containsKey(key)).toList()}');
        isValidData = false;
        break;
      }
    }
    
    if (!isValidData) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Data transaksi dengan kas kecil tidak valid')),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: transactionsList.map((transaction) {
            final pettyCashName = transaction['petty_cash_name']?.toString() ?? 'Kas kecil tidak diketahui';
            final userName = transaction['user_name']?.toString() ?? 'Pengguna tidak diketahui';
            final transactionCount = transaction['transaction_count'] is num 
                ? transaction['transaction_count'].toString() 
                : transaction['transaction_count']?.toString() ?? '0';
            final totalAmount = transaction['total_amount'];
            final pettyCashId = transaction['petty_cash_id'];
            
            print('DailyRecapScreen: Transaction with petty cash $pettyCashName: count $transactionCount, total: $totalAmount, user: $userName, id: $pettyCashId');
            
            return ListTile(
              title: Text(pettyCashName),
              subtitle: Text('Oleh: $userName | Jumlah Transaksi: $transactionCount'),
              trailing: Text(
                FormatUtils.formatCurrency(totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                if (pettyCashId != null) {
                  _fetchDailyRecapDetails(pettyCashId: pettyCashId);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildTransactionsWithoutPettyCashSummary(Map<String, dynamic> transactionsData) {
    print('DailyRecapScreen: Building transactions without petty cash summary');
    print('DailyRecapScreen: transactionsData: $transactionsData');
    
    if (transactionsData.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Tidak ada data transaksi tanpa kas kecil')),
        ),
      );
    }
    
    // Validasi data transaksi tanpa kas kecil
    if (!transactionsData.containsKey('transaction_count') || !transactionsData.containsKey('total_amount')) {
      print('DailyRecapScreen: Invalid transactions without petty cash data');
      print('DailyRecapScreen: Missing keys: ${['transaction_count', 'total_amount'].where((key) => !transactionsData.containsKey(key)).toList()}');
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Data transaksi tanpa kas kecil tidak valid')),
        ),
      );
    }
    
    final transactionCount = transactionsData['transaction_count'] is num 
        ? transactionsData['transaction_count'].toString() 
        : transactionsData['transaction_count']?.toString() ?? '0';
    final totalAmount = transactionsData['total_amount'];
    
    print('DailyRecapScreen: Transactions without petty cash: count $transactionCount, total: $totalAmount');
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Jumlah Transaksi'),
              trailing: Text(
                transactionCount,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Total Nilai Transaksi'),
              trailing: Text(
                FormatUtils.formatCurrency(totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ElevatedButton(
              onPressed: () {
                // Mengambil detail rekapitulasi tanpa petty cash (pettyCashId = null)
                _fetchDailyRecapDetails(pettyCashId: null);
              },
              child: const Text('Lihat Detail Transaksi'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDailyRecapDetailsView(Map<String, dynamic> detailsData) {
    print('DailyRecapScreen: Building daily recap details view');
    print('DailyRecapScreen: detailsData keys: ${detailsData.keys}');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailHeader(detailsData),
          const SizedBox(height: 24),
          _buildDetailSummary(detailsData),
          const SizedBox(height: 24),
          _buildSectionTitle('Metode Pembayaran'),
          _buildDetailPaymentMethods(detailsData),
          const SizedBox(height: 24),
          _buildSectionTitle('Daftar Transaksi'),
          _buildDetailTransactionsList(detailsData),
        ],
      ),
    );
  }
  
  Widget _buildDetailHeader(Map<String, dynamic> detailsData) {
    print('DailyRecapScreen: Building detail header');
    
    String warehouseName = 'Tidak diketahui';
    String pettyCashName = 'Tidak ada';
    String pettyCashAmount = '-';
    String userName = '-';
    
    if (detailsData.containsKey('warehouse') && detailsData['warehouse'] is Map) {
      final warehouse = detailsData['warehouse'] as Map;
      if (warehouse.containsKey('name')) {
        warehouseName = warehouse['name'];
      }
    }
    
    if (detailsData.containsKey('petty_cash') && detailsData['petty_cash'] is Map) {
      final pettyCash = detailsData['petty_cash'] as Map;
      if (pettyCash.containsKey('name')) {
        pettyCashName = pettyCash['name'];
      }
      if (pettyCash.containsKey('amount')) {
        pettyCashAmount = FormatUtils.formatCurrency(pettyCash['amount']);
      }
      if (pettyCash.containsKey('user') && pettyCash['user'] is Map) {
        final user = pettyCash['user'] as Map;
        if (user.containsKey('name')) {
          userName = user['name'];
        }
      }
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Gudang',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(warehouseName),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Informasi Kas Kecil',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nama Kas Kecil'),
                    Text(pettyCashName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Jumlah'),
                    Text(pettyCashAmount, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Penanggung Jawab: '),
                Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailSummary(Map<String, dynamic> detailsData) {
    print('DailyRecapScreen: Building detail summary');
    
    if (!detailsData.containsKey('summary') || !(detailsData['summary'] is Map)) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Tidak ada data ringkasan')),
        ),
      );
    }
    
    final summary = detailsData['summary'] as Map;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Penjualan'),
                Text(
                  summary.containsKey('total_amount') 
                      ? FormatUtils.formatCurrency(summary['total_amount'])
                      : 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pajak'),
                Text(
                  summary.containsKey('tax_amount') 
                      ? FormatUtils.formatCurrency(summary['tax_amount'])
                      : 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Diskon'),
                Text(
                  summary.containsKey('discount_amount') 
                      ? FormatUtils.formatCurrency(summary['discount_amount'])
                      : 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profit'),
                Text(
                  summary.containsKey('profit') 
                      ? FormatUtils.formatCurrency(summary['profit'])
                      : 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Item Terjual'),
                Text(
                  summary.containsKey('items_sold') 
                      ? summary['items_sold'].toString()
                      : 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailPaymentMethods(Map<String, dynamic> detailsData) {
    print('DailyRecapScreen: Building detail payment methods');
    
    if (!detailsData.containsKey('payment_methods') || !(detailsData['payment_methods'] is List)) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Tidak ada data metode pembayaran')),
        ),
      );
    }
    
    final paymentMethods = List<Map<String, dynamic>>.from(detailsData['payment_methods']);
    
    if (paymentMethods.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Tidak ada data metode pembayaran')),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...paymentMethods.map((method) {
              final methodName = method['method']?.toString() ?? 'Tidak diketahui';
              final total = method['total'];
              final percentage = method['percentage'];
              
              return ListTile(
                title: Text(methodName),
                subtitle: Text('${percentage.toString()}%'),
                trailing: Text(
                  FormatUtils.formatCurrency(total),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailTransactionsList(Map<String, dynamic> detailsData) {
    print('DailyRecapScreen: Building detail transactions list');
    
    if (!detailsData.containsKey('transactions') || !(detailsData['transactions'] is List)) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Tidak ada data transaksi')),
        ),
      );
    }
    
    final transactions = List<Map<String, dynamic>>.from(detailsData['transactions']);
    
    if (transactions.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Tidak ada data transaksi')),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...transactions.map((transaction) {
              final invoiceNumber = transaction['invoice_number']?.toString() ?? 'Tidak diketahui';
              final customerName = transaction['customer_name']?.toString() ?? 'Tidak diketahui';
              final totalAmount = transaction['total_amount'];
              final paymentMethod = transaction['payment_method']?.toString() ?? 'Tidak diketahui';
              final createdAt = transaction['created_at']?.toString() ?? '-';
              
              // Format tanggal jika tersedia
              String formattedDate = '-';
              try {
                if (createdAt != '-') {
                  final dateTime = DateTime.parse(createdAt);
                  formattedDate = DateFormat('dd MMM yyyy HH:mm').format(dateTime);
                }
              } catch (e) {
                print('Error parsing date: $e');
                formattedDate = createdAt;
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(invoiceNumber),
                    subtitle: Text('$customerName - $paymentMethod'),
                    trailing: Text(
                      FormatUtils.formatCurrency(totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                    child: Text('Waktu: $formattedDate'),
                  ),
                  const Divider(),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}