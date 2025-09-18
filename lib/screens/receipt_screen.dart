import 'package:flutter/material.dart';
import 'dart:io' show File, Directory;
import 'dart:async';
// import 'package:pdf_render/pdf_render.dart'; // Commented out due to NDK issues
// import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart'; // Commented out due to NDK issues
import 'package:path_provider/path_provider.dart';
import '../models/receipt_model.dart';
import '../services/receipt_service.dart';
import '../services/platform_service.dart';

class ReceiptScreen extends StatefulWidget {
  final Receipt receipt;

  const ReceiptScreen({Key? key, required this.receipt}) : super(key: key);

  @override
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final ReceiptService receiptService = ReceiptService();
  String? _pdfFilePath;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _generateAndSavePdf();
  }
  
  Future<void> _generateAndSavePdf() async {
    try {
      // Generate PDF path
      final pdfPath = await receiptService.generateReceipt(widget.receipt);
      
      setState(() {
        _pdfFilePath = pdfPath;
        _isLoading = false;
      });
      
      setState(() {
        _pdfFilePath = pdfPath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet Kasir - POS | Struk Pembayaran'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pdfFilePath == null
              ? const Center(child: Text('Gagal membuat PDF'))
              : Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Header dengan informasi toko
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.receipt.storeName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.receipt.storeAddress,
                              style: const TextStyle(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            if (widget.receipt.storePhone.isNotEmpty && widget.receipt.storePhone != '-') ...[
                               const SizedBox(height: 4),
                               Text(
                                 'Tel: ${widget.receipt.storePhone}',
                                 style: const TextStyle(fontSize: 14),
                                 textAlign: TextAlign.center,
                               ),
                             ],
                             if (widget.receipt.storeEmail.isNotEmpty && widget.receipt.storeEmail != '-') ...[
                               const SizedBox(height: 4),
                               Text(
                                 'Email: ${widget.receipt.storeEmail}',
                                 style: const TextStyle(fontSize: 14),
                                 textAlign: TextAlign.center,
                               ),
                             ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'PDF preview is temporarily unavailable due to NDK issues.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'PDF saved at: $_pdfFilePath',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Back'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
    );
  }
}