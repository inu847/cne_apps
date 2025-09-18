import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/promotion_model.dart';
import '../services/auth_service.dart';

class PromotionService {
  final AuthService _authService = AuthService();

  /// Mengambil daftar promosi aktif
  Future<List<Promotion>> getActivePromotions() async {
    try {
      print('PromotionService: Getting token...');
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final uri = Uri.parse(ApiConfig.activePromotionsEndpoint);
      print('PromotionService: Calling endpoint: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('PromotionService: Response status: ${response.statusCode}');
      print('PromotionService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final promotionResponse = PromotionResponse.fromJson(jsonData);
        
        if (promotionResponse.success) {
          return promotionResponse.data;
        } else {
          throw Exception(promotionResponse.message ?? 'Gagal mengambil data promosi');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Sesi telah berakhir. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        // Jika endpoint tidak ditemukan, return dummy data untuk testing
        print('PromotionService: Endpoint not found, returning dummy data');
        return _getDummyPromotions();
      } else {
        throw Exception('Gagal mengambil data promosi. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException')) {
        throw Exception('Koneksi internet bermasalah. Periksa koneksi Anda.');
      }
      rethrow;
    }
  }

  /// Mengambil promosi berdasarkan ID
  Future<Promotion?> getPromotionById(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final uri = Uri.parse('${ApiConfig.promotionsEndpoint}/$id');
      
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
          return Promotion.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Gagal mengambil detail promosi');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Sesi telah berakhir. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        return null; // Promosi tidak ditemukan
      } else {
        throw Exception('Gagal mengambil detail promosi. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException')) {
        throw Exception('Koneksi internet bermasalah. Periksa koneksi Anda.');
      }
      rethrow;
    }
  }

  /// Mencatat klik pada promosi (untuk tracking)
  Future<bool> recordPromotionClick(int promotionId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return false; // Gagal tanpa error untuk tracking
      }

      final uri = Uri.parse('${ApiConfig.promotionsEndpoint}/$promotionId/click');
      
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

  /// Mencatat view pada promosi (untuk tracking)
  Future<bool> recordPromotionView(int promotionId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return false; // Gagal tanpa error untuk tracking
      }

      final uri = Uri.parse('${ApiConfig.promotionsEndpoint}/$promotionId/view');
      
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

  /// Filter promosi berdasarkan target audience
  List<Promotion> filterPromotionsByAudience(List<Promotion> promotions, String userType) {
    return promotions.where((promotion) {
      return promotion.targetAudience.isEmpty || 
             promotion.targetAudience.contains(userType) ||
             promotion.targetAudience.contains('all_users');
    }).toList();
  }

  /// Mendapatkan promosi featured saja
  List<Promotion> getFeaturedPromotions(List<Promotion> promotions) {
    return promotions.where((promotion) => promotion.isFeatured).toList();
  }

  /// Mengurutkan promosi berdasarkan prioritas
  List<Promotion> sortPromotionsByPriority(List<Promotion> promotions) {
    final sortedPromotions = List<Promotion>.from(promotions);
    
    sortedPromotions.sort((a, b) {
      // Featured promotions first
      if (a.isFeatured && !b.isFeatured) return -1;
      if (!a.isFeatured && b.isFeatured) return 1;
      
      // Then by view count (higher first)
      if (a.viewCount != b.viewCount) {
        return b.viewCount.compareTo(a.viewCount);
      }
      
      // Finally by start date (newer first)
      return b.startDate.compareTo(a.startDate);
    });
    
    return sortedPromotions;
  }

  /// Mendapatkan data dummy untuk testing
  List<Promotion> _getDummyPromotions() {
    final now = DateTime.now();
    return [
      Promotion(
        id: 1,
        title: 'Diskon Akhir Tahun',
        description: 'Dapatkan diskon hingga 50% untuk semua produk elektronik',
        content: 'Promo spesial akhir tahun dengan diskon fantastis untuk semua kategori produk elektronik. Berlaku untuk pembelian minimal Rp 500.000',
        type: 'discount',
        status: 'active',
        discountPercentage: 50.0,
        promoCode: 'AKHIRTAHUN50',
        isFeatured: true,
        viewCount: 125,
        clickCount: 45,
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 25)),
        targetAudience: ['all_users'],
        termsConditions: [
          'Berlaku untuk pembelian minimal Rp 500.000',
          'Tidak dapat digabung dengan promo lain',
          'Berlaku hingga 31 Desember 2024'
        ],
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Promotion(
        id: 2,
        title: 'Cashback Spesial',
        description: 'Cashback 20% untuk transaksi menggunakan e-wallet',
        content: 'Nikmati cashback 20% untuk setiap transaksi menggunakan e-wallet. Maksimal cashback Rp 100.000 per transaksi.',
        type: 'cashback',
        status: 'active',
        discountAmount: '100000',
        promoCode: 'CASHBACK20',
        isFeatured: false,
        viewCount: 89,
        clickCount: 23,
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 15)),
        targetAudience: ['premium_users', 'regular_users'],
        termsConditions: [
          'Berlaku untuk pembayaran e-wallet',
          'Maksimal cashback Rp 100.000',
          'Berlaku untuk transaksi minimal Rp 200.000'
        ],
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(hours: 12)),
      ),
      Promotion(
        id: 3,
        title: 'Bundle Hemat',
        description: 'Beli 2 gratis 1 untuk produk fashion',
        content: 'Promo bundle hemat untuk semua produk fashion. Beli 2 item fashion apapun dan dapatkan 1 item gratis dengan nilai terendah.',
        type: 'special_offer',
        status: 'active',
        isFeatured: true,
        viewCount: 156,
        clickCount: 67,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 20)),
        targetAudience: ['all_users'],
        termsConditions: [
          'Berlaku untuk kategori fashion',
          'Item gratis adalah yang bernilai terendah',
          'Tidak berlaku untuk item sale'
        ],
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }
}