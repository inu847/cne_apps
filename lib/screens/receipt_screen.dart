import 'package:flutter/material.dart';
import 'dart:io' show File, Directory;
import 'dart:async';
import 'package:pdf_render/pdf_render.dart';
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';
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
      // Generate PDF
      final pdfBytes = await receiptService.generateReceiptPdf(widget.receipt);
      
      // Gunakan PlatformService untuk mendapatkan direktori sementara
      final platformService = PlatformService();
      final tempDir = await platformService.getTemporaryDir();
      
      final file = File('${tempDir.path}/receipt_${widget.receipt.invoiceNumber}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      setState(() {
        _pdfFilePath = file.path;
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
        title: const Text('Struk Pembayaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              await receiptService.printReceipt(context, widget.receipt);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pdfFilePath == null
              ? const Center(child: Text('Gagal membuat PDF'))
              : Container(
                  padding: const EdgeInsets.all(8.0),
                  child: PdfView(
                    path: _pdfFilePath!,
                    gestureRecognizers: const {},
                  ),
                )
    );
  }
}