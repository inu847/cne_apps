import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/stock_movement_provider.dart';
import '../providers/product_provider.dart';
import '../models/stock_movement_model.dart';
import '../models/product_model.dart';
import '../config/api_config.dart';
import '../utils/currency_formatter.dart';

class BulkStockMovementScreen extends StatefulWidget {
  const BulkStockMovementScreen({super.key});

  @override
  State<BulkStockMovementScreen> createState() => _BulkStockMovementScreenState();
}

class _BulkStockMovementScreenState extends State<BulkStockMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  
  List<BulkStockMovementRow> _rows = [];
  bool _isLoading = false;
  String _globalNotes = '';
  DateTime _movementDate = DateTime.now();
  
  final TextEditingController _globalNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addNewRow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).initProducts();
    });
  }

  @override
  void dispose() {
    _globalNotesController.dispose();
    _scrollController.dispose();
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addNewRow() {
    setState(() {
      _rows.add(BulkStockMovementRow());
    });
  }

  void _removeRow(int index) {
    if (_rows.length > 1) {
      setState(() {
        _rows[index].dispose();
        _rows.removeAt(index);
      });
    }
  }

  Future<void> _submitBulkMovements() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua field yang diperlukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that all rows have valid data
    List<BulkStockMovementItem> stockItems = [];
    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      if (row.productId == null || row.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Baris ${i + 1}: Produk dan kuantitas harus diisi'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      stockItems.add(BulkStockMovementItem(
        productId: row.productId!,
        sourceType: row.sourceType,
        quantityChange: row.type == 'in' ? row.quantity.toDouble() : -row.quantity.toDouble(),
        unitCost: row.unitCost,
        notes: row.notes.isNotEmpty ? row.notes : null,
      ));
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<StockMovementProvider>(context, listen: false);
      final request = BulkCreateStockMovementRequest(
        movementDate: _movementDate,
        notes: _globalNotes.isNotEmpty ? _globalNotes : null,
        stockItems: stockItems,
      );
      
      final success = await provider.createBulkStockMovements(request);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${stockItems.length} pergerakan stok berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuat pergerakan stok'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: ApiConfig.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Input Massal Pergerakan Stok',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: ApiConfig.primaryColor,
        foregroundColor: ApiConfig.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _addNewRow,
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Baris',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Global Settings Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengaturan Global',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ApiConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Pergerakan',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          controller: TextEditingController(
                            text: DateFormat('dd/MM/yyyy').format(_movementDate),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _movementDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                _movementDate = date;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _globalNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Default',
                      hintText: 'Catatan untuk semua pergerakan (opsional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) => _globalNotes = value,
                  ),
                ],
              ),
            ),

            // Header Row
            if (!isMobile)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ApiConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: Text('Produk', style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(flex: 2, child: Text('Tipe', style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(flex: 2, child: Text('Kuantitas', style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(flex: 2, child: Text('Alasan', style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(flex: 2, child: Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 48), // Space for delete button
                  ],
                ),
              ),

            // Rows List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _rows.length,
                itemBuilder: (context, index) {
                  return _buildMovementRow(index, isMobile);
                },
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addNewRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Baris'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ApiConfig.primaryColor,
                        side: BorderSide(color: ApiConfig.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitBulkMovements,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Semua'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ApiConfig.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementRow(int index, bool isMobile) {
    final row = _rows[index];
    
    if (isMobile) {
      return _buildMobileRow(index, row);
    } else {
      return _buildDesktopRow(index, row);
    }
  }

  Widget _buildMobileRow(int index, BulkStockMovementRow row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Baris ${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ApiConfig.primaryColor,
                ),
              ),
              const Spacer(),
              if (_rows.length > 1)
                IconButton(
                  onPressed: () => _removeRow(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProductDropdown(row),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTypeDropdown(row)),
              const SizedBox(width: 12),
              Expanded(child: _buildQuantityField(row)),
            ],
          ),
          const SizedBox(height: 12),
          _buildUnitCostField(row),
          const SizedBox(height: 12),
          _buildNotesField(row),
        ],
      ),
    );
  }

  Widget _buildDesktopRow(int index, BulkStockMovementRow row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildProductDropdown(row)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _buildTypeDropdown(row)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _buildQuantityField(row)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: _buildUnitCostField(row)),
            const SizedBox(width: 8),
          Expanded(flex: 2, child: _buildNotesField(row)),
          const SizedBox(width: 8),
          if (_rows.length > 1)
            IconButton(
              onPressed: () => _removeRow(index),
              icon: const Icon(Icons.delete, color: Colors.red),
              iconSize: 20,
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildProductDropdown(BulkStockMovementRow row) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return DropdownButtonFormField<int>(
          value: row.productId,
          decoration: const InputDecoration(
            labelText: 'Produk',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          validator: (value) => value == null ? 'Pilih produk' : null,
          items: productProvider.products.map((Product product) {
            return DropdownMenuItem<int>(
              value: product.id,
              child: Text(
                product.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              row.productId = value;
            });
          },
          isExpanded: true,
        );
      },
    );
  }

  Widget _buildTypeDropdown(BulkStockMovementRow row) {
    return DropdownButtonFormField<String>(
      value: row.type,
      decoration: const InputDecoration(
        labelText: 'Tipe',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(value: 'in', child: Text('Masuk')),
        DropdownMenuItem(value: 'out', child: Text('Keluar')),
      ],
      onChanged: (value) {
        setState(() {
          row.type = value!;
        });
      },
    );
  }

  Widget _buildQuantityField(BulkStockMovementRow row) {
    return TextFormField(
      controller: row.quantityController,
      decoration: const InputDecoration(
        labelText: 'Kuantitas',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Masukkan kuantitas';
        final quantity = int.tryParse(value);
        if (quantity == null || quantity <= 0) return 'Kuantitas harus > 0';
        return null;
      },
      onChanged: (value) {
        row.quantity = int.tryParse(value) ?? 0;
      },
    );
  }

  Widget _buildUnitCostField(BulkStockMovementRow row) {
    return TextFormField(
      controller: row.unitCostController,
      decoration: const InputDecoration(
        labelText: 'Harga Satuan',
        hintText: 'Opsional',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        prefixText: 'Rp ',
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        row.unitCost = double.tryParse(value);
      },
    );
  }

  Widget _buildNotesField(BulkStockMovementRow row) {
    return TextFormField(
      controller: row.notesController,
      decoration: const InputDecoration(
        labelText: 'Catatan',
        hintText: 'Kosongkan untuk gunakan default',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (value) {
        row.notes = value;
      },
    );
  }
}

class BulkStockMovementRow {
  int? productId;
  String type = 'in';
  int quantity = 0;
  String sourceType = 'manual_adjustment';
  double? unitCost;
  String notes = '';
  
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitCostController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  void dispose() {
    quantityController.dispose();
    unitCostController.dispose();
    notesController.dispose();
  }
}