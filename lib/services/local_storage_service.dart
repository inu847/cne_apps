import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../models/payment_method_model.dart';

class LocalStorageService {
  static const String _productsKey = 'pos_products';
  static const String _paymentMethodsKey = 'pos_payment_methods';
  static const String _lastUpdateKey = 'pos_last_update';

  // Singleton pattern
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  /// Cek apakah localStorage tersedia
  bool get isLocalStorageAvailable {
    try {
      if (kIsWeb) {
        // For web, we'll assume localStorage is available
        return true;
      } else {
        // For mobile, shared_preferences is always available
        return true;
      }
    } catch (e) {
      print('LocalStorage tidak tersedia: $e');
      return false;
    }
  }

  /// Get SharedPreferences instance for mobile platforms
  Future<SharedPreferences?> _getPrefs() async {
    try {
      if (!kIsWeb) {
        return await SharedPreferences.getInstance();
      }
      return null;
    } catch (e) {
      print('Error getting SharedPreferences: $e');
      return null;
    }
  }

  /// Set string value based on platform
  Future<bool> _setString(String key, String value) async {
    try {
      if (kIsWeb) {
        // For web platform, use a simple in-memory storage as fallback
        // In a real web app, you would use dart:html localStorage
        _webStorage[key] = value;
        return true;
      } else {
        final prefs = await _getPrefs();
        if (prefs != null) {
          return await prefs.setString(key, value);
        }
        return false;
      }
    } catch (e) {
      print('Error setting string: $e');
      return false;
    }
  }

  /// Get string value based on platform
  Future<String?> _getString(String key) async {
    try {
      if (kIsWeb) {
        // For web platform, use in-memory storage as fallback
        return _webStorage[key];
      } else {
        final prefs = await _getPrefs();
        if (prefs != null) {
          return prefs.getString(key);
        }
        return null;
      }
    } catch (e) {
      print('Error getting string: $e');
      return null;
    }
  }

  /// Remove value based on platform
  Future<bool> _remove(String key) async {
    try {
      if (kIsWeb) {
        _webStorage.remove(key);
        return true;
      } else {
        final prefs = await _getPrefs();
        if (prefs != null) {
          return await prefs.remove(key);
        }
        return false;
      }
    } catch (e) {
      print('Error removing key: $e');
      return false;
    }
  }

  // In-memory storage for web fallback
  static final Map<String, String> _webStorage = {};

  /// Simpan data produk ke localStorage
  Future<bool> saveProducts(List<Product> products) async {
    try {
      if (!isLocalStorageAvailable) return false;
      
      final productsJson = products.map((product) => product.toJson()).toList();
      final jsonString = jsonEncode(productsJson);
      
      final success = await _setString(_productsKey, jsonString);
      if (success) {
        await _setString(_lastUpdateKey, DateTime.now().toIso8601String());
        print('LocalStorageService: ${products.length} produk berhasil disimpan');
        return true;
      }
      return false;
    } catch (e) {
      print('LocalStorageService: Error menyimpan produk - $e');
      return false;
    }
  }

  /// Ambil data produk dari localStorage
  Future<List<Product>?> getProducts() async {
    try {
      if (!isLocalStorageAvailable) return null;
      
      final jsonString = await _getString(_productsKey);
      if (jsonString == null || jsonString.isEmpty) {
        print('LocalStorageService: Tidak ada data produk di localStorage');
        return null;
      }
      
      final List<dynamic> productsJson = jsonDecode(jsonString);
      final products = productsJson.map((json) => Product.fromJson(json)).toList();
      
      print('LocalStorageService: ${products.length} produk berhasil dimuat dari localStorage');
      return products;
    } catch (e) {
      print('LocalStorageService: Error memuat produk - $e');
      // Hapus data corrupt
      await clearProducts();
      return null;
    }
  }

  /// Simpan data metode pembayaran ke localStorage
  Future<bool> savePaymentMethods(List<PaymentMethod> paymentMethods) async {
    try {
      if (!isLocalStorageAvailable) return false;
      
      final paymentMethodsJson = paymentMethods.map((method) => method.toJson()).toList();
      final jsonString = jsonEncode(paymentMethodsJson);
      
      final success = await _setString(_paymentMethodsKey, jsonString);
      if (success) {
        await _setString(_lastUpdateKey, DateTime.now().toIso8601String());
        print('LocalStorageService: ${paymentMethods.length} metode pembayaran berhasil disimpan');
        return true;
      }
      return false;
    } catch (e) {
      print('LocalStorageService: Error menyimpan metode pembayaran - $e');
      return false;
    }
  }

