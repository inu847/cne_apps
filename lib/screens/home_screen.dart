import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/receipt_service.dart';
import '../utils/responsive_helper.dart';
import '../config/api_config.dart';
import '../main.dart';
import '../widgets/promotion_section_widget.dart';
import '../widgets/announcement_section_widget.dart';
import 'category_screen.dart';
import 'product_screen.dart';
import 'expense_category_screen.dart';
import 'expense_screen.dart';

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
    
    final quickActions = [
      {
        'title': 'Point of Sale',
        'subtitle': 'Mulai transaksi',
        'icon': Icons.point_of_sale,
        'color': ApiConfig.primaryColor,
        'route': '/pos',
      },
      {
        'title': 'Transaksi',
        'subtitle': 'Riwayat penjualan',
        'icon': Icons.receipt_long,
        'color': ApiConfig.secondaryColor,
        'route': '/transactions',
      },
      {
        'title': 'Persediaan',
        'subtitle': 'Kelola stok',
        'icon': Icons.inventory_2,
        'color': ApiConfig.accentColor,
        'route': '/inventory',
      },
      {
        'title': 'Kategori',
        'subtitle': 'Kelola kategori',
        'icon': Icons.category,
        'color': const Color(0xFF00BCD4),
        'onTap': () => _navigateToCategories(),
      },
      {
        'title': 'Produk',
        'subtitle': 'Kelola produk',
        'icon': Icons.shopping_bag,
        'color': const Color(0xFFFF7043),
        'onTap': () => _navigateToProducts(),
      },
      {
        'title': 'Kategori Pengeluaran',
        'subtitle': 'Kelola kategori pengeluaran',
        'icon': Icons.category_outlined,
        'color': const Color(0xFFE91E63),
        'onTap': () => _navigateToExpenseCategories(),
      },
      {
        'title': 'Pengeluaran',
        'subtitle': 'Kelola pengeluaran',
        'icon': Icons.receipt_long,
        'color': const Color(0xFFFF5722),
        'onTap': () => _navigateToExpenses(),
      },
      {
        'title': 'Laporan',
        'subtitle': 'Analisis bisnis',
        'icon': Icons.analytics,
        'color': const Color(0xFF7B1FA2),
        'onTap': _showReportsMenu,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: TextStyle(
            fontSize: isMobile ? 20 : isTablet ? 22 : 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : isTablet ? 3 : 4,
            crossAxisSpacing: isMobile ? 12 : isTablet ? 14 : 16,
            mainAxisSpacing: isMobile ? 12 : isTablet ? 14 : 16,
            childAspectRatio: isMobile ? 1.1 : isTablet ? 1.15 : 1.2,
          ),
          itemCount: quickActions.length,
          itemBuilder: (context, index) {
            final action = quickActions[index];
            return _buildQuickActionCard(action);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(Map<String, dynamic> action) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            action['color'].withOpacity(0.1),
            action['color'].withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: action['color'].withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: action['color'].withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: action['color'].withOpacity(0.1),
          highlightColor: action['color'].withOpacity(0.05),
          onTap: () {
            if (action['onTap'] != null) {
              action['onTap']();
            } else if (action['route'] != null) {
              navigatorKey.currentState?.pushNamed(action['route']);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isMobile ? 48 : 56,
                  height: isMobile ? 48 : 56,
                  decoration: BoxDecoration(
                    color: action['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    action['icon'],
                    color: action['color'],
                    size: isMobile ? 24 : 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  action['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : 16,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  action['subtitle'],
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
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
                navigatorKey.currentState?.pushNamed('/reports/daily-recap');
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
                navigatorKey.currentState?.pushNamed('/reports/sales');
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