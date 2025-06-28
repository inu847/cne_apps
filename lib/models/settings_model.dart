import 'dart:convert';

class StoreSettings {
  final GeneralSettings general;
  final TaxSettings tax;
  final ReceiptSettings receipt;
  final StoreInfoSettings store;
  final SystemSettings system;
  final VoucherSettings voucher;

  StoreSettings({
    required this.general,
    required this.tax,
    required this.receipt,
    required this.store,
    required this.system,
    required this.voucher,
  });

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      general: GeneralSettings.fromJson(json['general'] ?? {}),
      tax: TaxSettings.fromJson(json['tax'] ?? {}),
      receipt: ReceiptSettings.fromJson(json['receipt'] ?? {}),
      store: StoreInfoSettings.fromJson(json['store'] ?? {}),
      system: SystemSettings.fromJson(json['system'] ?? {}),
      voucher: VoucherSettings.fromJson(json['voucher'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'general': general.toJson(),
      'tax': tax.toJson(),
      'receipt': receipt.toJson(),
      'store': store.toJson(),
      'system': system.toJson(),
      'voucher': voucher.toJson(),
    };
  }
}

class GeneralSettings {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String storeEmail;
  final String currencySymbol;
  final String cashierName;

  GeneralSettings({
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.storeEmail,
    required this.currencySymbol,
    this.cashierName = 'Kasir',
  });

  factory GeneralSettings.fromJson(Map<String, dynamic> json) {
    return GeneralSettings(
      storeName: json['store_name'] ?? '',
      storeAddress: json['store_address'] ?? '',
      storePhone: json['store_phone'] ?? '',
      storeEmail: json['store_email'] ?? '',
      currencySymbol: json['currency_symbol'] ?? 'Rp',
      cashierName: json['cashier_name'] ?? 'Kasir',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_name': storeName,
      'store_address': storeAddress,
      'store_phone': storePhone,
      'store_email': storeEmail,
      'currency_symbol': currencySymbol,
      'cashier_name': cashierName,
    };
  }
}

class TaxSettings {
  final String taxPercentage;
  final bool enableTax;
  final bool taxEnabled;
  final String taxName;

  TaxSettings({
    required this.taxPercentage,
    required this.enableTax,
    required this.taxEnabled,
    required this.taxName,
  });

  factory TaxSettings.fromJson(Map<String, dynamic> json) {
    return TaxSettings(
      taxPercentage: json['tax_percentage'] ?? '0',
      enableTax: json['enable_tax'] == 'true' || json['enable_tax'] == '1',
      taxEnabled: json['tax_enabled'] == '1' || json['tax_enabled'] == 'true',
      taxName: json['tax_name'] ?? 'TAX',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tax_percentage': taxPercentage,
      'enable_tax': enableTax ? 'true' : 'false',
      'tax_enabled': taxEnabled ? '1' : '0',
      'tax_name': taxName,
    };
  }
}

class ReceiptSettings {
  final String receiptHeader;
  final String receiptFooter;
  final bool enableEmailReceipt;
  final bool enableWhatsappReceipt;
  final bool receiptShowLogo;
  final bool receiptShowTax;
  final bool receiptShowCashier;
  final bool receiptEmailEnabled;
  final bool receiptWhatsappEnabled;
  final String receiptPrinterSize;

  ReceiptSettings({
    required this.receiptHeader,
    required this.receiptFooter,
    required this.enableEmailReceipt,
    required this.enableWhatsappReceipt,
    required this.receiptShowLogo,
    required this.receiptShowTax,
    required this.receiptShowCashier,
    required this.receiptEmailEnabled,
    required this.receiptWhatsappEnabled,
    required this.receiptPrinterSize,
  });

  factory ReceiptSettings.fromJson(Map<String, dynamic> json) {
    return ReceiptSettings(
      receiptHeader: json['receipt_header'] ?? '',
      receiptFooter: json['receipt_footer'] ?? '',
      enableEmailReceipt: json['enable_email_receipt'] == 'true' || json['enable_email_receipt'] == '1',
      enableWhatsappReceipt: json['enable_whatsapp_receipt'] == 'true' || json['enable_whatsapp_receipt'] == '1',
      receiptShowLogo: json['receipt_show_logo'] == '1' || json['receipt_show_logo'] == 'true',
      receiptShowTax: json['receipt_show_tax'] == '1' || json['receipt_show_tax'] == 'true',
      receiptShowCashier: json['receipt_show_cashier'] == '1' || json['receipt_show_cashier'] == 'true',
      receiptEmailEnabled: json['receipt_email_enabled'] == '1' || json['receipt_email_enabled'] == 'true',
      receiptWhatsappEnabled: json['receipt_whatsapp_enabled'] == '1' || json['receipt_whatsapp_enabled'] == 'true',
      receiptPrinterSize: json['receipt_printer_size'] ?? '80',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'enable_email_receipt': enableEmailReceipt ? 'true' : 'false',
      'enable_whatsapp_receipt': enableWhatsappReceipt ? 'true' : 'false',
      'receipt_show_logo': receiptShowLogo ? '1' : '0',
      'receipt_show_tax': receiptShowTax ? '1' : '0',
      'receipt_show_cashier': receiptShowCashier ? '1' : '0',
      'receipt_email_enabled': receiptEmailEnabled ? '1' : '0',
      'receipt_whatsapp_enabled': receiptWhatsappEnabled ? '1' : '0',
      'receipt_printer_size': receiptPrinterSize,
    };
  }
}

