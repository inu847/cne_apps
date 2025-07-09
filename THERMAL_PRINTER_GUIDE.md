# Panduan Fitur Cetak Struk Thermal Printer

## Overview
Fitur cetak struk telah dioptimalkan menggunakan library terbaik untuk printer thermal Bluetooth. Implementasi ini mendukung berbagai jenis printer thermal dengan format ESC/POS.

## Library yang Digunakan

### 1. print_bluetooth_thermal (v1.1.1)
**Mengapa dipilih:**
- ✅ Maintenance status: **Good** 
- ✅ Dart 3 compatible
- ✅ Support Android & iOS
- ✅ Tidak memerlukan location permission untuk koneksi printer
- ✅ API yang sederhana dan stabil
- ✅ Download count tinggi (7.7K)

### 2. esc_pos_utils_plus (v2.0.1)
**Mengapa dipilih:**
- ✅ Maintenance status: **Average**
- ✅ Dart 3 compatible
- ✅ Support untuk ESC/POS commands
- ✅ Support untuk Bluetooth, WiFi/Network, dan USB printers
- ✅ Fitur lengkap: text styling, images, barcodes, tables

### 3. permission_handler (v11.3.1)
**Untuk mengelola:**
- Bluetooth permissions
- Location permissions (Android)
- Runtime permission requests

## Fitur yang Tersedia

### 1. Scanning Printer Bluetooth
- Otomatis scan printer yang sudah dipasangkan (paired)
- Refresh manual untuk update daftar printer
- Tampilan nama dan MAC address printer

### 2. Format Struk yang Optimal
- **Header**: Nama toko, alamat, nomor telepon
- **Info Transaksi**: Nomor invoice, tanggal, kasir, pelanggan
- **Detail Items**: Nama produk, quantity, harga, subtotal
- **Total**: Subtotal, diskon, total akhir
- **Payment**: Metode pembayaran dan jumlah
- **Footer**: Ucapan terima kasih

### 3. Error Handling
- Validasi permission Bluetooth
- Validasi status Bluetooth (aktif/tidak)
- Error handling untuk koneksi printer
- Error handling untuk proses printing

## Cara Penggunaan

### 1. Persiapan
```bash
# Install dependencies
flutter pub get
```

### 2. Setup Printer
1. Pastikan printer thermal Bluetooth sudah dinyalakan
2. Pasangkan printer di pengaturan Bluetooth device
3. Catat nama printer untuk identifikasi

### 3. Menggunakan Fitur Cetak
```dart
// Di transaction detail screen
ElevatedButton(
  onPressed: () => _printReceipt(),
  child: Text('Cetak Struk'),
)

// Method untuk cetak struk
void _printReceipt() async {
  final receipt = _createReceiptFromTransaction();
  await ReceiptService().printReceipt(context, receipt);
}
```

### 4. Flow Pencetakan
1. User tap "Cetak Struk"
2. Sistem check permission Bluetooth
3. Sistem check status Bluetooth
4. Tampilkan dialog pilihan printer
5. User pilih printer dari daftar
6. Sistem connect ke printer
7. Generate ESC/POS commands
8. Kirim data ke printer
9. Disconnect dari printer
10. Tampilkan status hasil

## Konfigurasi Platform

### Android
Permissions sudah dikonfigurasi di `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### iOS
Tambahkan di `ios/Runner/Info.plist`:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth access to connect thermal printers</string>
```

## Troubleshooting

### 1. Printer Tidak Terdeteksi
- Pastikan printer sudah dipasangkan di pengaturan Bluetooth
- Pastikan printer dalam mode pairing/discoverable
- Restart Bluetooth di device
- Tap refresh di dialog printer selection

### 2. Gagal Connect ke Printer
- Pastikan printer tidak sedang digunakan aplikasi lain
- Restart printer
- Hapus pairing dan pasangkan ulang
- Pastikan jarak device dengan printer tidak terlalu jauh

### 3. Hasil Cetak Tidak Sesuai
- Pastikan menggunakan paper size yang benar (58mm/80mm)
- Cek konfigurasi character encoding
- Pastikan printer support ESC/POS commands

### 4. Permission Denied
- Buka pengaturan aplikasi
- Berikan izin Bluetooth dan Location
- Restart aplikasi

## Printer yang Didukung

Library ini mendukung printer thermal yang compatible dengan ESC/POS commands:
- **58mm thermal printers**
- **80mm thermal printers**
- Brand populer: Epson, Star, Citizen, Bixolon, dll
- Generic thermal printers dengan ESC/POS support

## Optimasi Performa

### 1. Connection Management
- Auto disconnect setelah printing
- Timeout handling untuk koneksi
- Retry mechanism untuk koneksi gagal

### 2. Data Transmission
- Chunked data transmission untuk data besar
- Optimized ESC/POS command generation
- Minimal data transfer untuk efisiensi

### 3. Memory Management
- Efficient byte array handling
- Proper disposal of resources
- Minimal memory footprint

## Pengembangan Lanjutan

### 1. Fitur Tambahan yang Bisa Ditambahkan
- QR Code printing
- Barcode printing
- Logo/image printing
- Custom receipt templates
- Printer settings configuration

### 2. Integration dengan Sistem Lain
- Cloud printing
- Network printer support
- Multiple printer management
- Print queue system

## Kesimpulan

Implementasi ini menggunakan kombinasi library terbaik yang tersedia:
- **print_bluetooth_thermal**: Untuk koneksi dan komunikasi Bluetooth
- **esc_pos_utils_plus**: Untuk generate ESC/POS commands
- **permission_handler**: Untuk manajemen permissions

Kombinasi ini memberikan:
- ✅ Stabilitas tinggi
- ✅ Kompatibilitas luas
- ✅ Maintenance yang baik
- ✅ Performance optimal
- ✅ Error handling yang robust

Fitur cetak struk siap digunakan untuk production dengan dukungan berbagai jenis printer thermal Bluetooth.