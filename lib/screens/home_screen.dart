import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/receipt_service.dart';
import '../utils/responsive_helper.dart';
import '../config/api_config.dart';
import '../main.dart' as main;
import '../widgets/promotion_section_widget.dart';
import '../widgets/announcement_section_widget.dart';
import '../providers/connectivity_provider.dart';
import 'category_screen.dart';
import 'product_screen.dart';
import 'expense_category_screen.dart';
import 'expense_screen.dart';
import 'stock_movement_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  
  // Using theme colors from ApiConfig
  
  // Additional theme colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }





  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 32),
                  _buildQuickActionsSection(),
                  const SizedBox(height: 32),
                  AnnouncementSectionWidget(isTablet: !isMobile),
                  const SizedBox(height: 32),
                  _buildPromotionsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ApiConfig.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Dompet Kasir - POS',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        // Indikator status koneksi dan tombol switch mode
        Consumer<ConnectivityProvider>(
          builder: (context, connectivityProvider, child) {
            return PopupMenuButton<String>(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    connectivityProvider.getStatusIcon(),
                    color: connectivityProvider.getStatusIconColor(),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: connectivityProvider.isOnline 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      connectivityProvider.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: connectivityProvider.isOnline 
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              tooltip: 'Mode Koneksi',
              onSelected: (String value) {
                if (value == 'toggle') {
                  connectivityProvider.toggleMode();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Row(
                    children: [
                      Icon(
                        connectivityProvider.getStatusIcon(),
                        color: connectivityProvider.getStatusIconColor(),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        connectivityProvider.statusMessage,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        connectivityProvider.isOnline 
                          ? Icons.wifi_off 
                          : Icons.wifi,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        connectivityProvider.isOnline 
                          ? 'Beralih ke Offline'
                          : 'Beralih ke Online',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Handle notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () {
            // Handle help
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ApiConfig.primaryColor, ApiConfig.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ApiConfig.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 60 : 80,
            height: isMobile ? 60 : 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person,
              size: isMobile ? 30 : 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Premium',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        final quickActions = [
      {
        'title': 'Point of Sale',
        'subtitle': 'Mulai transaksi penjualan',
        'icon': Icons.storefront_rounded,
        'color': const Color(0xFF2E7D32),
        'route': '/pos',
      },
      {
        'title': 'Riwayat Transaksi',
        'subtitle': 'Lihat penjualan terdahulu',
        'icon': Icons.history_rounded,
        'color': const Color(0xFF388E3C),
        'route': '/transactions',
      },
      {
        'title': 'Persediaan Harian',
        'subtitle': 'Kelola persediaan barang harian',
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF43A047),
        'route': '/inventory',
      },
      {
        'title': 'Kategori Produk',
        'subtitle': 'Atur kategori barang',
        'icon': Icons.folder_rounded,
        'color': const Color(0xFF4CAF50),
        'onTap': () => _navigateToCategories(),
      },
      {
        'title': 'Data Produk',
        'subtitle': 'Kelola informasi produk',
        'icon': Icons.shopping_bag_rounded,
        'color': const Color(0xFF558B2F),
        'onTap': () => _navigateToProducts(),
      },
      {
        'title': 'Kategori Biaya',
        'subtitle': 'Atur jenis pengeluaran',
        'icon': Icons.label_rounded,
        'color': const Color(0xFF689F38),
        'onTap': () => _navigateToExpenseCategories(),
      },
      {
        'title': 'Pencatatan Biaya',
        'subtitle': 'Catat pengeluaran harian',
        'icon': Icons.receipt_long_rounded,
        'color': const Color(0xFF7CB342),
        'onTap': () => _navigateToExpenses(),
      },
      {
        'title': 'Pergerakan Stok Produk',
        'subtitle': 'Penyesuaian Stock Produk',
        'icon': Icons.swap_horiz_rounded,
        'color': const Color(0xFF8BC34A),
        'onTap': () => _navigateToStockMovements(),
      },
      {
        'title': 'Laporan & Analisis',
        'subtitle': 'Insight bisnis mendalam',
        'icon': Icons.analytics_rounded,
        'color': const Color(0xFF1B5E20),
        'onTap': _showReportsMenu,
      },
    ];

        // Filter actions based on offline mode
        final filteredActions = connectivityProvider.isOffline 
            ? quickActions.where((action) => 
                action['title'] == 'Point of Sale' || 
                action['title'] == 'Riwayat Transaksi'
              ).toList()
            : quickActions;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Fitur',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : isTablet ? 22 : 24,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                // Offline mode indicator
                if (connectivityProvider.isOffline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mode Offline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 2 : isTablet ? 3 : 4,
                crossAxisSpacing: isMobile ? 16 : isTablet ? 20 : 24,
                mainAxisSpacing: isMobile ? 16 : isTablet ? 20 : 24,
                childAspectRatio: isMobile ? 1.0 : isTablet ? 1.1 : 1.15,
              ),
              itemCount: filteredActions.length,
              itemBuilder: (context, index) {
                final action = filteredActions[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _buildQuickActionCard(action),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionCard(Map<String, dynamic> action) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        // Check if feature is available in current mode
        final isAvailable = connectivityProvider.isOnline || 
            action['title'] == 'Point of Sale' || 
            action['title'] == 'Riwayat Transaksi';
        
        return StatefulBuilder(
          builder: (context, setState) {
            bool isHovered = false;
        
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..scale(isHovered ? 1.05 : 1.0)
              ..translate(0.0, isHovered ? -4.0 : 0.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: !isAvailable
                  ? [
                      Colors.grey.withOpacity(0.08),
                      Colors.grey.withOpacity(0.03),
                    ]
                  : isHovered 
                    ? [
                        action['color'].withOpacity(0.15),
                        action['color'].withOpacity(0.08),
                      ]
                    : [
                        action['color'].withOpacity(0.08),
                        action['color'].withOpacity(0.03),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: !isAvailable
                  ? Colors.grey.withOpacity(0.3)
                  : isHovered 
                    ? action['color'].withOpacity(0.4)
                    : action['color'].withOpacity(0.15),
                width: isHovered ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovered 
                    ? action['color'].withOpacity(0.25)
                    : action['color'].withOpacity(0.08),
                  blurRadius: isHovered ? 20 : 8,
                  offset: isHovered ? const Offset(0, 8) : const Offset(0, 2),
                  spreadRadius: isHovered ? 2 : 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                splashColor: action['color'].withOpacity(0.15),
                highlightColor: action['color'].withOpacity(0.08),
                onTap: isAvailable ? () {
                  // Add haptic feedback
                  if (action['onTap'] != null) {
                    action['onTap']();
                  } else if (action['route'] != null) {
                    main.navigatorKey.currentState?.pushNamed(action['route']);
                  }
                } : () {
                  // Show unavailable feature dialog
                  connectivityProvider.showFeatureUnavailableDialog(context, action['title']);
                },
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 18 : isTablet ? 20 : 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Enhanced icon container with animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isMobile ? 56 : isTablet ? 64 : 72,
                        height: isMobile ? 56 : isTablet ? 64 : 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isHovered
                              ? [
                                  action['color'].withOpacity(0.2),
                                  action['color'].withOpacity(0.1),
                                ]
                              : [
                                  action['color'].withOpacity(0.12),
                                  action['color'].withOpacity(0.06),
                                ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: action['color'].withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                        ),
                        child: AnimatedScale(
                          scale: isHovered ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                action['icon'],
                                color: !isAvailable
                                  ? Colors.grey.withOpacity(0.5)
                                  : isHovered 
                                    ? action['color']
                                    : action['color'].withOpacity(0.8),
                                size: isMobile ? 28 : isTablet ? 32 : 36,
                              ),
                              if (!isAvailable)
                                Icon(
                                  Icons.lock_outline,
                                  color: Colors.grey.withOpacity(0.7),
                                  size: (isMobile ? 28 : isTablet ? 32 : 36) * 0.6,
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 14 : isTablet ? 16 : 18),
                      
                      // Enhanced title with better typography
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 15 : isTablet ? 17 : 18,
                          color: !isAvailable
                            ? Colors.grey.withOpacity(0.6)
                            : isHovered ? textPrimary : textPrimary.withOpacity(0.9),
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                        child: Text(
                          action['title'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: isMobile ? 6 : isTablet ? 8 : 10),
                      
                      // Enhanced subtitle with better contrast
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                          color: !isAvailable
                            ? Colors.grey.withOpacity(0.5)
                            : isHovered 
                              ? textSecondary 
                              : textSecondary.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                          letterSpacing: 0.1,
                        ),
                        child: Text(
                          action['subtitle'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }



  Widget _buildPromotionsSection() {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return PromotionSectionWidget(
      isTablet: !isMobile,
    );
  }



  void _showReportsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Pilih Jenis Laporan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ApiConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.summarize,
                  color: ApiConfig.primaryColor,
                ),
              ),
              title: const Text('Rekapitulasi Harian'),
              subtitle: const Text('Ringkasan transaksi harian'),
              onTap: () {
                Navigator.pop(context);
                main.navigatorKey.currentState?.pushNamed('/reports/daily-recap');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ApiConfig.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: ApiConfig.secondaryColor,
                ),
              ),
              title: const Text('Laporan Penjualan'),
              subtitle: const Text('Analisis penjualan detail'),
              onTap: () {
                Navigator.pop(context);
                main.navigatorKey.currentState?.pushNamed('/reports/sales');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToCategories() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CategoryScreen(),
      ),
    );
  }

  void _navigateToProducts() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductScreen(),
      ),
    );
  }

  void _navigateToExpenseCategories() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ExpenseCategoryScreen(),
      ),
    );
  }

  void _navigateToExpenses() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ExpenseScreen(),
      ),
    );
  }

  void _navigateToStockMovements() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StockMovementScreen(),
      ),
    );
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ApiConfig.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldLogout) return;
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sedang keluar...')),
    );
    
    final result = await _authService.logout();
    if (result) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal keluar dari aplikasi')),
      );
    }
  }
}