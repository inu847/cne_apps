import 'dart:typed_data';
import 'dart:io' show Directory, File;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf_render/pdf_render.dart' as pdf_render;
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_bluetooth_basic/flutter_bluetooth_basic.dart';
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
  
  // Bluetooth Thermal Printer
  final PrinterBluetoothManager _printerManager = PrinterBluetoothManager();
  List<PrinterBluetooth> _devices = [];
  PrinterBluetooth? _selectedDevice;
  // For print_bluetooth_thermal
  List<BluetoothInfo> _bluetoothDevices = [];
  BluetoothInfo? _selectedBluetoothInfo;
  // Blue Thermal Printer - menggunakan PrintBluetoothThermal sebagai pengganti BlueThermalPrinter
  // karena BlueThermalPrinter tidak tersedia dalam dependensi saat ini
  
  // Constructor
  ReceiptService() {
    final platformService = PlatformService();
    if (!platformService.isWeb) {
      _initPrinters();
    }
  }
  
  // Initialize printers
  void _initPrinters() {
    // Initialize both printer managers
    _printerManager.startScan(Duration(seconds: 4));
    
    _printerManager.scanResults.listen((devices) {
      _devices = devices;
    });
    
    // Initialize print_bluetooth_thermal
    _scanPrintBluetoothThermal();
  }
  
  // Scan for print_bluetooth_thermal devices
  Future<void> _scanPrintBluetoothThermal() async {
    try {
      bool isBluetoothOn = await PrintBluetoothThermal.bluetoothEnabled;
      if (!isBluetoothOn) {
        print('Bluetooth is not enabled');
        return;
      }
      
      _bluetoothDevices = await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      print('Error scanning for print_bluetooth_thermal devices: $e');
    }
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
  
  // Inisialisasi dan scan printer bluetooth
  Future<List<PrinterBluetooth>> scanBluetoothDevices() async {
    final platformService = PlatformService();
    if (platformService.isWeb) {
      // Bluetooth tidak didukung di web
      return [];
    }
    
    try {
      // Scan with esc_pos_bluetooth
      _printerManager.stopScan();
      _printerManager.startScan(Duration(seconds: 4));
      
      // Scan with print_bluetooth_thermal
      await _scanPrintBluetoothThermal();
      
      // Wait for scan to complete
      await Future.delayed(Duration(seconds: 5));
      
      return _devices;
    } catch (e) {
      print('Error scanning for Bluetooth devices: $e');
      return [];
    }
  }

  // Membuat PDF receipt berdasarkan model Receipt
  Future<Uint8List> generateReceiptPdf(Receipt receipt) async {
    // Delegasikan pembuatan PDF ke PdfService
    return await _pdfService.generateReceiptPdf(receipt);
  }

  // This method has been moved to PdfService

  // Menampilkan preview receipt dan opsi cetak

  // Pilih printer bluetooth
  Future<bool> selectPrinter(PrinterBluetooth printer) async {
    final platformService = PlatformService();
    if (platformService.isWeb) return false;
    
    try {
      _selectedDevice = printer;
      
      // Find matching print_bluetooth_thermal device
      for (var device in _bluetoothDevices) {
        if (device.name == printer.name) {
          _selectedBluetoothInfo = device;
          break;
        }
      }
      
      return true;
    } catch (e) {
      print('Error selecting printer: $e');
      return false;
    }
  }
  
  // Pilih printer bluetooth thermal
  Future<bool> selectPrinterThermal(BluetoothInfo printer) async {
    final platformService = PlatformService();
    if (platformService.isWeb) return false;
    
    try {
      _selectedBluetoothInfo = printer;
      
      // Find matching esc_pos_bluetooth device
      for (var device in _devices) {
        if (device.name == printer.name) {
          _selectedDevice = device;
          break;
        }
      }
      
      return true;
    } catch (e) {
      print('Error selecting thermal printer: $e');
      return false;
    }
  }
  
  /// Print with PrintBluetoothThermal
  Future<bool> _printWithBluetoothThermal(Receipt receipt, Uint8List imageBytes) async {
    final platformService = PlatformService();
    if (platformService.isWeb || _selectedBluetoothInfo == null) return false;
    
    try {
      // Connect to printer
      final bool connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: _selectedBluetoothInfo!.macAdress
      );
      
      // Check if connected
      if (connected) {
        // Load capability profile
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile);
        
        // Generate ticket
        List<int> ticket = [];
        
        // Add header
        ticket += generator.text(receipt.storeName, styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
        ticket += generator.text(receipt.storeAddress, styles: PosStyles(align: PosAlign.center));
        ticket += generator.hr();
        
        // Add receipt details
        ticket += generator.text('No. Invoice: ${receipt.invoiceNumber}', styles: PosStyles(align: PosAlign.left));
        ticket += generator.text('Tanggal: ${receipt.transactionDate.day}/${receipt.transactionDate.month}/${receipt.transactionDate.year} ${receipt.transactionDate.hour}:${receipt.transactionDate.minute}', styles: PosStyles(align: PosAlign.left));
        if (receipt.receiptSettings.receiptShowCashier) {
          ticket += generator.text('Kasir: ${receipt.cashierName}', styles: PosStyles(align: PosAlign.left));
        }
        ticket += generator.hr();
        
        // Add items
        for (var item in receipt.order.items) {
          ticket += generator.text(item.productName, styles: PosStyles(align: PosAlign.left));
          ticket += generator.row([
            PosColumn(text: '${item.quantity}x', width: 2),
            PosColumn(text: '@${item.price}', width: 4),
            PosColumn(text: '${item.total}', width: 6, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        
        // Add totals
        ticket += generator.hr();
        ticket += generator.row([
          PosColumn(text: 'Subtotal:', width: 6),
          PosColumn(text: '${receipt.order.subtotal.toInt()}', width: 6, styles: PosStyles(align: PosAlign.right)),
        ]);
        
        if (receipt.receiptSettings.receiptShowTax) {
          ticket += generator.row([
            PosColumn(text: 'Pajak:', width: 6),
            PosColumn(text: '${receipt.order.tax.toInt()}', width: 6, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        
        if (receipt.discountAmount > 0) {
          ticket += generator.row([
            PosColumn(text: 'Diskon:', width: 6),
            PosColumn(text: '${receipt.discountAmount.toInt()}', width: 6, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        
        ticket += generator.row([
          PosColumn(text: 'Total:', width: 6, styles: PosStyles(bold: true)),
          PosColumn(text: '${receipt.order.total.toInt()}', width: 6, styles: PosStyles(bold: true, align: PosAlign.right)),
        ]);
        
        // Add payment info
        ticket += generator.hr();
        ticket += generator.text('PEMBAYARAN', styles: PosStyles(align: PosAlign.center));
        
        for (var payment in receipt.payments) {
          ticket += generator.row([
            PosColumn(text: payment['payment_method_name'] ?? 'Tunai', width: 6),
            PosColumn(text: '${double.tryParse(payment['amount'].toString())?.toInt() ?? 0}', width: 6, styles: PosStyles(align: PosAlign.right)),
          ]);
        }
        
        // Add footer
        ticket += generator.hr();
        ticket += generator.text(receipt.receiptSettings.receiptHeader, styles: PosStyles(align: PosAlign.center));
        ticket += generator.text(receipt.receiptSettings.receiptFooter, styles: PosStyles(align: PosAlign.center));
        ticket += generator.cut();
        
        // Print ticket
        final result = await PrintBluetoothThermal.writeBytes(ticket);
        
        // Disconnect
        await PrintBluetoothThermal.disconnect;
        
        return result;
      }
      return false;
    } catch (e) {
      print('Error printing with PrintBluetoothThermal: $e');
      return false;
    }
  }
  
  /// Print with EscPosBluetooth
  Future<bool> printWithEscPosBluetooth(Receipt receipt, Uint8List imageBytes) async {
    final platformService = PlatformService();
    if (platformService.isWeb || _selectedDevice == null) return false;
    
    try {
      // Create printer
      final PrinterBluetooth printer = _selectedDevice!;
      
      // Connect to printer
      _printerManager.selectPrinter(printer);
      
      // Get printer capabilities
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      
      // Decode image
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return false;
      
      // Resize image to fit printer width
      final resizedImage = img.copyResize(decodedImage, width: 380); // 80mm printer width
      
      // Create ticket
      List<int> bytes = [];
      bytes += generator.text(receipt.storeName, styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text(receipt.storeAddress, styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Telp: ${receipt.storePhone}', styles: PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.text('No. Invoice: ${receipt.invoiceNumber}', styles: PosStyles(align: PosAlign.left));
      bytes += generator.text('Tanggal: ${receipt.transactionDate.day}/${receipt.transactionDate.month}/${receipt.transactionDate.year} ${receipt.transactionDate.hour}:${receipt.transactionDate.minute}', styles: PosStyles(align: PosAlign.left));
      bytes += generator.text('Pelanggan: ${receipt.customerName}', styles: PosStyles(align: PosAlign.left));
      if (receipt.receiptSettings.receiptShowCashier) {
        bytes += generator.text('Kasir: ${receipt.cashierName}', styles: PosStyles(align: PosAlign.left));
      }
      bytes += generator.hr();
      
      // Items
      for (var item in receipt.order.items) {
        bytes += generator.text(item.productName, styles: PosStyles(align: PosAlign.left));
        bytes += generator.row([
          PosColumn(text: '${item.quantity}x', width: 2),
          PosColumn(text: '@${item.price}', width: 4),
          PosColumn(text: '${item.total}', width: 6, styles: PosStyles(align: PosAlign.right)),
        ]);
      }
      
      // Totals
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Subtotal:', width: 6),
        PosColumn(text: '${receipt.order.subtotal.toInt()}', width: 6, styles: PosStyles(align: PosAlign.right)),
      ]);
      
      if (receipt.receiptSettings.receiptShowTax) {
        bytes += generator.row([
          PosColumn(text: 'Pajak:', width: 6),
          PosColumn(text: '${receipt.order.tax.toInt()}', width: 6, styles: PosStyles(align: PosAlign.right)),
        ]);
      }
      
      if (receipt.discountAmount > 0) {
        bytes += generator.row([
          PosColumn(text: 'Diskon:', width: 6),
          PosColumn(text: '${receipt.discountAmount.toInt()}', width: 6, styles: PosStyles(align: PosAlign.right)),
        ]);
      }
      
      bytes += generator.row([
        PosColumn(text: 'Total:', width: 6, styles: PosStyles(bold: true)),
        PosColumn(text: '${receipt.order.total.toInt()}', width: 6, styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);
      
      // Payment info
      bytes += generator.hr();
      bytes += generator.text('PEMBAYARAN', styles: PosStyles(align: PosAlign.center));
      
      for (var payment in receipt.payments) {
        bytes += generator.row([
          PosColumn(text: payment['payment_method_name'] ?? 'Tunai', width: 6),
          PosColumn(text: '${double.tryParse(payment['amount'].toString())?.toInt() ?? 0}', width: 6, styles: PosStyles(align: PosAlign.right)),
        ]);
      }
      
      // Add footer
      bytes += generator.hr();
      bytes += generator.text(receipt.receiptSettings.receiptHeader, styles: PosStyles(align: PosAlign.center));
      bytes += generator.text(receipt.receiptSettings.receiptFooter, styles: PosStyles(align: PosAlign.center));
      
      // Add image if needed
      // bytes += generator.image(imageBytes);
      
      bytes += generator.cut();
      
      // Print ticket
      await _printerManager.printTicket(bytes);
      
      return true;
    } catch (e) {
      print('Error printing with EscPosBluetooth: $e');
      return false;
    }
  }
  
  // Menampilkan dialog untuk memilih printer dan mencetak receipt
  Future<void> printReceipt(BuildContext context, Receipt receipt) async {
    try {
      // Generate PDF receipt
      final pdfBytes = await generateReceiptPdf(receipt);
      
      // Simpan PDF ke file sementara
      final tempDir = await _tempDirectory;
      final tempFile = File('${tempDir.path}/receipt_${receipt.invoiceNumber}.pdf');
      await tempFile.writeAsBytes(pdfBytes);
      
      // Tampilkan dialog untuk memilih printer
      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Cetak Struk'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview PDF
                Container(
                  height: 200,
                  width: double.infinity,
                  child: PdfView(path: tempFile.path),
                ),
                SizedBox(height: 20),
                
                // Printer selection
                Builder(builder: (context) {
                  final platformService = PlatformService();
                  return !platformService.isWeb
                    ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ESC/POS Bluetooth Printers:', style: TextStyle(fontWeight: FontWeight.bold)),
                      FutureBuilder<List<PrinterBluetooth>>(
                        future: scanBluetoothDevices(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('No printers found');
                          }
                          
                          return DropdownButton<PrinterBluetooth>(
                            hint: const Text('Select printer'),
                            value: _selectedDevice,
                            onChanged: (device) async {
                              if (device != null) {
                                await selectPrinter(device);
                                setState(() {});
                              }
                            },
                            items: snapshot.data!.map((device) {
                              return DropdownMenuItem<PrinterBluetooth>(
                                value: device,
                                child: Text(device.name ?? 'Unknown'),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      
                      SizedBox(height: 10),
                      
                      Text('Thermal Bluetooth Printers:', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<BluetoothInfo>(
                        hint: const Text('Select thermal printer'),
                        value: _selectedBluetoothInfo,
                        onChanged: (device) async {
                          if (device != null) {
                            await selectPrinterThermal(device);
                            setState(() {});
                          }
                        },
                        items: _bluetoothDevices.map((device) {
                          return DropdownMenuItem<BluetoothInfo>(
                            value: device,
                            child: Text(device.name),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                    : SizedBox.shrink();
                }),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    bool success = false;
                    
                    // Cek platform
                    final platformService = PlatformService();
                    if (platformService.isWeb) {
                      // Web tidak mendukung printer bluetooth
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Printing not supported on web')),
                      );
                      return;
                    }
                    
                    // Convert PDF to image for thermal printing
                    final pdfDocument = await pdf_render.PdfDocument.openData(pdfBytes);
                    final pdfPage = await pdfDocument.getPage(1);
                    final pageImage = await pdfPage.render();
                    // Menggunakan bytes() sebagai pengganti toPng() yang tidak tersedia
                    final pngBytes = pageImage.pixels!;
                    
                    // Try printing with different methods
                    if (_selectedBluetoothInfo != null) {
                      success = await _printWithBluetoothThermal(receipt, pngBytes);
                    }
                    
                    if (!success && _selectedDevice != null) {
                      success = await printWithEscPosBluetooth(receipt, pngBytes);
                    }
                    
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal mencetak struk')),
                      );
                    }
                    
                    Navigator.pop(context);
                  } catch (e) {
                    // Tampilkan pesan error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal mencetak: ${e.toString()}')),
                    );
                  }
                },
                child: Text('Cetak'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error in printReceipt: $e');
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencetak: ${e.toString()}')),
      );
    }
  }
}