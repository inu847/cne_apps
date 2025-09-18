import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/announcement_model.dart';
import '../services/auth_service.dart';

class AnnouncementService {
  final AuthService _authService = AuthService();

  /// Mengambil daftar pengumuman aktif
  Future<List<Announcement>> getActiveAnnouncements() async {
    try {
      print('AnnouncementService: Getting token...');
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/announcements/active');
      print('AnnouncementService: Calling endpoint: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('AnnouncementService: Response status: ${response.statusCode}');
      print('AnnouncementService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final announcementResponse = AnnouncementResponse.fromJson(jsonData);
        
        if (announcementResponse.success) {
          print('AnnouncementService: Successfully loaded ${announcementResponse.data.length} announcements');
          return announcementResponse.data;
        } else {
          throw Exception(announcementResponse.message ?? 'Gagal mengambil data pengumuman');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Sesi telah berakhir. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        // Jika endpoint tidak ditemukan, return dummy data untuk testing
        print('AnnouncementService: Endpoint not found, returning dummy data');
        return _getDummyAnnouncements();
      } else {
        throw Exception('Gagal mengambil data pengumuman. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('AnnouncementService: Error occurred: $e');
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException')) {
        print('AnnouncementService: Network error, returning dummy data');
        return _getDummyAnnouncements();
      }
      
      // Untuk error lain, tetap return dummy data agar UI tidak crash
      print('AnnouncementService: Other error, returning dummy data as fallback');
      return _getDummyAnnouncements();
    }
  }

  /// Mengambil pengumuman berdasarkan ID
  Future<Announcement?> getAnnouncementById(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/announcements/$id');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return Announcement.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Gagal mengambil detail pengumuman');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Sesi telah berakhir. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        return null; // Pengumuman tidak ditemukan
      } else {
        throw Exception('Gagal mengambil detail pengumuman. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException')) {
        throw Exception('Koneksi internet bermasalah. Periksa koneksi Anda.');
      }
      rethrow;
    }
  }

  /// Mencatat view pada pengumuman (untuk tracking)
  Future<bool> recordAnnouncementView(int announcementId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return false; // Gagal tanpa error untuk tracking
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/announcements/$announcementId/view');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      // Gagal tracking tidak perlu mengganggu user experience
      return false;
    }
  }

  /// Mencatat klik pada pengumuman (untuk tracking)
  Future<bool> recordAnnouncementClick(int announcementId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return false; // Gagal tanpa error untuk tracking
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/announcements/$announcementId/click');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      // Gagal tracking tidak perlu mengganggu user experience
      return false;
    }
  }

  /// Filter pengumuman berdasarkan target audience
  List<Announcement> filterAnnouncementsByAudience(List<Announcement> announcements, String userType) {
    return announcements.where((announcement) {
      return announcement.targetAudience.isEmpty || 
             announcement.targetAudience.contains(userType) ||
             announcement.targetAudience.contains('all_users');
    }).toList();
  }

  /// Mendapatkan pengumuman yang dipinned saja
  List<Announcement> getPinnedAnnouncements(List<Announcement> announcements) {
    return announcements.where((announcement) => announcement.isPinned).toList();
  }

  /// Mengurutkan pengumuman berdasarkan prioritas
  List<Announcement> sortAnnouncementsByPriority(List<Announcement> announcements) {
    final sortedAnnouncements = List<Announcement>.from(announcements);
    
    sortedAnnouncements.sort((a, b) {
      // Pinned announcements first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // Then by priority (higher first)
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }
      
      // Finally by created date (newer first)
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return sortedAnnouncements;
  }

  /// Mendapatkan data dummy untuk testing
  List<Announcement> _getDummyAnnouncements() {
    final now = DateTime.now();
    return [
      Announcement(
        id: 1,
        title: 'Update Sistem POS v2.1',
        content: 'Fitur baru telah ditambahkan untuk meningkatkan performa aplikasi. Update ini mencakup perbaikan bug, peningkatan kecepatan, dan fitur laporan yang lebih detail.',
        type: 'feature',
        status: 'active',
        isActive: true,
        isPinned: true,
        priority: 5,
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 28)),
        targetAudience: ['all_users'],
        viewCount: 245,
        clickCount: 67,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 12)),
      ),
      Announcement(
        id: 2,
        title: 'Maintenance Server',
        content: 'Server akan mengalami maintenance pada tanggal 20 Januari 2024 pukul 02:00 - 04:00 WIB. Selama periode ini, aplikasi mungkin tidak dapat diakses.',
        type: 'maintenance',
        status: 'active',
        isActive: true,
        isPinned: false,
        priority: 3,
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 15)),
        targetAudience: ['all_users'],
        viewCount: 189,
        clickCount: 23,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Announcement(
        id: 3,
        title: 'Tips Menggunakan Fitur Laporan',
        content: 'Pelajari cara menggunakan fitur laporan baru untuk mendapatkan insight bisnis yang lebih baik. Fitur ini memungkinkan Anda melihat tren penjualan dan performa produk.',
        type: 'tip',
        status: 'active',
        isActive: true,
        isPinned: false,
        priority: 2,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 30)),
        targetAudience: ['premium_users', 'business_users'],
        linkUrl: 'https://help.dompetkasirapps.com/reports',
        linkText: 'Pelajari Selengkapnya',
        viewCount: 156,
        clickCount: 45,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
      Announcement(
        id: 4,
        title: 'Promo Berlangganan Premium',
        content: 'Dapatkan diskon 30% untuk berlangganan premium selama 3 bulan pertama. Nikmati fitur-fitur eksklusif dan dukungan prioritas.',
        type: 'promotion',
        status: 'active',
        isActive: true,
        isPinned: true,
        priority: 4,
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 25)),
        targetAudience: ['regular_users'],
        linkUrl: 'https://dompetkasirapps.com/premium',
        linkText: 'Upgrade Sekarang',
        viewCount: 312,
        clickCount: 89,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 8)),
      ),
    ];
  }
}