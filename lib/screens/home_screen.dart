import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/receipt_service.dart';
import '../utils/responsive_helper.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  
  // Enhanced color palette
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentBlue = Color(0xFF1976D2);
  static const Color accentOrange = Color(0xFFFF6B35);
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

  // Sample data
  final List<Map<String, dynamic>> _announcements = [
    {
      'id': 1,
      'title': 'Update Sistem POS v2.1',
      'content': 'Fitur baru telah ditambahkan untuk meningkatkan performa aplikasi.',
      'date': '15 Jan 2024',
      'type': 'feature',
    },
    {
      'id': 2,
      'title': 'Maintenance Server',
      'content': 'Server akan mengalami maintenance pada tanggal 20 Januari 2024.',
      'date': '12 Jan 2024',
      'type': 'info',
    },
  ];

  final List<Map<String, dynamic>> _promotions = [
    {
      'id': 1,
      'title': 'Diskon Akhir Tahun',
      'description': 'Dapatkan diskon hingga 50% untuk semua produk elektronik',
      'discount': '50% OFF',
      'validUntil': '31 Des 2024',
      'color': const Color(0xFFE91E63),
    },
    {
      'id': 2,
      'title': 'Cashback Spesial',
      'description': 'Cashback 20% untuk pembelian minimal Rp 500.000',
      'discount': '20% Cashback',
      'validUntil': '15 Feb 2024',
      'color': const Color(0xFF9C27B0),
    },
  ];

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
                  _buildAnnouncementsSection(),
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
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'CNE POS',
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
        gradient: const LinearGradient(
          colors: [primaryGreen, lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
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
                    'Staff',
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
        'color': primaryGreen,
        'route': '/pos',
      },
      {
        'title': 'Transaksi',
        'subtitle': 'Riwayat penjualan',
        'icon': Icons.receipt_long,
        'color': accentBlue,
        'route': '/transactions',
      },
      {
        'title': 'Persediaan',
        'subtitle': 'Kelola stok',
        'icon': Icons.inventory_2,
        'color': accentOrange,
        'route': '/inventory',
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

  Widget _buildAnnouncementsSection() {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.campaign_outlined,
              color: accentBlue,
              size: isMobile ? 24 : 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Pengumuman',
              style: TextStyle(
                fontSize: isMobile ? 20 : 22,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_announcements.length} Baru',
                style: TextStyle(
                  color: accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Informasi terbaru dan update sistem',
          style: TextStyle(
            color: textSecondary,
            fontSize: isMobile ? 14 : 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _announcements.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final announcement = _announcements[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildAnnouncementCard(announcement),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final isMobile = ResponsiveHelper.isMobile(context);

    Color getTypeColor(String type) {
      switch (type) {
        case 'info':
          return accentBlue;
        case 'feature':
          return primaryGreen;
        case 'tip':
          return accentOrange;
        default:
          return textPrimary;
      }
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: getTypeColor(announcement['type']).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getTypeColor(announcement['type']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  announcement['type'].toUpperCase(),
                  style: TextStyle(
                    color: getTypeColor(announcement['type']),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                announcement['date'],
                style: TextStyle(
                  fontSize: 12,
                  color: textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement['title'],
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isMobile ? 16 : 18,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            announcement['content'],
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsSection() {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promosi & Penawaran',
          style: TextStyle(
            fontSize: isMobile ? 20 : 22,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _promotions.length,
            itemBuilder: (context, index) {
              final promotion = _promotions[index];
              return _buildPromotionCard(promotion);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: isMobile ? 300 : 340,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              promotion['color'],
              promotion['color'].withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: promotion['color'].withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // Handle promotion tap
            },
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 24 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          promotion['discount'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    promotion['title'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 18 : 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    promotion['description'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: isMobile ? 14 : 15,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Berlaku hingga ${promotion['validUntil']}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Klaim',
                          style: TextStyle(
                            color: promotion['color'],
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.summarize,
                  color: primaryGreen,
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
                  color: accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: accentBlue,
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
              backgroundColor: primaryGreen,
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