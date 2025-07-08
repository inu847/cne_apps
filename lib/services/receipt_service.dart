import 'dart:io' show Directory, File;
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';

import '../models/receipt_model.dart';
import './platform_service.dart';
import './pdf_service.dart';

// Global key untuk akses Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ReceiptService {
  // Direktori untuk menyimpan file sementara
  static Directory? _tempDir;
  
  // PDF Service untuk generate PDF
  final PdfService _pdfService = PdfService();
  
  // Constructor
  ReceiptService();
  
  // Generate receipt PDF and return bytes
  Future<Uint8List> generateReceiptPdf(Receipt receipt) async {
    // Delegasikan pembuatan PDF ke PdfService
    return await _pdfService.generateReceiptPdf(receipt);
  }
  
  // Inisialisasi direktori sementara menggunakan PlatformService
  Future<Directory> get _tempDirectory async {
    if (_tempDir == null) {
      // Gunakan PlatformService untuk mendapatkan direktori sementara
      final platformService = PlatformService();
      _tempDir = await platformService.getTemporaryDir();
    }
    return _tempDir!;
  }

  // Generate PDF receipt
  Future<pw.Document> _generatePdf(Receipt receipt) async {
    final pdf = pw.Document();
    
    // Load font
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    
    // Add page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, 297 * PdfPageFormat.mm, marginAll: 5 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(receipt.storeName, style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(receipt.storeAddress, style: pw.TextStyle(font: ttf, fontSize: 8)),
              pw.Text('Telp: ${receipt.storePhone}', style: pw.TextStyle(font: ttf, fontSize: 8)),
              pw.Divider(),
              
              // Receipt details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice:', style: pw.TextStyle(font: ttf, fontSize: 8)),
                  pw.Text(receipt.invoiceNumber, style: pw.TextStyle(font: ttf, fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tanggal:', style: pw.TextStyle(font: ttf, fontSize: 8)),
                  pw.Text(
                    '${receipt.transactionDate.day}/${receipt.transactionDate.month}/${receipt.transactionDate.year} ${receipt.transactionDate.hour}:${receipt.transactionDate.minute}',
                    style: pw.TextStyle(font: ttf, fontSize: 8),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pelanggan:', style: pw.TextStyle(font: ttf, fontSize: 8)),
                  pw.Text(receipt.customerName, style: pw.TextStyle(font: ttf, fontSize: 8)),
                ],
              ),
              if (receipt.receiptSettings.receiptShowCashier)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kasir:', style: pw.TextStyle(font: ttf, fontSize: 8)),
                    pw.Text(receipt.cashierName, style: pw.TextStyle(font: ttf, fontSize: 8)),
                  ],
                ),
              pw.Divider(),
              
              // Items
              ...receipt.order.items.map((item) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(item.productName, style: pw.TextStyle(font: ttf, fontSize: 8)),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${item.quantity}x @${item.price}', style: pw.TextStyle(font: ttf, fontSize: 8)),
                      pw.Text('${item.total}', style: pw.TextStyle(font: ttf, fontSize: 8)),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                ],
              )),
              
              // Totals
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: pw.TextStyle(font: ttf, fontSize: 8)),
                  pw.Text('${receipt.order.subtotal.toInt()}', style: pw.TextStyle(font: ttf, fontSize: 8)),
                ],
              ),
              if (receipt.receiptSettings.receiptShowTax)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Pajak:', style: pw.TextStyle(font: ttf, fontSize: 8)),
                    pw.Text('${receipt.order.tax.toInt()}', style: pw.TextStyle(font: ttf, fontSize: 8)),
                  ],
                ),
              if (receipt.discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Diskon:', style: pw.TextStyle(font: ttf, fontSize: 8)),
                    pw.Text('${receipt.discountAmount.toInt()}', style: pw.TextStyle(font: ttf, fontSize: 8)),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('${receipt.order.total.toInt()}', style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              // Payment info
              pw.Divider(),
              pw.Text('PEMBAYARAN', style: pw.TextStyle(font: ttf, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ...receipt.payments.map((payment) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(payment['payment_method_name'] ?? 'Tunai', style: pw.TextStyle(font: ttf, fontSize: 8)),
                  pw.Text('${double.tryParse(payment["amount"].toString())?.toInt() ?? 0}', style: pw.TextStyle(font: ttf, fontSize: 8)),
                ],
              )),
              
              // Footer
              pw.Divider(),
              pw.Text(receipt.receiptSettings.receiptHeader, style: pw.TextStyle(font: ttf, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text(receipt.receiptSettings.receiptFooter, style: pw.TextStyle(font: ttf, fontSize: 8)),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }

  // Menampilkan preview receipt dan opsi cetak


  

  

  
  // Menampilkan dialog untuk melihat PDF receipt
  Future<void> printReceipt(BuildContext context, Receipt receipt) async {
    try {
      // Generate PDF receipt
      final pdfBytes = await generateReceiptPdf(receipt);
      
      // Simpan PDF ke file sementara
      final tempDir = await _tempDirectory;
      final tempFile = File('${tempDir.path}/receipt_${receipt.invoiceNumber}.pdf');
      await tempFile.writeAsBytes(pdfBytes);
      
      // Tampilkan dialog dengan preview PDF
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Struk'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preview Struk:'),
              SizedBox(height: 10),
              Container(
                height: 400,
                width: double.infinity,
                child: PdfView(path: tempFile.path),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing receipt: $e');
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menampilkan struk: ${e.toString()}')),
      );
    }
  }
}