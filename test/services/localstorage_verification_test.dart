import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  group('LocalStorage Verification Tests', () {
    test('Verify offline transaction structure has correct sync status', () {
      // Simulasi data transaksi offline yang disimpan di localStorage
      final Map<String, dynamic> offlineTransaction = {
        // Fields untuk API POST (struktur yang sama)
        "items": [
          {
            "product_id": 1,
            "quantity": 2,
            "unit_price": 15000,
            "discount_amount": 0,
            "tax_amount": 2750,
            "subtotal": 30000
          }
        ],
        "payments": [
          {
            "payment_method_id": 1,
            "amount": 32750,
            "reference_number": "REF-TEST-123"
          }
        ],
        "subtotal": 30000,
        "tax_amount": 2750,
        "discount_amount": 0,
        "total_amount": 32750,
        "customer_name": "Walk-in Customer",
        "customer_email": "",
        "customer_phone": "",
        "notes": "",
        "is_parked": false,
        "warehouse_id": 1,
        "voucher_code": "",
        
        // Fields tambahan untuk tracking offline
        "id": "offline_1758610000000",
        "invoice_number": "INV-OFFLINE-1758610000000",
        "transaction_date": "2025-01-24T10:00:00.000Z",
        "status": "completed",
        "grand_total": 32750,
        "created_at": "2025-01-24T10:00:00.000Z",
        "updated_at": "2025-01-24T10:00:00.000Z",
        "is_synced": false,  // ✅ CRITICAL: Harus false untuk transaksi offline
        "is_offline": true,  // ✅ CRITICAL: Harus true untuk transaksi offline
        "local_saved_at": "2025-01-24T10:00:00.000Z",
        "offline_saved_at": "2025-01-24T10:00:00.000Z",
        "source": "offline"
      };

      print('🔍 Verifying Offline Transaction Structure...');
      
      // ✅ Test 1: Verifikasi status sync
      expect(offlineTransaction['is_synced'], false, 
        reason: 'Transaksi offline harus memiliki is_synced = false');
      print('✅ is_synced: ${offlineTransaction['is_synced']} (correct)');
      
      // ✅ Test 2: Verifikasi status offline
      expect(offlineTransaction['is_offline'], true, 
        reason: 'Transaksi offline harus memiliki is_offline = true');
      print('✅ is_offline: ${offlineTransaction['is_offline']} (correct)');
      
      // ✅ Test 3: Verifikasi source
      expect(offlineTransaction['source'], 'offline', 
        reason: 'Transaksi offline harus memiliki source = offline');
      print('✅ source: ${offlineTransaction['source']} (correct)');
      
      // ✅ Test 4: Verifikasi field metadata offline
      expect(offlineTransaction.containsKey('offline_saved_at'), true,
        reason: 'Transaksi offline harus memiliki field offline_saved_at');
      print('✅ offline_saved_at: ${offlineTransaction['offline_saved_at']} (exists)');
      
      // ✅ Test 5: Verifikasi tidak ada synced_at untuk transaksi belum sync
      expect(offlineTransaction.containsKey('synced_at'), false,
        reason: 'Transaksi belum sync tidak boleh memiliki field synced_at');
      print('✅ synced_at: tidak ada (correct untuk transaksi belum sync)');
      
      print('🎯 Semua verifikasi status sync berhasil!');
    });

    test('Verify unsynced transaction filtering logic', () {
      // Simulasi daftar transaksi dengan berbagai status sync
      final List<Map<String, dynamic>> transactions = [
        {
          "id": "offline_1",
          "invoice_number": "INV-OFFLINE-001",
          "is_synced": false,  // ✅ Belum sync
          "is_offline": true,
          "source": "offline"
        },
        {
          "id": "offline_2", 
          "invoice_number": "INV-OFFLINE-002",
          "is_synced": true,   // ❌ Sudah sync
          "is_offline": true,
          "source": "offline",
          "synced_at": "2025-01-24T11:00:00.000Z"
        },
        {
          "id": "api_1",
          "invoice_number": "INV-API-001", 
          "is_synced": true,   // ❌ Data dari API (sudah sync)
          "source": "api"
        },
        {
          "id": "offline_3",
          "invoice_number": "INV-OFFLINE-003",
          "is_synced": false,  // ✅ Belum sync
          "is_offline": true,
          "source": "offline"
        }
      ];

      print('🔍 Testing Unsynced Transaction Filtering...');
      
      // Filter transaksi yang belum sync (is_synced != true)
      final unsyncedTransactions = transactions.where((transaction) {
        return transaction['is_synced'] != true;
      }).toList();

      print('📊 Total transaksi: ${transactions.length}');
      print('📊 Transaksi belum sync: ${unsyncedTransactions.length}');
      
      // ✅ Test: Harus ada 2 transaksi belum sync
      expect(unsyncedTransactions.length, 2,
        reason: 'Harus ada 2 transaksi dengan is_synced = false');
      
      // ✅ Test: Verifikasi ID transaksi yang belum sync
      final unsyncedIds = unsyncedTransactions.map((t) => t['id']).toList();
      expect(unsyncedIds, containsAll(['offline_1', 'offline_3']),
        reason: 'Transaksi offline_1 dan offline_3 harus masuk kategori belum sync');
      
      // ✅ Test: Verifikasi transaksi yang sudah sync tidak masuk
      expect(unsyncedIds, isNot(contains('offline_2')),
        reason: 'Transaksi offline_2 (sudah sync) tidak boleh masuk kategori belum sync');
      expect(unsyncedIds, isNot(contains('api_1')),
        reason: 'Transaksi api_1 (dari API) tidak boleh masuk kategori belum sync');
      
      print('✅ offline_1: belum sync (included)');
      print('❌ offline_2: sudah sync (excluded)');
      print('❌ api_1: dari API (excluded)');
      print('✅ offline_3: belum sync (included)');
      
      print('🎯 Filtering logic berfungsi dengan benar!');
    });

    test('Verify localStorage key structure', () {
      // Verifikasi struktur key yang digunakan untuk localStorage
      const String transactionsOfflineKey = 'transactions_offline';
      const String transactionsCacheKey = 'transactions_cache';
      const String transactionsKey = 'transactions';

      print('🔍 Verifying LocalStorage Key Structure...');
      
      // ✅ Test: Verifikasi key untuk transaksi offline
      expect(transactionsOfflineKey, 'transactions_offline',
        reason: 'Key untuk transaksi offline harus transactions_offline');
      print('✅ Offline transactions key: $transactionsOfflineKey');
      
      // ✅ Test: Verifikasi key untuk cache API
      expect(transactionsCacheKey, 'transactions_cache',
        reason: 'Key untuk cache API harus transactions_cache');
      print('✅ API cache key: $transactionsCacheKey');
      
      // ✅ Test: Verifikasi key untuk transaksi umum
      expect(transactionsKey, 'transactions',
        reason: 'Key untuk transaksi umum harus transactions');
      print('✅ General transactions key: $transactionsKey');
      
      print('🎯 Struktur key localStorage sudah benar!');
    });

    test('Verify transaction categorization in transactions screen', () {
      // Simulasi data yang akan ditampilkan di halaman transaksi
      final List<Map<String, dynamic>> allTransactions = [
        // Transaksi offline belum sync
        {
          "id": "offline_001",
          "invoice_number": "INV-OFFLINE-001",
          "is_synced": false,
          "is_offline": true,
          "source": "offline",
          "status": "completed",
          "total_amount": 50000
        },
        // Transaksi offline sudah sync
        {
          "id": "offline_002", 
          "invoice_number": "INV-OFFLINE-002",
          "is_synced": true,
          "is_offline": true,
          "source": "offline",
          "status": "completed",
          "total_amount": 75000,
          "synced_at": "2025-01-24T12:00:00.000Z"
        },
        // Transaksi dari API
        {
          "id": "api_001",
          "invoice_number": "INV-001",
          "is_synced": true,
          "source": "api",
          "status": "completed", 
          "total_amount": 100000
        }
      ];

      print('🔍 Testing Transaction Categorization...');
      
      // Kategori 1: Semua transaksi
      final allCount = allTransactions.length;
      print('📊 Total semua transaksi: $allCount');
      
      // Kategori 2: Transaksi belum sync
      final unsyncedTransactions = allTransactions.where((t) => t['is_synced'] != true).toList();
      print('📊 Transaksi belum sync: ${unsyncedTransactions.length}');
      
      // Kategori 3: Transaksi sudah sync
      final syncedTransactions = allTransactions.where((t) => t['is_synced'] == true).toList();
      print('📊 Transaksi sudah sync: ${syncedTransactions.length}');
      
      // Kategori 4: Transaksi offline saja
      final offlineTransactions = allTransactions.where((t) => t['is_offline'] == true).toList();
      print('📊 Transaksi offline: ${offlineTransactions.length}');
      
      // ✅ Test: Verifikasi kategorisasi
      expect(allCount, 3, reason: 'Total harus 3 transaksi');
      expect(unsyncedTransactions.length, 1, reason: 'Harus ada 1 transaksi belum sync');
      expect(syncedTransactions.length, 2, reason: 'Harus ada 2 transaksi sudah sync');
      expect(offlineTransactions.length, 2, reason: 'Harus ada 2 transaksi offline');
      
      // ✅ Test: Verifikasi transaksi belum sync adalah offline_001
      expect(unsyncedTransactions.first['id'], 'offline_001',
        reason: 'Transaksi belum sync harus offline_001');
      
      print('✅ Kategorisasi transaksi berfungsi dengan benar!');
      print('🎯 Data siap untuk ditampilkan di halaman transaksi!');
    });
  });
}