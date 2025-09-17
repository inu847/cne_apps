import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart'; // Commented out due to NDK issues
import '../models/receipt_model.dart';
import 'platform_service.dart';

// Global navigator key for navigation from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ReceiptService {
  final PlatformService _platformService = PlatformService();
  late Directory _tempDir;
  late File _fontFile;
  
  // Printer connection management
  static String? _savedPrinterMac;
  static String? _savedPrinterName;
  static bool _isConnected = false;
  static final List<Receipt> _printQueue = [];
  static bool _isPrinting = false;
  
  ReceiptService() {
    _initTempDir();
    _loadSavedPrinter();
  }

  Future<void> _initTempDir() async {
    try {
      _tempDir = await _platformService.getTemporaryDir();
      print('Receipt service temp directory: ${_tempDir.path}');
    } catch (e) {
      print('Error initializing temp directory: $e');
    }
  }

  // Load saved printer from SharedPreferences
  Future<void> _loadSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedPrinterMac = prefs.getString('saved_printer_mac');
      _savedPrinterName = prefs.getString('saved_printer_name');
      print('Loaded saved printer: $_savedPrinterName ($_savedPrinterMac)');
    } catch (e) {
      print('Error loading saved printer: $e');
    }
  }

  // Save printer to SharedPreferences
  static Future<void> _savePrinter(String mac, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_printer_mac', mac);
      await prefs.setString('saved_printer_name', name);
      _savedPrinterMac = mac;
      _savedPrinterName = name;
      print('Saved printer: $name ($mac)');
    } catch (e) {
      print('Error saving printer: $e');
    }
  }

  // Clear saved printer
  static Future<void> clearSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_printer_mac');
      await prefs.remove('saved_printer_name');
      _savedPrinterMac = null;
      _savedPrinterName = null;
      _isConnected = false;
      await PrintBluetoothThermal.disconnect;
      print('Cleared saved printer');
    } catch (e) {
      print('Error clearing saved printer: $e');
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
    try {
      // Check and request Bluetooth permissions
      if (!await _checkBluetoothPermissions()) {
        _showErrorDialog(context, 'Izin Bluetooth diperlukan untuk mencetak struk.');
        return;
      }

      // Check if Bluetooth is available and enabled
      if (!await PrintBluetoothThermal.bluetoothEnabled) {
        _showErrorDialog(context, 'Bluetooth tidak aktif. Silakan aktifkan Bluetooth terlebih dahulu.');
        return;
      }

      // Add to print queue
      _printQueue.add(receipt);
      
      // If we have a saved printer, try to use it
      if (_savedPrinterMac != null && _savedPrinterName != null) {
        await _processPrintQueue(context);
      } else {
        // Show printer selection dialog
        _showPrinterSelectionDialog(context, receipt);
      }
    } catch (e) {
      print('Error in printReceipt: $e');
      _showErrorDialog(context, 'Terjadi kesalahan: $e');
    }
  }

  // Process print queue
  Future<void> _processPrintQueue(BuildContext context) async {
    if (_isPrinting || _printQueue.isEmpty) return;
    
    _isPrinting = true;
    
    try {
      while (_printQueue.isNotEmpty) {
        final receipt = _printQueue.removeAt(0);
        await _printWithSavedPrinter(context, receipt);
        // Add small delay between prints
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('Error processing print queue: $e');
    } finally {
      _isPrinting = false;
    }
  }

  // Print with saved printer
  Future<void> _printWithSavedPrinter(BuildContext context, Receipt receipt) async {
    try {
      // Check if already connected
      if (!_isConnected) {
        final connected = await PrintBluetoothThermal.connect(macPrinterAddress: _savedPrinterMac!);
        if (!connected) {
          // Connection failed, show printer selection dialog
          _showPrinterSelectionDialog(context, receipt);
          return;
        }
        _isConnected = true;
      }

      // Generate and print receipt
      final commands = await _generateReceiptCommands(receipt);
      final result = await PrintBluetoothThermal.writeBytes(commands);
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Struk berhasil dicetak ke $_savedPrinterName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Gagal mencetak struk');
      }
    } catch (e) {
      print('Error printing with saved printer: $e');
      _isConnected = false;
      // Show printer selection dialog as fallback
      _showPrinterSelectionDialog(context, receipt);
    }
  }

  // Check and request Bluetooth permissions
  Future<bool> _checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      
      return statuses.values.every((status) => status.isGranted);
    }
    return true; // iOS handles permissions differently
  }

  // Show printer selection dialog
  void _showPrinterSelectionDialog(BuildContext context, Receipt receipt) {
    showDialog(
      context: context,
      builder: (context) => PrinterSelectionDialog(
        receipt: receipt,
        savedPrinterName: _savedPrinterName,
        savedPrinterMac: _savedPrinterMac,
      ),
    );
  }

  // Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // Generate ESC/POS commands for receipt printing
  Future<List<int>> _generateReceiptCommands(Receipt receipt) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Simplified header for checker receipt
    if (receipt.isCheckerReceipt) {
      // 1. Hilangkan bagian judul toko - langsung ke indicator checker
      bytes += generator.text(
        '*** STRUK CHECKER ***',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      );
      if (receipt.checkerCategory != null) {
        bytes += generator.text(
          'Kategori: ${receipt.checkerCategory}',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
      }
      // 2. Hapus nomor urutan - tidak menampilkan checkerSequence
      
      bytes += generator.hr();
      bytes += generator.feed(1);

      // 3. Hilangkan informasi kasir - hanya tampilkan invoice dan tanggal
      bytes += generator.text(
        'No. Invoice: ${receipt.invoiceNumber}',
        styles: const PosStyles(bold: true),
      );
      bytes += generator.text(
        'Tanggal: ${_formatDate(receipt.transactionDate)}',
      );
      bytes += generator.text(
        'Pelanggan: ${receipt.customerName}',
      );
      bytes += generator.hr();
      bytes += generator.feed(1);
    } else {
      // Normal receipt header
      // Custom header from settings if available
      if (receipt.receiptSettings.receiptHeader.isNotEmpty) {
        bytes += generator.text(
          receipt.receiptSettings.receiptHeader,
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
          ),
        );
      } else {
        // Default header with store info
        bytes += generator.text(
          receipt.storeName,
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
          ),
        );
        bytes += generator.text(
          receipt.storeAddress,
          styles: const PosStyles(align: PosAlign.center),
        );
        if (receipt.storePhone.isNotEmpty && receipt.storePhone != '-') {
          bytes += generator.text(
            'Tel: ${receipt.storePhone}',
            styles: const PosStyles(align: PosAlign.center),
          );
        }
        if (receipt.storeEmail.isNotEmpty && receipt.storeEmail != '-') {
          bytes += generator.text(
            'Email: ${receipt.storeEmail}',
            styles: const PosStyles(align: PosAlign.center),
          );
        }
      }
      
      bytes += generator.hr();
      bytes += generator.feed(1);

      // Transaction info
      bytes += generator.text(
        'No. Invoice: ${receipt.invoiceNumber}',
        styles: const PosStyles(bold: true),
      );
      bytes += generator.text(
        'Tanggal: ${_formatDate(receipt.transactionDate)}',
      );
      bytes += generator.text(
        'Kasir: ${receipt.cashierName}',
      );
      bytes += generator.text(
        'Pelanggan: ${receipt.customerName}',
      );
      bytes += generator.hr();
      bytes += generator.feed(1);
    }

    // Items
    for (var item in receipt.order.items) {
      bytes += generator.text(
        item.productName,
        styles: const PosStyles(bold: true),
      );
      bytes += generator.row([
        PosColumn(
          text: '${item.quantity} x ${_formatCurrency(item.price.toDouble())}',
          width: 8,
        ),
        PosColumn(
          text: _formatCurrency((item.quantity * item.price).toDouble()),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();

    // Different footer for checker receipt vs normal receipt
    if (receipt.isCheckerReceipt) {
      // 5. Hapus seluruh section berikutnya dan ganti dengan catatan sederhana
      bytes += generator.feed(2);
      bytes += generator.text(
        'Catatan: Struk ini hanya untuk keperluan checker',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      );
    } else {
      // Normal receipt totals and payment info
      // Totals
      bytes += generator.row([
        PosColumn(text: 'Subtotal:', width: 8),
        PosColumn(
          text: _formatCurrency(receipt.order.total),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      if (receipt.discountAmount > 0) {
        bytes += generator.row([
          PosColumn(text: 'Diskon:', width: 8),
          PosColumn(
            text: '-${_formatCurrency(receipt.discountAmount)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      final total = receipt.order.total - receipt.discountAmount;
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL:',
          width: 8,
          styles: const PosStyles(bold: true, height: PosTextSize.size2),
        ),
        PosColumn(
          text: _formatCurrency(total),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size2,
          ),
        ),
      ]);

      bytes += generator.hr();

      // Payment info
      for (var payment in receipt.payments) {
        bytes += generator.row([
          PosColumn(
            text: payment['method'] ?? 'Cash',
            width: 8,
          ),
          PosColumn(
            text: _formatCurrency(double.tryParse(payment['amount']?.toString() ?? '0') ?? 0),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.feed(2);
      
      // Footer from settings
      if (receipt.receiptSettings.receiptFooter.isNotEmpty) {
        bytes += generator.text(
          receipt.receiptSettings.receiptFooter,
          styles: const PosStyles(align: PosAlign.center),
        );
      } else {
        bytes += generator.text(
          'Terima kasih atas kunjungan Anda!',
          styles: const PosStyles(align: PosAlign.center),
        );
      }
    }
    
    bytes += generator.feed(3);
    // bytes += generator.cut();

    return bytes;
  }

  // Format currency
  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  // Format date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Printer Selection Dialog Widget
class PrinterSelectionDialog extends StatefulWidget {
  final Receipt receipt;
  final String? savedPrinterName;
  final String? savedPrinterMac;

  const PrinterSelectionDialog({
    Key? key, 
    required this.receipt,
    this.savedPrinterName,
    this.savedPrinterMac,
  }) : super(key: key);

  @override
  _PrinterSelectionDialogState createState() => _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<PrinterSelectionDialog> {
  List<BluetoothInfo> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _scanForDevices();
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    try {
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      setState(() {
        _devices = devices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      print('Error scanning devices: $e');
    }
  }

  Future<void> _connectAndPrint(BluetoothInfo device) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      // Connect to printer
      final connected = await PrintBluetoothThermal.connect(macPrinterAddress: device.macAdress);
      
      if (connected) {
        setState(() {
          _connectedDevice = device.name;
        });

        // Save printer for future use
        await ReceiptService._savePrinter(device.macAdress, device.name);
        ReceiptService._isConnected = true;

        // Generate receipt commands
        final receiptService = ReceiptService();
        final commands = await receiptService._generateReceiptCommands(widget.receipt);
        
        // Print receipt
        final result = await PrintBluetoothThermal.writeBytes(commands);
        
        if (result) {
          Navigator.pop(context);
          _showSuccessDialog('Struk berhasil dicetak ke ${device.name}!');
          
          // Process any remaining items in queue
          final globalContext = navigatorKey.currentContext;
          if (globalContext != null) {
            await receiptService._processPrintQueue(globalContext);
          }
        } else {
          _showErrorDialog('Gagal mencetak struk.');
          ReceiptService._isConnected = false;
        }
        
        // Don't disconnect - keep connection for future prints
      } else {
        _showErrorDialog('Gagal terhubung ke printer.');
      }
    } catch (e) {
      print('Error connecting and printing: $e');
      _showErrorDialog('Terjadi kesalahan: $e');
      ReceiptService._isConnected = false;
    } finally {
      setState(() {
        _isConnecting = false;
        _connectedDevice = null;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Berhasil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Printer'),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Column(
          children: [
            // Show saved printer if available
            if (widget.savedPrinterName != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Printer Tersimpan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.savedPrinterName!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      widget.savedPrinterMac!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              final receiptService = ReceiptService();
                              await receiptService._printWithSavedPrinter(context, widget.receipt);
                            },
                            icon: const Icon(Icons.print, size: 16),
                            label: const Text('Gunakan Printer Ini'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            await ReceiptService.clearSavedPrinter();
                            setState(() {
                              _scanForDevices();
                            });
                          },
                          icon: const Icon(Icons.change_circle, size: 16),
                          label: const Text('Ubah'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            // Divider if saved printer exists
            if (widget.savedPrinterName != null)
              const Divider(),
            
            // Available printers section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Printer Tersedia',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            if (_isScanning)
               const Padding(
                 padding: EdgeInsets.all(16.0),
                 child: CircularProgressIndicator(),
               )
             else
               Expanded(
              child: _devices.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada printer ditemukan.\nPastikan printer sudah dipasangkan di pengaturan Bluetooth.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final isConnecting = _isConnecting && _connectedDevice == device.name;
                        
                        return ListTile(
                          leading: const Icon(Icons.print),
                          title: Text(device.name),
                          subtitle: Text(device.macAdress),
                          trailing: isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_forward_ios),
                          onTap: _isConnecting ? null : () => _connectAndPrint(device),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _scanForDevices(),
          child: const Text('Refresh'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}