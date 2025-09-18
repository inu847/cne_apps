import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import '../config/api_config.dart';
import '../utils/responsive_helper.dart';

class AnnouncementSectionWidget extends StatefulWidget {
  final bool isTablet;

  const AnnouncementSectionWidget({
    super.key,
    this.isTablet = false,
  });

  @override
  State<AnnouncementSectionWidget> createState() => _AnnouncementSectionWidgetState();
}

class _AnnouncementSectionWidgetState extends State<AnnouncementSectionWidget>
    with TickerProviderStateMixin {
  final AnnouncementService _announcementService = AnnouncementService();
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Color constants
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAnnouncements();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadAnnouncements() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final announcements = await _announcementService.getActiveAnnouncements();
      final sortedAnnouncements = _announcementService.sortAnnouncementsByPriority(announcements);

      setState(() {
        _announcements = sortedAnnouncements;
        _isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('AnnouncementSectionWidget: Error loading announcements: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      // Validate URL format
      if (url.isEmpty) {
        throw Exception('URL is empty');
      }
      
      // Ensure URL has proper scheme
      String validUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        validUrl = 'https://$url';
      }
      
      print('Attempting to launch URL: $validUrl');
      
      final Uri uri = Uri.parse(validUrl);
      print('Parsed URI: $uri');
      
      // Check if URL can be launched
      final bool canLaunch = await canLaunchUrl(uri);
      print('Can launch URL: $canLaunch');
      
      if (canLaunch) {
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('URL launched successfully: $launched');
        
        if (!launched) {
          throw Exception('Failed to launch URL despite canLaunchUrl returning true');
        }
      } else {
        print('Cannot launch URL: $validUrl');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka link: $validUrl\nPastikan ada aplikasi browser yang terinstal.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error launching URL: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat membuka link: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    if (_isLoading) {
      return _buildLoadingState(isMobile);
    }

    if (_errorMessage != null) {
      return _buildErrorState(isMobile);
    }

    if (_announcements.isEmpty) {
      return _buildEmptyState(isMobile);
    }

    return _buildAnnouncementsSection(isMobile);
  }

  Widget _buildLoadingState(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.campaign_outlined,
              color: ApiConfig.secondaryColor,
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
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.campaign_outlined,
              color: ApiConfig.secondaryColor,
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
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat pengumuman',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Terjadi kesalahan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAnnouncements,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ApiConfig.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.campaign_outlined,
              color: ApiConfig.secondaryColor,
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
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.notifications_none,
                color: textTertiary,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Tidak ada pengumuman',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada pengumuman terbaru untuk ditampilkan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.campaign_outlined,
              color: ApiConfig.secondaryColor,
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
                color: ApiConfig.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_announcements.length} Baru',
                style: TextStyle(
                  color: ApiConfig.secondaryColor,
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
              child: _buildAnnouncementCard(announcement, isMobile),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement, bool isMobile) {
    Color getTypeColor(String type) {
      switch (type) {
        case 'info':
          return ApiConfig.secondaryColor;
        case 'feature':
          return ApiConfig.primaryColor;
        case 'maintenance':
          return Colors.orange;
        case 'promotion':
          return Colors.green;
        case 'warning':
          return Colors.red;
        case 'tip':
          return ApiConfig.accentColor;
        default:
          return textPrimary;
      }
    }

    return InkWell(
      onTap: () async {
        _announcementService.recordAnnouncementView(announcement.id);
        if (announcement.linkUrl != null) {
          _announcementService.recordAnnouncementClick(announcement.id);
          await _launchURL(announcement.linkUrl!);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: getTypeColor(announcement.type).withOpacity(0.2),
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
                    color: getTypeColor(announcement.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    announcement.typeDisplayName.toUpperCase(),
                    style: TextStyle(
                      color: getTypeColor(announcement.type),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (announcement.isPinned) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.push_pin,
                    size: 16,
                    color: getTypeColor(announcement.type),
                  ),
                ],
                const Spacer(),
                Text(
                  announcement.formattedDate,
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
              announcement.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isMobile ? 16 : 18,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              announcement.content,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                color: textSecondary,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (announcement.linkUrl != null && announcement.linkText != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: getTypeColor(announcement.type),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    announcement.linkText!,
                    style: TextStyle(
                      fontSize: 14,
                      color: getTypeColor(announcement.type),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}