# Offline Transaction Structure Documentation

## ✅ Implementasi Selesai

Struktur data transaksi offline telah diperbarui untuk **sepenuhnya sesuai** dengan format API POST endpoint yang digunakan oleh POS system.

## 📋 Struktur Data yang Disimpan

### **API POST Structure (Target)**
```json
{
  "items": [
    {
      "product_id": int,
      "quantity": int,
      "unit_price": int,
      "discount_amount": int,
      "tax_amount": int,
      "subtotal": int
    }
  ],
  "payments": [
    {
      "payment_method_id": int,
      "amount": int,
      "reference_number": string
    }
  ],
  "subtotal": int,
  "tax_amount": int,
  "discount_amount": int,
  "total_amount": int,
  "customer_name": string,
  "customer_email": string,
  "customer_phone": string,
  "notes": string,
  "is_parked": bool,
  "warehouse_id": int,
  "voucher_code": string
}
```

### **Offline Storage Structure (Implementasi Saat Ini)**
```json
{
  // ✅ FIELDS UNTUK API POST (STRUKTUR YANG SAMA)
  "items": [
    {
      "product_id": int,           // ✅ Mapped dari productId/product_id
      "quantity": int,             // ✅ Direct mapping
      "unit_price": int,           // ✅ Mapped dari price/unit_price
      "discount_amount": 0,        // ✅ Default 0, bisa disesuaikan
      "tax_amount": int,           // ✅ Calculated proportionally
      "subtotal": int              // ✅ Calculated (unit_price * quantity)
    }
  ],
  "payments": [
    {
      "payment_method_id": int,    // ✅ Mapped dari paymentMethodId/payment_method_id
      "amount": int,               // ✅ Direct mapping
      "reference_number": string   // ✅ Mapped dari referenceNumber/reference_number
    }
  ],
  "subtotal": int,                 // ✅ Direct mapping
  "tax_amount": int,               // ✅ Direct mapping
  "discount_amount": int,          // ✅ Direct mapping
  "total_amount": int,             // ✅ Direct mapping
  "customer_name": string,         // ✅ Default "Walk-in Customer"
  "customer_email": string,        // ✅ Optional
  "customer_phone": string,        // ✅ Optional
  "notes": string,                 // ✅ Default ""
  "is_parked": bool,               // ✅ Direct mapping
  "warehouse_id": int,             // ✅ Default 1
  "voucher_code": string,          // ✅ Optional
  
  // FIELDS TAMBAHAN UNTUK TRACKING OFFLINE
  "id": "offline_timestamp",       // Unique offline ID
  "invoice_number": "INV-OFFLINE-timestamp",
  "transaction_date": "ISO string",
  "status": "completed/parked",
  "grand_total": int,              // Alias untuk total_amount
  "created_at": "ISO string",
  "updated_at": "ISO string",
  "is_synced": false,              // Tracking sync status
  "is_offline": true,              // Marking as offline transaction
  "local_saved_at": "ISO string"   // Local save timestamp
}
```

## 🔧 Fitur Implementasi

### **1. Format Items yang Sesuai API**
- ✅ **product_id**: Mapped dari `productId` atau `product_id`
- ✅ **quantity**: Direct mapping
- ✅ **unit_price**: Mapped dari `price` atau `unit_price`
- ✅ **discount_amount**: Default 0 (dapat disesuaikan per item)
- ✅ **tax_amount**: Dihitung proporsional berdasarkan subtotal item
- ✅ **subtotal**: Dihitung otomatis (unit_price × quantity)

### **2. Format Payments yang Sesuai API**
- ✅ **payment_method_id**: Mapped dari `paymentMethodId` atau `payment_method_id`
- ✅ **amount**: Direct mapping
- ✅ **reference_number**: Mapped dari `referenceNumber` atau `reference_number`
- ✅ **Default payment**: Cash (ID: 1) jika tidak ada payment yang diberikan

### **3. Perhitungan Tax yang Akurat**
```dart
// Distribusi pajak per item berdasarkan proporsi subtotal
final itemTaxAmount = subtotal > 0 
    ? (itemSubtotal * taxAmount / subtotal).round() 
    : 0;
```

### **4. Field Mapping yang Fleksibel**
Mendukung berbagai format input:
- `productId` ↔ `product_id`
- `price` ↔ `unit_price`
- `paymentMethodId` ↔ `payment_method_id`
- `referenceNumber` ↔ `reference_number`

## 🧪 Testing & Validasi

### **Test Results**
```
✅ All structure validations passed!
✅ Tax distribution calculation is correct!
✅ Field mapping handles different input formats correctly!
✅ All tests passed!
```

### **Test Coverage**
1. **Structure Validation**: Memverifikasi semua field yang diperlukan ada
2. **Tax Distribution**: Memverifikasi perhitungan pajak per item akurat
3. **Field Mapping**: Memverifikasi mapping field dari berbagai format input

## 🔄 Proses Sinkronisasi

### **1. Penyimpanan Offline**
```dart
// Data disimpan dengan struktur yang sama persis dengan API POST
await _localStorageService.saveOfflineTransaction(offlineTransaction);
```

### **2. Sinkronisasi ke Server**
```dart
// Data langsung dikirim tanpa transformasi tambahan
final response = await http.post(
  Uri.parse(ApiConfig.transactionsEndpoint),
  body: jsonEncode(requestBody), // requestBody sudah sesuai format API
);
```

### **3. Update Status**
```dart
// Update status sync setelah berhasil
transaction['is_synced'] = true;
transaction['synced_at'] = DateTime.now().toIso8601String();
```

## 📊 Keuntungan Implementasi

1. **Konsistensi Data**: Struktur offline sama persis dengan API POST
2. **Sinkronisasi Mudah**: Tidak perlu transformasi data saat sync
3. **Debugging Mudah**: Format data yang konsisten memudahkan troubleshooting
4. **Maintainability**: Perubahan API structure mudah diadaptasi
5. **Data Integrity**: Semua field yang diperlukan API tersedia di offline storage

## 🎯 Kesimpulan

✅ **SELESAI**: Struktur data transaksi offline telah **sepenuhnya sesuai** dengan format API POST endpoint.

✅ **TESTED**: Semua test validasi berhasil dan struktur data telah diverifikasi.

✅ **READY**: Aplikasi siap untuk mode offline dengan sinkronisasi yang seamless.