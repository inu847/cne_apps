import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
// import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart'; // Commented out due to NDK issues
import '../models/receipt_model.dart';
import 'platform_service.dart';

// Global navigator key for navigation from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ReceiptService {
  final PlatformService _platformService = PlatformService();
  late Directory _tempDir;
  late File _fontFile;
  
  ReceiptService() {
    _initTempDir();
  }

  Future<void> _initTempDir() async {
    try {
      _tempDir = await _platformService.getTemporaryDir();
      print('Receipt service temp directory: ${_tempDir.path}');
    } catch (e) {
      print('Error initializing temp directory: $e');
    }
  }

  Future<String> generateReceipt(Receipt receipt) async {
    try {
      // Create a PDF file path
      final String pdfPath = '${_tempDir.path}/receipt_${receipt.transactionId}.pdf';
      
      // Generate PDF logic would go here
      // For now, just create a simple text file as placeholder
      final File file = File(pdfPath);
      // Use the total from the order object directly
      double total = receipt.order.total;
      // Apply discount
      total -= receipt.discountAmount;
      
      await file.writeAsString('Receipt for transaction ${receipt.transactionId}\n\nTotal: $total');
      
      return pdfPath;
    } catch (e) {
      print('Error generating receipt: $e');
      return '';
    }
  }

  // Method to show receipt preview
  void showReceiptPreview(BuildContext context, String pdfPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt Preview'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text('PDF preview is temporarily unavailable due to NDK issues.'),
              const SizedBox(height: 10),
              Text('PDF saved at: $pdfPath'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Method to print receipt to thermal printer
  Future<void> printReceipt(BuildContext context, Receipt receipt) async {
    // TODO: Integrate with a thermal printer plugin (e.g., blue_thermal_printer, esc_pos_printer, etc.)
    // For now, show a dialog as a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cetak Struk'),
        content: const Text('Fitur cetak struk ke printer thermal akan segera tersedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}