import 'dart:typed_data';
import 'dart:io' show Directory, File, HttpClient;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:archive/archive.dart';
import '../models/receipt_model.dart';
import '../utils/format_utils.dart';
import './platform_service.dart';

/// A dedicated service for PDF generation operations
/// This service handles all PDF-related functionality to separate concerns
/// and avoid platform-specific issues
class PdfService {
  // Singleton instance
  static final PdfService _instance = PdfService._internal();
  
  // Factory constructor to return the singleton instance
  factory PdfService() => _instance;
  
  // Private constructor
  PdfService._internal();
  
  // Cache for font agar tidak perlu diload ulang setiap kali generate receipt
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;
  
  // Cache untuk logo
  static Uint8List? _cachedLogoBytes;
  
  // Platform service for platform-specific operations
  final PlatformService _platformService = PlatformService();
  
  /// Generates a PDF receipt from a Receipt model
  Future<Uint8List> generateReceiptPdf(Receipt receipt) async {
    // Determine paper size based on settings
    final double width = receipt.receiptSettings.receiptPrinterSize == '80' ? 80 * PdfPageFormat.mm : 58 * PdfPageFormat.mm;
    final double height = 297 * PdfPageFormat.mm; // Standard thermal paper length
    final double margin = 5 * PdfPageFormat.mm;
    
    // Create PDF document with optimization
    final pdf = pw.Document(
      compress: true,
      title: 'Receipt-${receipt.invoiceNumber}',
      author: 'CNE POS',
      creator: 'CNE POS Apps',
      producer: 'CNE POS Apps',
      keywords: 'receipt, invoice, pos',
    );

    // Load fonts with caching for better performance
    final font = _cachedRegularFont ?? await _loadRegularFont();
    final fontBold = _cachedBoldFont ?? await _loadBoldFont();

    // Create custom page format
    final pageFormat = PdfPageFormat(width, height, marginAll: margin);

    // Add content to PDF
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return buildReceiptContent(receipt, font, fontBold);
        },
      ),
    );

    // Save PDF as bytes
    final pdfBytes = await pdf.save();
    
    // Compress PDF for smaller file size (optional, as pdf package already does compression)
    final compressedBytes = GZipEncoder().encode(pdfBytes);
    
    // Return PDF as bytes
    return Uint8List.fromList(compressedBytes ?? pdfBytes);
  }

  /// Builds the content of the receipt
  pw.Widget buildReceiptContent(Receipt receipt, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Header receipt
        if (receipt.receiptSettings.receiptShowLogo)
          pw.SizedBox(height: 10),

        // Store name
        pw.Text(
          receipt.storeName,
          style: pw.TextStyle(font: fontBold, fontSize: 12),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2),

        // Store address
        pw.Text(
          receipt.storeAddress,
          style: pw.TextStyle(font: font, fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2),

        // Store phone
        pw.Text(
          'Telp: ${receipt.storePhone}',
          style: pw.TextStyle(font: font, fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),

        // Divider
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 5),

        // Transaction information
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('No. Invoice:', style: pw.TextStyle(font: font, fontSize: 8)),
            pw.Text(receipt.invoiceNumber, style: pw.TextStyle(font: font, fontSize: 8)),
          ],
        ),
        pw.SizedBox(height: 2),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Tanggal:', style: pw.TextStyle(font: font, fontSize: 8)),
            pw.Text(
              '${receipt.transactionDate.day}/${receipt.transactionDate.month}/${receipt.transactionDate.year} ${receipt.transactionDate.hour}:${receipt.transactionDate.minute}',
              style: pw.TextStyle(font: font, fontSize: 8),
            ),
          ],
        ),
        pw.SizedBox(height: 2),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Pelanggan:', style: pw.TextStyle(font: font, fontSize: 8)),
            pw.Text(receipt.customerName, style: pw.TextStyle(font: font, fontSize: 8)),
          ],
        ),
        pw.SizedBox(height: 2),

        if (receipt.receiptSettings.receiptShowCashier)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Kasir:', style: pw.TextStyle(font: font, fontSize: 8)),
              pw.Text(receipt.cashierName, style: pw.TextStyle(font: font, fontSize: 8)),
            ],
          ),
        pw.SizedBox(height: 5),

        // Divider
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 5),

        // Item header
        pw.Row(
          children: [
            pw.Expanded(
              flex: 5,
              child: pw.Text('Item', style: pw.TextStyle(font: fontBold, fontSize: 8)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Qty', style: pw.TextStyle(font: fontBold, fontSize: 8), textAlign: pw.TextAlign.center),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text('Harga', style: pw.TextStyle(font: fontBold, fontSize: 8), textAlign: pw.TextAlign.right),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text('Total', style: pw.TextStyle(font: fontBold, fontSize: 8), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
        pw.SizedBox(height: 2),

        // Item list
        ...receipt.order.items.map((item) {
          return pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(item.productName, style: pw.TextStyle(font: font, fontSize: 8)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(item.quantity.toString(), style: pw.TextStyle(font: font, fontSize: 8), textAlign: pw.TextAlign.center),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(FormatUtils.formatCurrency(item.price), style: pw.TextStyle(font: font, fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(FormatUtils.formatCurrency(item.total), style: pw.TextStyle(font: font, fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
            ],
          );
        }).toList(),

        // Divider
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 5),

        // Subtotal, tax, discount, total
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Subtotal:', style: pw.TextStyle(font: font, fontSize: 8)),
            pw.Text(FormatUtils.formatCurrency(receipt.order.subtotal.toInt()), style: pw.TextStyle(font: font, fontSize: 8)),
          ],
        ),
        pw.SizedBox(height: 2),

        if (receipt.receiptSettings.receiptShowTax)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Pajak:', style: pw.TextStyle(font: font, fontSize: 8)),
              pw.Text(FormatUtils.formatCurrency(receipt.order.tax.toInt()), style: pw.TextStyle(font: font, fontSize: 8)),
            ],
          ),
        pw.SizedBox(height: 2),

        if (receipt.discountAmount > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Diskon:', style: pw.TextStyle(font: font, fontSize: 8)),
              pw.Text(FormatUtils.formatCurrency(receipt.discountAmount.toInt()), style: pw.TextStyle(font: font, fontSize: 8)),
            ],
          ),
        pw.SizedBox(height: 2),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Total:', style: pw.TextStyle(font: fontBold, fontSize: 10)),
            pw.Text(FormatUtils.formatCurrency(receipt.order.total.toInt()), style: pw.TextStyle(font: fontBold, fontSize: 10)),
          ],
        ),
        pw.SizedBox(height: 5),

        // Payment information
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 5),

        pw.Text('PEMBAYARAN', style: pw.TextStyle(font: fontBold, fontSize: 8), textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 2),

        ...receipt.payments.map((payment) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(payment['payment_method_name'] ?? 'Tunai', style: pw.TextStyle(font: font, fontSize: 8)),
              pw.Text(FormatUtils.formatCurrency(double.tryParse(payment['amount'].toString())?.toInt() ?? 0), style: pw.TextStyle(font: font, fontSize: 8)),
            ],
          );
        }).toList(),
        pw.SizedBox(height: 5),

        // Receipt footer
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 5),

        pw.Text(
          receipt.receiptSettings.receiptHeader,
          style: pw.TextStyle(font: font, fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2),

        pw.Text(
          receipt.receiptSettings.receiptFooter,
          style: pw.TextStyle(font: font, fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  /// Helper method to load regular font with caching
  Future<pw.Font> _loadRegularFont() async {
    if (_cachedRegularFont == null) {
      try {
        // Load font from asset
        final fontData = await rootBundle.load('assets/fonts/Nunito/static/Nunito-Regular.ttf');
        _cachedRegularFont = pw.Font.ttf(fontData.buffer.asByteData());
      } catch (e) {
        // Fallback to default font if font not found
        print('Font Nunito-Regular.ttf not found: $e');
        _cachedRegularFont = pw.Font.helvetica();
      }
    }
    return _cachedRegularFont!;
  }

  /// Helper method to load bold font with caching
  Future<pw.Font> _loadBoldFont() async {
    if (_cachedBoldFont == null) {
      try {
        // Load font from asset
        final fontData = await rootBundle.load('assets/fonts/Nunito/static/Nunito-Bold.ttf');
        _cachedBoldFont = pw.Font.ttf(fontData.buffer.asByteData());
      } catch (e) {
        // Fallback to default font if font not found
        print('Font Nunito/static/Nunito-Bold.ttf not found: $e');
        _cachedBoldFont = pw.Font.helvetica();
      }
    }
    return _cachedBoldFont!;
  }

  /// Helper method to load logo with caching
  Future<Uint8List?> _loadLogoImage(String logoUrl) async {
    try {
      if (_cachedLogoBytes != null) {
        return _cachedLogoBytes;
      }

      final tempDir = await _platformService.getTemporaryDir();
      
      if (kIsWeb) {
        // Web platform handling
        // For web, we need to use different approach since HttpClient is not available
        // This is a placeholder for web-specific implementation
        return null;
      } else if (logoUrl.startsWith('http')) {
        // Load from URL with caching for native platforms
        final cacheKey = Uri.parse(logoUrl).pathSegments.last;
        final cacheFile = File('${tempDir.path}/$cacheKey');
        
        if (await cacheFile.exists()) {
          _cachedLogoBytes = await cacheFile.readAsBytes();
        } else {
          // Download and cache
          final httpClient = HttpClient();
          try {
            final request = await httpClient.getUrl(Uri.parse(logoUrl));
            final response = await request.close();
            
            if (response.statusCode == 200) {
              // Collect all bytes from the response
              final List<List<int>> chunks = [];
              await for (final chunk in response) {
                chunks.add(chunk);
              }
              
              // Flatten the chunks into a single list
              final List<int> bytes = [];
              for (var chunk in chunks) {
                bytes.addAll(chunk);
              }
              
              _cachedLogoBytes = Uint8List.fromList(bytes);
              await cacheFile.writeAsBytes(_cachedLogoBytes!);
            }
          } finally {
            httpClient.close();
          }
        }
      } else if (logoUrl.startsWith('assets/')) {
        // Load from assets
        _cachedLogoBytes = (await rootBundle.load(logoUrl)).buffer.asUint8List();
      } else {
        // Load from local file
        final file = File(logoUrl);
        if (await file.exists()) {
          _cachedLogoBytes = await file.readAsBytes();
        }
      }
      
      return _cachedLogoBytes;
    } catch (e) {
      print('Error loading logo: $e');
      return null;
    }
  }
}