class StoreInfoSettings {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String storeEmail;
  final String storeWebsite;

  StoreInfoSettings({
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.storeEmail,
    required this.storeWebsite,
  });

  factory StoreInfoSettings.fromJson(Map<String, dynamic> json) {
    return StoreInfoSettings(
      storeName: json['store_name'] ?? '',
      storeAddress: json['store_address'] ?? '',
      storePhone: json['store_phone'] ?? '',
      storeEmail: json['store_email'] ?? '',
      storeWebsite: json['store_website'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_name': storeName,
      'store_address': storeAddress,
      'store_phone': storePhone,
      'store_email': storeEmail,
      'store_website': storeWebsite,
    };
  }
}

class SystemSettings {
  final String lowStockThreshold;
  final String defaultCurrency;
  final String currencySymbol;
  final String dateFormat;
  final String timeFormat;
  final String defaultDiscountType;
  final bool isRounded;
  final String roundedDigit;
  final String pettyCashLimit;
  final String pettyCashWarningThreshold;
  final bool pettyCashEnabled;

  SystemSettings({
    required this.lowStockThreshold,
    required this.defaultCurrency,
    required this.currencySymbol,
    required this.dateFormat,
    required this.timeFormat,
    required this.defaultDiscountType,
    required this.isRounded,
    required this.roundedDigit,
    required this.pettyCashLimit,
    required this.pettyCashWarningThreshold,
    required this.pettyCashEnabled,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      lowStockThreshold: json['low_stock_threshold'] ?? '10',
      defaultCurrency: json['default_currency'] ?? 'IDR',
      currencySymbol: json['currency_symbol'] ?? 'Rp',
      dateFormat: json['date_format'] ?? 'Y-m-d',
      timeFormat: json['time_format'] ?? 'H:i:s',
      defaultDiscountType: json['default_discount_type'] ?? 'percentage',
      isRounded: json['is_rounded'] == '1' || json['is_rounded'] == 'true',
      roundedDigit: json['rounded_digit'] ?? '2',
      pettyCashLimit: json['petty_cash_limit'] ?? '1000',
      pettyCashWarningThreshold: json['petty_cash_warning_threshold'] ?? '20',
      pettyCashEnabled: json['petty_cash_enabled'] == '1' || json['petty_cash_enabled'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'low_stock_threshold': lowStockThreshold,
      'default_currency': defaultCurrency,
      'currency_symbol': currencySymbol,
      'date_format': dateFormat,
      'time_format': timeFormat,
      'default_discount_type': defaultDiscountType,
      'is_rounded': isRounded ? '1' : '0',
      'rounded_digit': roundedDigit,
      'petty_cash_limit': pettyCashLimit,
      'petty_cash_warning_threshold': pettyCashWarningThreshold,
      'petty_cash_enabled': pettyCashEnabled ? '1' : '0',
    };
  }
}

class VoucherSettings {
  final String voucherCodePrefix;
  final String voucherCodeLength;
  final String defaultVoucherType;
  final String defaultVoucherValue;
  final bool voucherEnabled;

  VoucherSettings({
    required this.voucherCodePrefix,
    required this.voucherCodeLength,
    required this.defaultVoucherType,
    required this.defaultVoucherValue,
    required this.voucherEnabled,
  });

  factory VoucherSettings.fromJson(Map<String, dynamic> json) {
    return VoucherSettings(
      voucherCodePrefix: json['voucher_code_prefix'] ?? 'VC',
      voucherCodeLength: json['voucher_code_length'] ?? '8',
      defaultVoucherType: json['default_voucher_type'] ?? 'percentage',
      defaultVoucherValue: json['default_voucher_value'] ?? '10',
      voucherEnabled: json['voucher_enabled'] == '1' || json['voucher_enabled'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voucher_code_prefix': voucherCodePrefix,
      'voucher_code_length': voucherCodeLength,
      'default_voucher_type': defaultVoucherType,
      'default_voucher_value': defaultVoucherValue,
      'voucher_enabled': voucherEnabled ? '1' : '0',
    };
  }
}