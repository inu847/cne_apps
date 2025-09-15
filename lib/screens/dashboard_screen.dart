import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../models/sales_dashboard_model.dart';
import '../services/auth_service.dart';
import '../services/receipt_service.dart'; // Impor untuk navigatorKey
import '../services/sales_dashboard_service.dart';
import '../services/transaction_service.dart';
import '../screens/transactions_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/transaction_detail_screen.dart';
import '../widgets/sales_chart_widget.dart';
import '../widgets/sales_stat_card_widget.dart';
import '../utils/currency_formatter.dart';
import '../config/api_config.dart'; // Import untuk ApiConfig

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final SalesDashboardService _salesDashboardService = SalesDashboardService();
  final TransactionService _transactionService = TransactionService();
  int _selectedIndex = 0;
  
  // Color palette baru
  static const Color primaryGreen = Color(0xFF03D26F);
  static const Color lightBlue = Color(0xFFEAF4F4);
  static const Color darkBlack = Color(0xFF161514);
  
  // Data dashboard penjualan
  SalesDashboardData? _salesDashboardData;
  bool _isLoadingSalesData = false;
  String? _salesDataError;
  int _selectedPeriod = 30; // Default 30 hari
  
  void _onItemTapped(int index) {
    if (index == 1) { // POS menu
      Navigator.pushNamed(context, '/pos');
      return;
    } else if (index == 2) { // Inventory menu
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InventoryScreen(),
        ),
      );
      return;
    } else if (index == 3) { // Transactions menu
      Navigator.pushNamed(context, '/transactions');
      return;
    } else if (index == 4) { // Reports menu
      // Navigasi langsung ke halaman rekapitulasi harian
      print('Navigating to daily recap screen from bottom nav');
      navigatorKey.currentState?.pushNamed('/reports/daily-recap');
      return;
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  void initState() {
    super.initState();
    _fetchSalesDashboardData();
    _fetchRecentTransactions();
    _fetchTopProducts();
  }
  
  // Fungsi untuk mengambil data produk terlaris
  Future<void> _fetchTopProducts() async {
    setState(() {
      _isLoadingTopProducts = true;
      _topProductsError = null;
    });
    
    try {
      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _topProductsError = 'Tidak ada token autentikasi. Silakan login kembali.';
          _isLoadingTopProducts = false;
        });
        return;
      }
      
      // Membuat URL dengan query parameters
      final uri = Uri.parse('${ApiConfig.baseUrl}/transactions/top-selling-products');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print(response.statusCode);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null && responseData['data']['top_products'] != null) {
          final topProductsData = responseData['data']['top_products'] as List<dynamic>;
          
          setState(() {
            _topProducts = topProductsData.map((product) {
              // Format jumlah dengan Rupiah
              final totalSales = product['total_sales'];
              final numTotalSales = totalSales is String ? double.tryParse(totalSales) ?? 0 : (totalSales as num);
              final formattedRevenue = 'Rp ${NumberFormat('#,###', 'id_ID').format(numTotalSales)}';
              
              return {
                'id': product['id'],
                'name': product['name'],
                'sku': product['sku'],
                'sold': product['quantity_sold'],
                'revenue': formattedRevenue,
                'profit': product['profit'],
                'profit_margin': product['profit_margin'],
              };
            }).toList();
            _isLoadingTopProducts = false;
          });
        } else {
          setState(() {
            _topProductsError = responseData['message'] ?? 'Gagal memuat data produk terlaris';
            _isLoadingTopProducts = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _topProductsError = 'Sesi telah berakhir. Silakan login kembali.';
          _isLoadingTopProducts = false;
        });
        // Redirect ke halaman login
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        setState(() {
          _topProductsError = 'Gagal memuat data produk terlaris: ${response.statusCode}';
          _isLoadingTopProducts = false;
        });
      }
    } catch (e) {
      setState(() {
        _topProductsError = e.toString();
        _isLoadingTopProducts = false;
      });
    }
  }
  
  // Fungsi untuk mengambil data transaksi terbaru
  Future<void> _fetchRecentTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
      _transactionsError = null;
    });
    
    try {
      final result = await _transactionService.getTransactions(
        page: 1,
        perPage: 5, // Hanya ambil 5 transaksi terbaru
      );
      
      if (result['success'] == true && result['data'] != null) {
        final transactionsData = result['data']['transactions'] as List<dynamic>;
        
        setState(() {
          _recentTransactions = transactionsData.map((transaction) {
            // Format tanggal dari API (asumsi format ISO)
            final date = DateTime.parse(transaction['created_at']);
            final formattedDate = DateFormat('yyyy-MM-dd').format(date);
            
            // Format jumlah dengan Rupiah
            final amount = transaction['total_amount'] is String 
                ? double.tryParse(transaction['total_amount'].toString()) ?? 0 
                : transaction['total_amount'] as num;
            final formattedAmount = 'Rp ${NumberFormat('#,###', 'id_ID').format(amount)}';
            
            return {
              'id': transaction['invoice_number'] ?? 'INV-${transaction['id']}',
              'customer': transaction['customer_name'] ?? 'Pelanggan Umum',
              'date': formattedDate,
              'amount': formattedAmount,
              'status': transaction['status'] ?? 'Completed',
            };
          }).toList();
          _isLoadingTransactions = false;
        });
      } else {
        setState(() {
          _recentTransactions = [];
          _transactionsError = result['message'] ?? 'Gagal memuat data transaksi';
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      setState(() {
        _recentTransactions = [];
        _transactionsError = e.toString();
        _isLoadingTransactions = false;
      });
    }
  }
  
  // Fungsi untuk mengambil data dashboard penjualan
  Future<void> _fetchSalesDashboardData() async {
    setState(() {
      _isLoadingSalesData = true;
      _salesDataError = null;
    });
    
    try {
      final data = await _salesDashboardService.getDashboardData(period: _selectedPeriod);
      setState(() {
        _salesDashboardData = data as SalesDashboardData?;
        _isLoadingSalesData = false;
      });
    } catch (e) {
      setState(() {
        _salesDataError = e.toString();
        _isLoadingSalesData = false;
      });
    }
  }
  
  // Fungsi untuk mengubah periode dan memuat ulang data
  void _changePeriod(int days) {
    if (_selectedPeriod != days) {
      setState(() {
        _selectedPeriod = days;
      });
      _fetchSalesDashboardData();
    }
  }
  
  // Data transaksi terbaru dari API
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoadingTransactions = false;
  String? _transactionsError;
  
  // Data produk terlaris dari API
  List<Map<String, dynamic>> _topProducts = [];
  bool _isLoadingTopProducts = false;
  String? _topProductsError;

  // Menambahkan variabel untuk drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;
    final isMobile = screenWidth < 650;

    return Scaffold(
      key: _scaffoldKey,
      // AppBar hanya ditampilkan pada tablet dan mobile
      appBar: (isTablet || isMobile) ? AppBar(
        backgroundColor: lightBlue,
        elevation: 0,
        title: Text(
          _getPageTitle(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkBlack),
        ),
        leading: isTablet ? IconButton(
          icon: Icon(Icons.menu, color: primaryGreen),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ) : null,
        actions: [
          // Help icon
          IconButton(
            icon: Icon(Icons.help_outline, color: primaryGreen),
            onPressed: () {},
            tooltip: 'Help',
          ),
          // Notification icon
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: primaryGreen),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          // Logout icon
          IconButton(
            icon: Icon(Icons.logout, color: primaryGreen),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ) : null,
      
      // Drawer untuk tablet
      drawer: isTablet ? _buildSidebar() : null,
      
      // Bottom navigation untuk mobile
      bottomNavigationBar: isMobile ? BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: lightBlue,
        selectedItemColor: primaryGreen,
        unselectedItemColor: darkBlack.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),            activeIcon: Icon(Icons.point_of_sale),
            label: 'POS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_outlined),
            activeIcon: Icon(Icons.inventory),
            label: 'Persediaan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            activeIcon: Icon(Icons.receipt),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Reports',
          ),
        ],
      ) : null,
      
      // Body dengan layout responsif
      body: Row(
        children: [
          // Sidebar hanya ditampilkan pada desktop
          if (isDesktop) _buildSidebar(),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top app bar hanya untuk desktop
                if (isDesktop) Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    boxShadow: [
                      BoxShadow(
                        color: darkBlack.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Page title based on selected index
                      Text(
                        _getPageTitle(),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkBlack),
                      ),
                      const Spacer(),
                      // Search bar
                      Container(
                        width: 300,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryGreen.withOpacity(0.3)),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: Icon(Icons.search, color: primaryGreen),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            hintStyle: TextStyle(color: darkBlack.withOpacity(0.5)),
                          ),
                          style: TextStyle(color: darkBlack),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Help icon
                      IconButton(
                        icon: Icon(Icons.help_outline, color: primaryGreen),
                        onPressed: () {},
                        tooltip: 'Help',
                      ),
                      // Notification icon
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: primaryGreen),
                        onPressed: () {},
                        tooltip: 'Notifications',
                      ),
                      // Logout icon
                      IconButton(
                        icon: Icon(Icons.logout, color: primaryGreen),
                        onPressed: _logout,
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),
                
                // Main content area
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget untuk sidebar
  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: darkBlack, // Dark black color for sidebar
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/logo.png',
              height: 60,
              width: 120,
              fit: BoxFit.contain,
            ),
          ),
          Divider(color: primaryGreen.withOpacity(0.3), height: 1),
          
          // User profile section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryGreen,
                  radius: 24,
                  child: Text(
                    widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.user.email,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: primaryGreen.withOpacity(0.3), height: 1),
          
          // Navigation menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
                _buildNavItem(1, 'POS', Icons.point_of_sale_outlined, Icons.point_of_sale),
                _buildNavItem(2, 'Persediaan', Icons.inventory_outlined, Icons.inventory),
                _buildNavItem(3, 'Transactions', Icons.receipt_outlined, Icons.receipt),
                _buildNavItem(4, 'Reports', Icons.receipt_long_outlined, Icons.receipt_long),
                // _buildNavItem(5, 'Settings', Icons.settings_outlined, Icons.settings),
              ],
            ),
          ),
          
          // Logout button at bottom
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get page title based on selected index
  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Point of Sale';
      case 2: return 'Manajemen Persediaan';
      case 3: return 'Transactions';
      case 4: return 'Reports & Analytics';
      case 5: return 'Settings';
      default: return 'Dashboard';
    }
  }
  
  // Build navigation item for sidebar
  Widget _buildNavItem(int index, String title, IconData icon, IconData selectedIcon) {
    final bool isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (index == 1) { // POS menu
            Navigator.pushNamed(context, '/pos');
            return;
          } else if (index == 2) { // Inventory menu
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InventoryScreen(),
              ),
            );
            return;
          } else if (index == 3) { // Transactions menu
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TransactionsScreen(),
              ),
            );
            return;
          } else if (index == 4) { // Reports menu
            // Navigasi langsung ke halaman rekapitulasi harian
            print('Navigating to daily recap screen from sidebar');
            navigatorKey.currentState?.pushNamed('/reports/daily-recap');
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? primaryGreen.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(0),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              if (isSelected) ...[  
                const Spacer(),
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper to get color for transaction status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildMainContent() {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;
    final isMobile = screenWidth < 650;
    
    // Switch content based on selected index
    if (_selectedIndex != 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForIndex(_selectedIndex),
              size: isMobile ? 70 : 100,
              color: const Color(0xFF1E2A78).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              '${_getPageTitle()} Coming Soon',
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This feature is under development',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Dashboard content
    return Container(
      color: lightBlue,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message - responsif untuk mobile
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${widget.user.name}!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Here\'s what\'s happening with your store today',
                        style: TextStyle(
                          fontSize: 14,
                          color: darkBlack.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Date range picker
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryGreen.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedPeriod,
                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                            isExpanded: true,
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                _changePeriod(newValue);
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 7,
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18),
                                    SizedBox(width: 8),
                                    Text('7 Hari Terakhir'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 30,
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18),
                                    SizedBox(width: 8),
                                    Text('30 Hari Terakhir'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 90,
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18),
                                    SizedBox(width: 8),
                                    Text('90 Hari Terakhir'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${widget.user.name}!',
                              style: TextStyle(
                                fontSize: isTablet ? 22 : 24,
                                fontWeight: FontWeight.bold,
                                color: darkBlack,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Here\'s what\'s happening with your store today',
                              style: TextStyle(
                                fontSize: isTablet ? 15 : 16,
                                color: darkBlack.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Date range picker
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryGreen.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedPeriod,
                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                _changePeriod(newValue);
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 7,
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18),
                                    SizedBox(width: 8),
                                    Text('7 Hari Terakhir'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 30,
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18),
                                    SizedBox(width: 8),
                                    Text('30 Hari Terakhir'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 90,
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18),
                                    SizedBox(width: 8),
                                    Text('90 Hari Terakhir'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            
            // Stats cards - responsif untuk mobile
            _isLoadingSalesData
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: primaryGreen),
                    ),
                  )
                : _salesDataError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              const Text(
                                'Gagal memuat data penjualan',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(_salesDataError!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchSalesDashboardData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _salesDashboardData == null
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('Tidak ada data penjualan'),
                            ),
                          )
                        : isMobile
                            ? Column(
                                children: [
                                  SalesStatCardWidget(
                                    title: 'Total Penjualan',
                                    value: CurrencyFormatter.formatCurrency(_salesDashboardData!.currentPeriod.totalSales),
                                    icon: Icons.attach_money,
                                    color: primaryGreen,
                                    changePercentage: _salesDashboardData!.comparison.totalSalesChange,
                                    isCurrency: true,
                                  ),
                                  const SizedBox(height: 16),
                                  SalesStatCardWidget(
                                    title: 'Jumlah Transaksi',
                                    value: CurrencyFormatter.formatNumber(_salesDashboardData!.currentPeriod.transactionCount.toDouble()),
                                    icon: Icons.receipt_long,
                                    color: primaryGreen,
                                    changePercentage: _salesDashboardData!.comparison.transactionCountChange,
                                  ),
                                  const SizedBox(height: 16),
                                  SalesStatCardWidget(
                                    title: 'Rata-rata Transaksi',
                                    value: CurrencyFormatter.formatCurrency(_salesDashboardData!.currentPeriod.averageTransactionValue),
                                    icon: Icons.trending_up,
                                    color: primaryGreen,
                                    changePercentage: _salesDashboardData!.comparison.averageTransactionValueChange,
                                    isCurrency: true,
                                  ),
                                  const SizedBox(height: 16),
                                  SalesStatCardWidget(
                                    title: 'Total Profit',
                                    value: CurrencyFormatter.formatCurrency(_salesDashboardData!.currentPeriod.totalProfit),
                                    icon: Icons.account_balance_wallet,
                                    color: primaryGreen,
                                    changePercentage: _salesDashboardData!.comparison.profitChange,
                                    isCurrency: true,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: SalesStatCardWidget(
                                      title: 'Total Penjualan',
                                      value: CurrencyFormatter.formatCurrency(_salesDashboardData!.currentPeriod.totalSales),
                                      icon: Icons.attach_money,
                                      color: primaryGreen,
                                      changePercentage: _salesDashboardData!.comparison.totalSalesChange,
                                      isCurrency: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SalesStatCardWidget(
                                      title: 'Jumlah Transaksi',
                                      value: CurrencyFormatter.formatNumber(_salesDashboardData!.currentPeriod.transactionCount.toDouble()),
                                      icon: Icons.receipt_long,
                                      color: primaryGreen,
                                      changePercentage: _salesDashboardData!.comparison.transactionCountChange,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SalesStatCardWidget(
                                      title: 'Rata-rata Transaksi',
                                      value: CurrencyFormatter.formatCurrency(_salesDashboardData!.currentPeriod.averageTransactionValue),
                                      icon: Icons.trending_up,
                                      color: primaryGreen,
                                      changePercentage: _salesDashboardData!.comparison.averageTransactionValueChange,
                                      isCurrency: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SalesStatCardWidget(
                                      title: 'Total Profit',
                                      value: CurrencyFormatter.formatCurrency(_salesDashboardData!.currentPeriod.totalProfit),
                                      icon: Icons.account_balance_wallet,
                                      color: primaryGreen,
                                      changePercentage: _salesDashboardData!.comparison.profitChange,
                                      isCurrency: true,
                                    ),
                                  ),
                                ],
                              ),
            const SizedBox(height: 24),
            
            // Grafik penjualan harian
            if (_salesDashboardData != null) ...[  
              SalesChartWidget(
                dailySalesData: _salesDashboardData!.dailySales,
                isMobile: isMobile,
              ),
              const SizedBox(height: 24),
            ],
            
            // Recent transactions and top products - responsif untuk mobile
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRecentTransactionsCard(),
                      const SizedBox(height: 16),
                      _buildTopProductsCard(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recent transactions table
                      Expanded(
                        flex: 3,
                        child: _buildRecentTransactionsCard(),
                      ),
                      const SizedBox(width: 16),
                      // Top products
                      Expanded(
                        flex: 2,
                        child: _buildTopProductsCard(),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // Helper to get icon for each navigation index
  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return Icons.dashboard;
      case 1: return Icons.point_of_sale;
      case 2: return Icons.inventory;
      case 3: return Icons.people;
      case 4: return Icons.receipt_long;
      case 5: return Icons.settings;
      default: return Icons.dashboard;
    }
  }
  

  
  // Show reports menu popup
  void _showReportsMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'daily-recap',
          child: Row(
            children: [
              Icon(Icons.summarize, color: Color(0xFF1E2A78)),
              SizedBox(width: 8),
              Text('Rekapitulasi Harian'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'sales-report',
          child: Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFF1E2A78)),
              SizedBox(width: 8),
              Text('Laporan Penjualan'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'daily-recap') {
        // Navigasi ke halaman rekapitulasi harian
        print('Navigating to daily recap screen');
        print('Navigator key valid: ${navigatorKey.currentState != null}');
        print('Route name: /reports/daily-recap');
        // Coba gunakan Navigator.of(context) sebagai fallback jika navigatorKey tidak berfungsi
        try {
          navigatorKey.currentState?.pushNamed('/reports/daily-recap');
          print('Navigation attempted with navigatorKey');
        } catch (e) {
          print('Error using navigatorKey: $e');
          Navigator.of(context).pushNamed('/reports/daily-recap');
          print('Fallback to Navigator.of(context)');
        }
      } else if (value == 'sales-report') {
        print('Navigating to sales report screen');
        // Coba gunakan Navigator.of(context) sebagai fallback jika navigatorKey tidak berfungsi
        try {
          navigatorKey.currentState?.pushNamed('/reports/sales');
          print('Navigation attempted with navigatorKey');
        } catch (e) {
          print('Error using navigatorKey: $e');
          Navigator.of(context).pushNamed('/reports/sales');
          print('Fallback to Navigator.of(context)');
        }
      }
    });
  }

  // Recent transactions card with table
  Widget _buildRecentTransactionsCard() {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/transactions');
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1E2A78),
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Menampilkan loading indicator
          if (_isLoadingTransactions) ...[  
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ]
          // Menampilkan pesan error jika ada
          else if (_transactionsError != null) ...[  
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(_transactionsError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchRecentTransactions,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ]
          // Menampilkan pesan jika tidak ada data
          else if (_recentTransactions.isEmpty) ...[  
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Tidak ada data transaksi terbaru'),
              ),
            ),
          ]
          // Tampilan mobile menggunakan ListView dengan Card
          else if (isMobile) ...[
            ...List.generate(_recentTransactions.length, (index) {
              final transaction = _recentTransactions[index];
              return InkWell(
                onTap: () {
                  // Navigasi ke halaman detail transaksi
                  if (transaction.containsKey('id')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionDetailScreen(
                          transactionId: int.parse(transaction['id'].toString().replaceAll('INV-', '')),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            transaction['id'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(transaction['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              transaction['status'],
                              style: TextStyle(
                                color: _getStatusColor(transaction['status']),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              transaction['customer'],
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                transaction['date'],
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                          Text(
                            transaction['amount'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ] else ...[
            // Tampilan desktop menggunakan tabel
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Invoice', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            // Table rows
            ...List.generate(_recentTransactions.length, (index) {
              final transaction = _recentTransactions[index];
              return InkWell(
                onTap: () {
                  // Navigasi ke halaman detail transaksi
                  if (transaction.containsKey('id')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionDetailScreen(
                          transactionId: int.parse(transaction['id'].toString().replaceAll('INV-', '')),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          transaction['id'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(transaction['customer']),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(transaction['date']),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          transaction['amount'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(transaction['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            transaction['status'],
                            style: TextStyle(
                              color: _getStatusColor(transaction['status']),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
  
  // Top products card
  Widget _buildTopProductsCard() {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isMobile ? 'Top Products' : 'Top Selling Products This Month',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : (isTablet ? 17 : 18),
                    fontWeight: FontWeight.bold,
                    color: darkBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: primaryGreen,
                ),
                child: Text(
                  isMobile ? 'All' : 'View All',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Menampilkan loading indicator
          if (_isLoadingTopProducts) ...[  
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ]
          // Menampilkan pesan error jika ada
          else if (_topProductsError != null) ...[  
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(_topProductsError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchTopProducts,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ]
          // Menampilkan pesan jika tidak ada data
          else if (_topProducts.isEmpty) ...[  
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Tidak ada data produk terlaris'),
              ),
            ),
          ]
          // Menampilkan daftar produk terlaris
          else ...[  
            ...List.generate(_topProducts.length, (index) {
              final product = _topProducts[index];
              return Container(
                margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: lightBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryGreen.withOpacity(0.2)),
                ),
                child: isMobile 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row with rank and name
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: primaryGreen,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                product['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 14,
                                  color: darkBlack,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Details row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${product['sold']} units',
                                    style: TextStyle(
                                      color: darkBlack.withOpacity(0.7), 
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (product['profit_margin'] != null)
                                    Text(
                                      'Margin: ${product['profit_margin']}%',
                                      style: TextStyle(
                                        color: darkBlack.withOpacity(0.7), 
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  product['revenue'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 14,
                                    color: primaryGreen,
                                  ),
                                ),
                                if (product['profit'] != null)
                                  Text(
                                    'Profit: Rp ${NumberFormat('#,###', 'id_ID').format(product['profit'])}',
                                    style: TextStyle(
                                      color: darkBlack.withOpacity(0.7), 
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // Product rank
                        Container(
                          width: isTablet ? 30 : 32,
                          height: isTablet ? 30 : 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            borderRadius: BorderRadius.circular(isTablet ? 15 : 16),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 16),
                        // Product details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: isTablet ? 15 : 16,
                                  color: darkBlack,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                children: [
                                  Text(
                                    '${product['sold']} units sold',
                                    style: TextStyle(
                                      color: darkBlack.withOpacity(0.7), 
                                      fontSize: isTablet ? 13 : 14,
                                    ),
                                  ),
                                  if (product['sku'] != null && !isTablet) ...[  
                                    Text(
                                      ' • SKU: ${product['sku']}',
                                      style: TextStyle(
                                        color: darkBlack.withOpacity(0.7), 
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (product['profit_margin'] != null) ...[  
                                const SizedBox(height: 4),
                                Text(
                                  'Profit Margin: ${product['profit_margin']}%',
                                  style: TextStyle(
                                    color: darkBlack.withOpacity(0.7), 
                                    fontSize: isTablet ? 13 : 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Revenue
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              product['revenue'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: isTablet ? 15 : 16,
                                color: primaryGreen,
                              ),
                            ),
                            if (product['profit'] != null) ...[  
                              const SizedBox(height: 4),
                              Text(
                                'Profit: Rp ${NumberFormat('#,###', 'id_ID').format(product['profit'])}',
                                style: TextStyle(
                                  color: darkBlack.withOpacity(0.7), 
                                  fontSize: isTablet ? 12 : 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
              );
            }),
          ],
        ],
      ),
    );
  }
  


  void _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2A78),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldLogout) return;
    
    // Show loading indicator
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging out...')),
    );
    
    final result = await _authService.logout();
    if (result) {
      // Navigate to login screen
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to logout')),
      );
    }
  }
}