  /// Ambil data metode pembayaran dari localStorage
  Future<List<PaymentMethod>?> getPaymentMethods() async {
    try {
      if (!isLocalStorageAvailable) return null;
      
      final jsonString = await _getString(_paymentMethodsKey);
      if (jsonString == null || jsonString.isEmpty) {
        print('LocalStorageService: Tidak ada data metode pembayaran di localStorage');
        return null;
      }
      
      final List<dynamic> paymentMethodsJson = jsonDecode(jsonString);
      final paymentMethods = paymentMethodsJson.map((json) => PaymentMethod.fromJson(json)).toList();
      
      print('LocalStorageService: ${paymentMethods.length} metode pembayaran berhasil dimuat dari localStorage');
      return paymentMethods;
    } catch (e) {
      print('LocalStorageService: Error memuat metode pembayaran - $e');
      // Hapus data corrupt
      await clearPaymentMethods();
      return null;
    }
  }

  /// Ambil waktu update terakhir
  Future<DateTime?> getLastUpdateTime() async {
    try {
      if (!isLocalStorageAvailable) return null;
      
      final lastUpdateString = await _getString(_lastUpdateKey);
      if (lastUpdateString == null) return null;
      
      return DateTime.parse(lastUpdateString);
    } catch (e) {
      print('LocalStorageService: Error mendapatkan waktu update terakhir - $e');
      return null;
    }
  }

  /// Cek apakah data perlu diperbarui (lebih dari 1 jam)
  Future<bool> shouldRefreshData() async {
    final lastUpdate = await getLastUpdateTime();
    if (lastUpdate == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    // Refresh jika data lebih dari 1 jam
    return difference.inHours >= 1;
  }

  /// Hapus data produk dari localStorage
  Future<void> clearProducts() async {
    try {
      if (!isLocalStorageAvailable) return;
      await _remove(_productsKey);
      print('LocalStorageService: Data produk dihapus dari localStorage');
    } catch (e) {
      print('LocalStorageService: Error menghapus data produk - $e');
    }
  }

  /// Hapus data metode pembayaran dari localStorage
  Future<void> clearPaymentMethods() async {
    try {
      if (!isLocalStorageAvailable) return;
      await _remove(_paymentMethodsKey);
      print('LocalStorageService: Data metode pembayaran dihapus dari localStorage');
    } catch (e) {
      print('LocalStorageService: Error menghapus data metode pembayaran - $e');
    }
  }

  /// Hapus semua data localStorage
  Future<void> clearAll() async {
    try {
      if (!isLocalStorageAvailable) return;
      
      await _remove(_productsKey);
      await _remove(_paymentMethodsKey);
      await _remove(_lastUpdateKey);
      
      print('LocalStorageService: Semua data localStorage dihapus');
    } catch (e) {
      print('LocalStorageService: Error menghapus semua data - $e');
    }
  }

  /// Cek apakah ada data di localStorage
  Future<bool> hasStoredData() async {
    try {
      if (!isLocalStorageAvailable) return false;
      
      final hasProducts = await _getString(_productsKey) != null;
      final hasPaymentMethods = await _getString(_paymentMethodsKey) != null;
      
      return hasProducts && hasPaymentMethods;
    } catch (e) {
      print('LocalStorageService: Error mengecek data tersimpan - $e');
      return false;
    }
  }

  /// Dapatkan ukuran data localStorage (dalam KB)
  Future<double> getStorageSize() async {
    try {
      if (!isLocalStorageAvailable) return 0.0;
      
      int totalSize = 0;
      final keys = [_productsKey, _paymentMethodsKey, _lastUpdateKey];
      
      for (String key in keys) {
        final value = await _getString(key);
        if (value != null) {
          totalSize += value.length;
        }
      }
      
      return totalSize / 1024; // Convert to KB
    } catch (e) {
      print('LocalStorageService: Error menghitung ukuran storage - $e');
      return 0.0;
    }
  }
}