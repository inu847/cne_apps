import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../screens/transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  
  void _onItemTapped(int index) {
    if (index == 1) { // POS menu
      Navigator.pushNamed(context, '/pos');
      return;
    } else if (index == 4) { // Transactions menu
      Navigator.pushNamed(context, '/transactions');
      return;
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }
  
  // Simulasi data untuk grafik dan tabel
  final List<Map<String, dynamic>> _recentTransactions = [
    {'id': 'INV-001', 'customer': 'John Doe', 'date': '2023-06-15', 'amount': 'Rp 350,000', 'status': 'Completed'},
    {'id': 'INV-002', 'customer': 'Jane Smith', 'date': '2023-06-15', 'amount': 'Rp 125,000', 'status': 'Completed'},
    {'id': 'INV-003', 'customer': 'Robert Johnson', 'date': '2023-06-14', 'amount': 'Rp 780,000', 'status': 'Pending'},
    {'id': 'INV-004', 'customer': 'Emily Davis', 'date': '2023-06-14', 'amount': 'Rp 450,000', 'status': 'Completed'},
    {'id': 'INV-005', 'customer': 'Michael Brown', 'date': '2023-06-13', 'amount': 'Rp 920,000', 'status': 'Cancelled'},
  ];
  
  final List<Map<String, dynamic>> _topProducts = [
    {'name': 'Product A', 'sold': 42, 'revenue': 'Rp 840,000'},
    {'name': 'Product B', 'sold': 38, 'revenue': 'Rp 760,000'},
    {'name': 'Product C', 'sold': 30, 'revenue': 'Rp 600,000'},
  ];

  // Menambahkan variabel untuk drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _getPageTitle(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        leading: isTablet ? IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ) : null,
        actions: [
          // Search icon pada mobile
          if (isMobile) IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          // Notification icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          // Help icon
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {},
            tooltip: 'Help',
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
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E2A78),
        unselectedItemColor: Colors.grey,
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
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Customers',
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
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // Search bar
                      Container(
                        width: 300,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Notification icon
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                        tooltip: 'Notifications',
                      ),
                      // Help icon
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () {},
                        tooltip: 'Help',
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
      color: const Color(0xFF1E2A78), // Dark blue color for sidebar
      child: Column(
        children: [
          // Logo and app name
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CNE',
                    style: TextStyle(
                      color: Color(0xFF1E2A78),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'CashNEntry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2D3990), height: 1),
          
          // User profile section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                  child: Text(
                    widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Color(0xFF1E2A78), fontWeight: FontWeight.bold, fontSize: 18),
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
          const Divider(color: Color(0xFF2D3990), height: 1),
          
          // Navigation menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
                _buildNavItem(1, 'POS', Icons.point_of_sale_outlined, Icons.point_of_sale),
                _buildNavItem(2, 'Inventory', Icons.inventory_outlined, Icons.inventory),
                _buildNavItem(3, 'Customers', Icons.people_outline, Icons.people),
                _buildNavItem(4, 'Transactions', Icons.receipt_outlined, Icons.receipt),
                _buildNavItem(5, 'Reports', Icons.receipt_long_outlined, Icons.receipt_long),
                _buildNavItem(6, 'Settings', Icons.settings_outlined, Icons.settings),
              ],
            ),
          ),
          
          // Logout button at bottom
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Color(0xFF1E2A78)),
              label: const Text('Logout', style: TextStyle(color: Color(0xFF1E2A78))),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E2A78),
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
      case 2: return 'Inventory Management';
      case 3: return 'Customer Management';
      case 4: return 'Transactions';
      case 5: return 'Reports & Analytics';
      case 6: return 'Settings';
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
          } else if (index == 4) { // Transactions menu
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TransactionsScreen(),
              ),
            );
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
            color: isSelected ? const Color(0xFF2D3990) : Colors.transparent,
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
                    color: Colors.white,
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

  Widget _buildMainContent() {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
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
      color: const Color(0xFFF5F7FA),
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Here\'s what\'s happening with your store today',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
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
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            const Text('Today'),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${widget.user.name}!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Here\'s what\'s happening with your store today',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Date range picker
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            const Text('Today'),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            
            // Stats cards - responsif untuk mobile
            isMobile
                ? Column(
                    children: [
                      _buildDashboardCard(
                        'Today\'s Sales',
                        'Rp 2,500,000',
                        Icons.attach_money,
                        const Color(0xFF1E2A78),
                        subtitle: '+15% from yesterday',
                        trend: 'up',
                      ),
                      const SizedBox(height: 16),
                      _buildDashboardCard(
                        'Orders',
                        '24',
                        Icons.shopping_cart,
                        const Color(0xFF1E2A78),
                        subtitle: '18 completed, 6 pending',
                        trend: 'up',
                      ),
                      const SizedBox(height: 16),
                      _buildDashboardCard(
                        'Customers',
                        '8',
                        Icons.people,
                        const Color(0xFF1E2A78),
                        subtitle: '3 new today',
                        trend: 'up',
                      ),
                      const SizedBox(height: 16),
                      _buildDashboardCard(
                        'Products',
                        '120',
                        Icons.inventory_2,
                        const Color(0xFF1E2A78),
                        subtitle: '5 low in stock',
                        trend: 'neutral',
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildDashboardCard(
                          'Today\'s Sales',
                          'Rp 2,500,000',
                          Icons.attach_money,
                          const Color(0xFF1E2A78),
                          subtitle: '+15% from yesterday',
                          trend: 'up',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDashboardCard(
                          'Orders',
                          '24',
                          Icons.shopping_cart,
                          const Color(0xFF1E2A78),
                          subtitle: '18 completed, 6 pending',
                          trend: 'up',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDashboardCard(
                          'Customers',
                          '8',
                          Icons.people,
                          const Color(0xFF1E2A78),
                          subtitle: '3 new today',
                          trend: 'up',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDashboardCard(
                          'Products',
                          '120',
                          Icons.inventory_2,
                          const Color(0xFF1E2A78),
                          subtitle: '5 low in stock',
                          trend: 'neutral',
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            
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

  Widget _buildDashboardCard(String title, String value, IconData icon, Color color, {String? subtitle, String? trend}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[  
            const SizedBox(height: 8),
            Row(
              children: [
                if (trend != null) ...[  
                  Icon(
                    trend == 'up' ? Icons.arrow_upward : (trend == 'down' ? Icons.arrow_downward : Icons.remove),
                    color: trend == 'up' ? Colors.green : (trend == 'down' ? Colors.red : Colors.grey),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: trend == 'up' ? Colors.green : (trend == 'down' ? Colors.red : Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
                onPressed: () {},
                child: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF1E2A78),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tampilan mobile menggunakan ListView dengan Card
          if (isMobile) ...[
            ...List.generate(_recentTransactions.length, (index) {
              final transaction = _recentTransactions[index];
              return Container(
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
              return Container(
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
                'Top Selling Products',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF1E2A78),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Product list
          ...List.generate(_topProducts.length, (index) {
            final product = _topProducts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Product rank
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2A78),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product['sold']} units sold',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  // Revenue
                  Text(
                    product['revenue'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            );
          }),
          
          // Chart placeholder - ukuran disesuaikan untuk mobile
          Container(
            height: isMobile ? 150 : 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: isMobile ? 36 : 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sales Chart',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to logout')),
      );
    }
  }
}