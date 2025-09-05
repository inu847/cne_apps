import '../models/order_model.dart';
import '../models/settings_model.dart';

class Receipt {
  final String invoiceNumber;
  final String transactionId; // Added for compatibility with receipt_service
  final Order order;
  final String customerName;
  final DateTime transactionDate;
  final List<Map<String, dynamic>> payments;
  final String? voucherCode;
  final String? voucherName;
  final double discountAmount;
  final ReceiptSettings receiptSettings;
  final String cashierName;
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String storeEmail;

  Receipt({
    required this.invoiceNumber,
    String? transactionId,
    required this.order,
    required this.customerName,
    required this.transactionDate,
    required this.payments,
    this.voucherCode,
    this.voucherName,
    required this.discountAmount,
    required this.receiptSettings,
    required this.cashierName,
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.storeEmail,
  }) : this.transactionId = transactionId ?? invoiceNumber;

  // Membuat Receipt dari data transaksi
  factory Receipt.fromTransaction({
    required Map<String, dynamic> transaction,
    required Order order,
    required ReceiptSettings receiptSettings,
    required String cashierName,
    required String storeName,
    required String storeAddress,
    required String storePhone,
    required String storeEmail,
  }) {
    return Receipt(
      invoiceNumber: transaction['invoice_number'] ?? '',
      transactionId: transaction['id']?.toString() ?? transaction['invoice_number'] ?? '',
      order: order,
      customerName: transaction['customer_name'] ?? 'Pelanggan Umum',
      transactionDate: DateTime.parse(transaction['created_at'] ?? DateTime.now().toIso8601String()),
      payments: List<Map<String, dynamic>>.from(transaction['payments'] ?? []),
      voucherCode: transaction['voucher_code'],
      voucherName: transaction['voucher_name'],
      discountAmount: double.tryParse(transaction['discount_amount']?.toString() ?? '0') ?? 0,
      receiptSettings: receiptSettings,
      cashierName: cashierName,
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      storeEmail: storeEmail,
    );
  }
}