import 'package:flutter/material.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  final AuthService _authService = AuthService();
  
  StoreSettings? _settings;
  bool _isLoading = false;
  String? _error;

  // Getters
  StoreSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Convenience getters for specific settings
  GeneralSettings get general => _settings?.general ?? _getDefaultGeneralSettings();
  TaxSettings get tax => _settings?.tax ?? _getDefaultTaxSettings();
  ReceiptSettings get receipt => _settings?.receipt ?? _getDefaultReceiptSettings();
  StoreInfoSettings get store => _settings?.store ?? _getDefaultStoreSettings();
  SystemSettings get system => _settings?.system ?? _getDefaultSystemSettings();
  VoucherSettings get voucher => _settings?.voucher ?? _getDefaultVoucherSettings();

  // Initialize settings
  Future<void> initSettings() async {
    await fetchSettings();
  }

  // Fetch settings from API
  Future<void> fetchSettings({String? group, bool refresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get token from AuthService
      final token = await _authService.getToken();
      
      if (token != null) {
        // Set token to SettingsService
        _settingsService.setToken(token);
        
        // Get settings from API
        final settings = await _settingsService.getSettings(group: group, refresh: refresh);
        
        if (settings != null) {
          _settings = settings;
          _error = null;
        } else {
          _error = 'Tidak dapat memuat pengaturan';
        }
      } else {
        _error = 'Token tidak ditemukan. Silakan login kembali.';
      }
    } catch (e) {
      _error = 'Gagal memuat pengaturan: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear cached settings
  Future<void> clearCachedSettings() async {
    await _settingsService.clearCachedSettings();
    _settings = null;
    notifyListeners();
  }

  // Default settings if API fails
  GeneralSettings _getDefaultGeneralSettings() {
    return GeneralSettings(
      storeName: 'My POS Store',
      storeAddress: 'Jl. Contoh No. 123',
      storePhone: '08123456789',
      storeEmail: 'info@myposstore.com',
      currencySymbol: 'Rp',
    );
  }

  TaxSettings _getDefaultTaxSettings() {
    return TaxSettings(
      taxPercentage: '11',
      enableTax: true,
      taxEnabled: true,
      taxName: 'TAX',
    );
  }

  ReceiptSettings _getDefaultReceiptSettings() {
    return ReceiptSettings(
      receiptHeader: 'Terima kasih telah berbelanja',
      receiptFooter: 'Barang yang sudah dibeli tidak dapat dikembalikan',
      enableEmailReceipt: true,
      enableWhatsappReceipt: false,
      receiptShowLogo: true,
      receiptShowTax: true,
      receiptShowCashier: true,
      receiptEmailEnabled: true,
      receiptWhatsappEnabled: false,
      receiptPrinterSize: '80',
    );
  }

  StoreInfoSettings _getDefaultStoreSettings() {
    return StoreInfoSettings(
      storeName: 'My POS Store',
      storeAddress: 'Jl. Contoh No. 123',
      storePhone: '08123456789',
      storeEmail: 'info@myposstore.com',
      storeWebsite: 'https://myposstore.com',
    );
  }

  SystemSettings _getDefaultSystemSettings() {
    return SystemSettings(
      lowStockThreshold: '10',
      defaultCurrency: 'IDR',
      currencySymbol: 'Rp',
      dateFormat: 'Y-m-d',
      timeFormat: 'H:i:s',
      defaultDiscountType: 'percentage',
      isRounded: true,
      roundedDigit: '2',
      pettyCashLimit: '1000',
      pettyCashWarningThreshold: '20',
      pettyCashEnabled: true,
    );
  }

  VoucherSettings _getDefaultVoucherSettings() {
    return VoucherSettings(
      voucherCodePrefix: 'VC',
      voucherCodeLength: '8',
      defaultVoucherType: 'percentage',
      defaultVoucherValue: '10',
      voucherEnabled: true,
    );
  }
}