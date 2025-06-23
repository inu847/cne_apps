# CashNEntry POS Application

## Overview
CashNEntry POS adalah aplikasi point of sale modern yang dirancang untuk memudahkan transaksi bisnis.

## Fitur
- Login sistem yang aman
- Antarmuka pengguna yang intuitif
- Manajemen inventaris
- Pemrosesan transaksi
- Laporan penjualan

## Instalasi

1. Pastikan Flutter SDK telah terinstal di komputer Anda
2. Clone repositori ini
3. Jalankan perintah berikut untuk menginstal dependensi:
   ```
   flutter pub get
   ```
4. Jalankan aplikasi dengan perintah:
   ```
   flutter run
   ```

## Struktur Proyek

- `lib/` - Kode sumber utama
  - `screens/` - Halaman-halaman aplikasi
  - `widgets/` - Komponen UI yang dapat digunakan kembali
  - `models/` - Model data
  - `services/` - Layanan API dan logika bisnis
- `assets/` - Aset aplikasi seperti gambar dan font

## Tampilan Login

Tampilan login dirancang dengan antarmuka modern dan responsif, mengikuti desain dari Figma. Fitur login meliputi:

- Input username dan password
- Opsi "Remember me"
- Tombol "Forgot Password"
- Validasi input

## Pengembangan Selanjutnya

- Implementasi autentikasi
- Penambahan dashboard
- Integrasi dengan sistem pembayaran
- Manajemen pengguna dengan berbagai level akses

## Referensi

- [Flutter Documentation](https://docs.flutter.dev/)
- [Material Design](https://material.io/design)
