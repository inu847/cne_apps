import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../models/payment_method_model.dart';

class LocalStorageService {
  static const String _productsKey = 'pos_products';
  static const String _paymentMethodsKey = 'pos_payment_methods';
  static const String _transactionsKey = 'pos_transactions'; // Legacy key - akan dihapus
  static const String _transactionsCacheKey = 'pos_transactions_cache'; // Data dari API
  static const String _transactionsOfflineKey = 'pos_transactions_offline'; // Transaksi offline
  static const String _lastUpdateKey = 'pos_last_update';
  static const int _maxTransactions = 50;

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
      await _remove(_transactionsKey);
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
      final hasTransactions = await _getString(_transactionsKey) != null;
      
      return hasProducts && hasPaymentMethods && hasTransactions;
    } catch (e) {
      print('LocalStorageService: Error mengecek data tersimpan - $e');
      return false;
    }
  }

  /// Simpan data transaksi ke localStorage (maksimal 50 transaksi terbaru)
  /// Simpan data transaksi ke localStorage (DEPRECATED - gunakan saveOfflineTransaction untuk offline atau saveTransactionsCache untuk API cache)
  @deprecated
  Future<bool> saveTransactions(List<Map<String, dynamic>> transactions) async {
    try {
      if (!isLocalStorageAvailable) return false;
      
      // Tambahkan timestamp dan status sync ke setiap transaksi
      final transactionsWithMeta = transactions.map((transaction) {
        final transactionCopy = Map<String, dynamic>.from(transaction);
        transactionCopy['local_saved_at'] = DateTime.now().toIso8601String();
        // Jika belum ada status sync, set sebagai false (belum sync)
        transactionCopy['is_synced'] = transactionCopy['is_synced'] ?? false;
        return transactionCopy;
      }).toList();
      
      // Ambil data transaksi yang sudah ada
      final existingTransactions = await getTransactions() ?? [];
      
      // Gabungkan dengan transaksi baru, hindari duplikasi berdasarkan ID
      final Map<String, Map<String, dynamic>> transactionMap = {};
      
      // Masukkan transaksi yang sudah ada
      for (final transaction in existingTransactions) {
        final id = transaction['id']?.toString();
        if (id != null) {
          transactionMap[id] = transaction;
        }
      }
      
      // Masukkan transaksi baru (akan menimpa jika ID sama)
      for (final transaction in transactionsWithMeta) {
        final id = transaction['id']?.toString();
        if (id != null) {
          transactionMap[id] = transaction;
        }
      }
      
      // Konversi kembali ke list dan urutkan berdasarkan created_at (terbaru dulu)
      final allTransactions = transactionMap.values.toList();
      allTransactions.sort((a, b) {
        final dateA = a['created_at'] ?? '';
        final dateB = b['created_at'] ?? '';
        return dateB.compareTo(dateA);
      });
      
      // Ambil maksimal 50 transaksi terbaru
      final limitedTransactions = allTransactions.take(_maxTransactions).toList();
      
      final jsonString = jsonEncode(limitedTransactions);
      final success = await _setString(_transactionsKey, jsonString);
      
      if (success) {
        await _setString(_lastUpdateKey, DateTime.now().toIso8601String());
        print('LocalStorageService: ${limitedTransactions.length} transaksi berhasil disimpan (DEPRECATED METHOD)');
        return true;
      }
      return false;
    } catch (e) {
      print('LocalStorageService: Error menyimpan transaksi - $e');
      return false;
    }
  }

  /// Ambil data transaksi dari localStorage
  Future<List<Map<String, dynamic>>?> getTransactions() async {
    try {
      if (!isLocalStorageAvailable) return null;
      
      final jsonString = await _getString(_transactionsKey);
      if (jsonString == null || jsonString.isEmpty) {
        print('LocalStorageService: Tidak ada data transaksi di localStorage');
        return null;
      }
      
      final List<dynamic> transactionsJson = jsonDecode(jsonString);
      final transactions = transactionsJson.map((json) => Map<String, dynamic>.from(json)).toList();
      
      print('LocalStorageService: ${transactions.length} transaksi berhasil dimuat dari localStorage');
      return transactions;
    } catch (e) {
      print('LocalStorageService: Error memuat transaksi - $e');
      // Hapus data corrupt
      await clearTransactions();
      return null;
    }
  }

  /// Update status sync transaksi berdasarkan ID
  Future<bool> updateTransactionSyncStatus(List<String> transactionIds, bool isSynced) async {
    try {
      if (!isLocalStorageAvailable) return false;
      
      final transactions = await getTransactions();
      if (transactions == null) return false;
      
      bool hasChanges = false;
      for (final transaction in transactions) {
        final id = transaction['id']?.toString();
        if (id != null && transactionIds.contains(id)) {
          transaction['is_synced'] = isSynced;
          transaction['synced_at'] = isSynced ? DateTime.now().toIso8601String() : null;
          hasChanges = true;
        }
      }
      
      if (hasChanges) {
        final jsonString = jsonEncode(transactions);
        final success = await _setString(_transactionsKey, jsonString);
        if (success) {
          print('LocalStorageService: Status sync ${transactionIds.length} transaksi berhasil diperbarui');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('LocalStorageService: Error memperbarui status sync transaksi - $e');
      return false;
    }
  }

  /// Ambil transaksi yang belum tersinkronisasi
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    try {
      // Gunakan metode khusus untuk transaksi offline yang belum sync
      final unsyncedTransactions = await getUnsyncedOfflineTransactions();
      
      print('LocalStorageService: ${unsyncedTransactions.length} transaksi offline belum tersinkronisasi');
      return unsyncedTransactions;
    } catch (e) {
      print('LocalStorageService: Error mengambil transaksi belum sync - $e');
      return [];
    }
  }

  /// Hapus data transaksi dari localStorage
  Future<void> clearTransactions() async {
    try {
      if (!isLocalStorageAvailable) return;
      await _remove(_transactionsKey);
      print('LocalStorageService: Data transaksi dihapus dari localStorage');
    } catch (e) {
      print('LocalStorageService: Error menghapus data transaksi - $e');
    }
  }

  /// Dapatkan ukuran data localStorage (dalam KB)
  Future<double> getStorageSize() async {
    try {
      if (!isLocalStorageAvailable) return 0.0;
      
      int totalSize = 0;
      final keys = [_productsKey, _paymentMethodsKey, _transactionsKey, _transactionsCacheKey, _transactionsOfflineKey, _lastUpdateKey];
      
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

  // ===== METHODS UNTUK CACHE API TRANSACTIONS =====
  
  /// Simpan cache transaksi dari API ke localStorage (untuk transaksi yang sudah sync)
  Future<bool> saveTransactionsCache(List<Map<String, dynamic>> transactions) async {
    try {
      if (!isLocalStorageAvailable) return false;
      
      // Tambahkan metadata untuk cache API
      final transactionsWithMeta = transactions.map((transaction) {
        final transactionCopy = Map<String, dynamic>.from(transaction);
        transactionCopy['cached_at'] = DateTime.now().toIso8601String();
        transactionCopy['is_synced'] = true; // Data dari API sudah sync
        transactionCopy['source'] = 'api';
        transactionCopy['is_offline'] = false; // Bukan transaksi offline
        return transactionCopy;
      }).toList();
      
      // Urutkan berdasarkan created_at (terbaru dulu)
      transactionsWithMeta.sort((a, b) {
        final dateA = a['created_at'] ?? '';
        final dateB = b['created_at'] ?? '';
        return dateB.compareTo(dateA);
      });
      
      // Ambil maksimal 50 transaksi terbaru
      final limitedTransactions = transactionsWithMeta.take(_maxTransactions).toList();
      
      final jsonString = jsonEncode(limitedTransactions);
      final success = await _setString(_transactionsCacheKey, jsonString);
      
      if (success) {
        print('LocalStorageService: ${limitedTransactions.length} transaksi cache API berhasil disimpan');
        return true;
      }
      return false;
    } catch (e) {
      print('LocalStorageService: Error menyimpan cache transaksi API - $e');
      return false;
    }
  }

  /// Ambil cache transaksi dari API
  Future<List<Map<String, dynamic>>?> getTransactionsCache() async {
    try {
      if (!isLocalStorageAvailable) return null;
      
      final jsonString = await _getString(_transactionsCacheKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> transactionsJson = jsonDecode(jsonString);
      final transactions = transactionsJson.map((json) => Map<String, dynamic>.from(json)).toList();
      
      print('LocalStorageService: ${transactions.length} transaksi cache API dimuat');
      return transactions;
    } catch (e) {
      print('LocalStorageService: Error memuat cache transaksi API - $e');
      return [];
    }
  }

  // ===== METHODS UNTUK OFFLINE TRANSACTIONS =====
  
  /// Simpan transaksi offline ke localStorage (struktur sesuai dengan payload POST API)
  Future<bool> saveOfflineTransaction(Map<String, dynamic> transaction) async {
    try {
      if (!isLocalStorageAvailable) return false;
      
      // Ambil transaksi offline yang sudah ada
      final existingOfflineTransactions = await getOfflineTransactions();
      
      // Pastikan struktur transaksi sesuai dengan payload POST API
      final transactionWithMeta = Map<String, dynamic>.from(transaction);
      
      // Metadata untuk tracking offline (tidak akan dikirim ke API)
      transactionWithMeta['offline_saved_at'] = DateTime.now().toIso8601String();
      transactionWithMeta['is_synced'] = false; // Transaksi offline belum sync
      transactionWithMeta['is_offline'] = true; // Tandai sebagai transaksi offline
      transactionWithMeta['source'] = 'offline';
      
      // Pastikan ada ID unik untuk transaksi offline
      if (transactionWithMeta['id'] == null) {
        transactionWithMeta['id'] = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      // Tambahkan ke list
      existingOfflineTransactions.add(transactionWithMeta);
      
      // Batasi maksimal 100 transaksi offline
      if (existingOfflineTransactions.length > 100) {
        existingOfflineTransactions.removeRange(0, existingOfflineTransactions.length - 100);
      }
      
      // Urutkan berdasarkan created_at (terbaru dulu)
      existingOfflineTransactions.sort((a, b) {
        final dateA = a['created_at'] ?? a['transaction_date'] ?? '';
        final dateB = b['created_at'] ?? b['transaction_date'] ?? '';
        return dateB.compareTo(dateA);
      });
      
      final jsonString = jsonEncode(existingOfflineTransactions);
      final success = await _setString(_transactionsOfflineKey, jsonString);
      
      if (success) {
        print('LocalStorageService: Transaksi offline berhasil disimpan. Total: ${existingOfflineTransactions.length}');
        return true;
      }
      return false;
    } catch (e) {
      print('LocalStorageService: Error menyimpan transaksi offline - $e');
      return false;
    }
  }

  /// Ambil semua transaksi offline
  Future<List<Map<String, dynamic>>> getOfflineTransactions() async {
    try {
      if (!isLocalStorageAvailable) return [];
      
      final jsonString = await _getString(_transactionsOfflineKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> transactionsJson = jsonDecode(jsonString);
      final transactions = transactionsJson.map((json) => Map<String, dynamic>.from(json)).toList();
      
      print('LocalStorageService: ${transactions.length} transaksi offline dimuat');
      return transactions;
    } catch (e) {
      print('LocalStorageService: Error memuat transaksi offline - $e');
      return [];
    }
  }

  /// Update status sync transaksi offline
  Future<bool> updateOfflineTransactionSyncStatus(List<String> transactionIds, bool isSynced) async {
    try {
      if (!isLocalStorageAvailable) return false;
      
      final offlineTransactions = await getOfflineTransactions();
      bool hasChanges = false;
      
      for (final transaction in offlineTransactions) {
        if (transactionIds.contains(transaction['id']?.toString())) {
          transaction['is_synced'] = isSynced;
          transaction['synced_at'] = DateTime.now().toIso8601String();
          hasChanges = true;
        }
      }
      
      if (hasChanges) {
        final jsonString = jsonEncode(offlineTransactions);
        final success = await _setString(_transactionsOfflineKey, jsonString);
        
        if (success) {
          print('LocalStorageService: Status sync ${transactionIds.length} transaksi offline berhasil diupdate');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('LocalStorageService: Error update status sync transaksi offline - $e');
      return false;
    }
  }

  /// Ambil transaksi offline yang belum tersinkronisasi
  Future<List<Map<String, dynamic>>> getUnsyncedOfflineTransactions() async {
    try {
      final offlineTransactions = await getOfflineTransactions();
      final unsyncedTransactions = offlineTransactions.where((transaction) {
        return transaction['is_synced'] != true;
      }).toList();
      
      print('LocalStorageService: ${unsyncedTransactions.length} transaksi offline belum tersinkronisasi');
      return unsyncedTransactions;
    } catch (e) {
      print('LocalStorageService: Error mengambil transaksi offline yang belum sync - $e');
      return [];
    }
  }

  /// Hapus transaksi offline yang sudah tersinkronisasi (opsional)
  Future<bool> cleanupSyncedOfflineTransactions() async {
    try {
      if (!isLocalStorageAvailable) return false;
      
      final offlineTransactions = await getOfflineTransactions();
      final unsyncedTransactions = offlineTransactions.where((transaction) {
        return transaction['is_synced'] != true;
      }).toList();
      
      if (unsyncedTransactions.length != offlineTransactions.length) {
        final jsonString = jsonEncode(unsyncedTransactions);
        final success = await _setString(_transactionsOfflineKey, jsonString);
        
        if (success) {
          final cleanedCount = offlineTransactions.length - unsyncedTransactions.length;
          print('LocalStorageService: $cleanedCount transaksi offline yang sudah sync berhasil dihapus');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('LocalStorageService: Error cleanup transaksi offline - $e');
      return false;
    }
  }

  // ===== MIGRATION METHOD =====
  
  /// Migrasi data dari key lama ke key baru yang terpisah
  Future<void> migrateTransactionData() async {
    try {
      if (!isLocalStorageAvailable) return;
      
      // Cek apakah ada data di key lama
      final oldData = await _getString(_transactionsKey);
      if (oldData == null || oldData.isEmpty) {
        print('LocalStorageService: Tidak ada data lama untuk dimigrasi');
        return;
      }
      
      final List<dynamic> transactionsJson = jsonDecode(oldData);
      final transactions = transactionsJson.map((json) => Map<String, dynamic>.from(json)).toList();
      
      // Pisahkan berdasarkan source atau is_synced
      final apiTransactions = <Map<String, dynamic>>[];
      final offlineTransactions = <Map<String, dynamic>>[];
      
      for (final transaction in transactions) {
        if (transaction['is_synced'] == true || transaction['source'] == 'api') {
          apiTransactions.add(transaction);
        } else {
          offlineTransactions.add(transaction);
        }
      }
      
      // Simpan ke key baru
      if (apiTransactions.isNotEmpty) {
        await saveTransactionsCache(apiTransactions);
      }
      
      if (offlineTransactions.isNotEmpty) {
        for (final transaction in offlineTransactions) {
          await saveOfflineTransaction(transaction);
        }
      }
      
      // Hapus data lama
      await _remove(_transactionsKey);
      
      print('LocalStorageService: Migrasi selesai - ${apiTransactions.length} cache API, ${offlineTransactions.length} offline');
      
    } catch (e) {
      print('LocalStorageService: Error migrasi data - $e');
    }
  }
}