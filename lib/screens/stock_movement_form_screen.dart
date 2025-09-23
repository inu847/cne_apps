import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/stock_movement_model.dart';
import '../models/product_model.dart';
import '../providers/stock_movement_provider.dart';
import '../providers/product_provider.dart';
import '../config/api_config.dart';

class StockMovementFormScreen extends StatefulWidget {
  final StockMovement? stockMovement;
  
  const StockMovementFormScreen({Key? key, this.stockMovement}) : super(key: key);

  @override
  State<StockMovementFormScreen> createState() => _StockMovementFormScreenState();
}

class _StockMovementFormScreenState extends State<StockMovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _unitCostController = TextEditingController();
  
  int? _selectedProductId;
  String _selectedSourceType = 'manual_adjustment';
  DateTime _selectedMovementDate = DateTime.now();
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get isEditing => widget.stockMovement != null;
  
  // Laravel API source_type enum values
  final List<Map<String, dynamic>> _sourceTypes = [
    {
      'value': 'purchase',
      'label': 'Pembelian',
      'icon': Icons.shopping_cart,
      'color': Colors.green,
      'description': 'Stok masuk dari pembelian'
    },
    {
      'value': 'sale',
      'label': 'Penjualan',
      'icon': Icons.point_of_sale,
      'color': Colors.blue,
      'description': 'Stok keluar dari penjualan'
    },
    {
      'value': 'manual_adjustment',
      'label': 'Penyesuaian Manual',
      'icon': Icons.tune,
      'color': Colors.orange,
      'description': 'Penyesuaian stok manual'
    },
    {
      'value': 'return_in',
      'label': 'Retur Masuk',
      'icon': Icons.keyboard_return,
      'color': Colors.green,
      'description': 'Stok masuk dari retur'
    },
    {
      'value': 'return_out',
      'label': 'Retur Keluar',
      'icon': Icons.undo,
      'color': Colors.red,
      'description': 'Stok keluar untuk retur'
    },
    {
      'value': 'transfer_in',
      'label': 'Transfer Masuk',
      'icon': Icons.call_received,
      'color': Colors.green,
      'description': 'Stok masuk dari transfer'
    },
    {
      'value': 'transfer_out',
      'label': 'Transfer Keluar',
      'icon': Icons.call_made,
      'color': Colors.red,
      'description': 'Stok keluar untuk transfer'
    },
    {
      'value': 'damage',
      'label': 'Kerusakan',
      'icon': Icons.broken_image,
      'color': Colors.red,
      'description': 'Stok berkurang karena kerusakan'
    },
    {
      'value': 'expired',
      'label': 'Kadaluarsa',
      'icon': Icons.schedule,
      'color': Colors.red,
      'description': 'Stok berkurang karena kadaluarsa'
    },
    {
      'value': 'lost',
      'label': 'Hilang',
      'icon': Icons.search_off,
      'color': Colors.red,
      'description': 'Stok hilang'
    },
    {
      'value': 'found',
      'label': 'Ditemukan',
      'icon': Icons.search,
      'color': Colors.green,
      'description': 'Stok ditemukan'
    },
    {
      'value': 'initial_stock',
      'label': 'Stok Awal',
      'icon': Icons.inventory,
      'color': Colors.blue,
      'description': 'Stok awal produk'
    },
    {
      'value': 'other',
      'label': 'Lainnya',
      'icon': Icons.more_horiz,
      'color': Colors.grey,
      'description': 'Alasan lainnya'
    },
  ];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForm();
    });
  }

  Future<void> _initializeForm() async {
    try {
      // Load products first
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (productProvider.products.isEmpty) {
        await productProvider.initProducts();
      }

      // Initialize form data if editing
      if (isEditing && widget.stockMovement != null) {
        final stockMovement = widget.stockMovement!;
        setState(() {
          _selectedProductId = stockMovement.productId;
          // Map old type to new source_type
          _selectedSourceType = _mapOldTypeToSourceType(stockMovement.type);
          _quantityController.text = stockMovement.quantity.abs().toString();
          _reasonController.text = stockMovement.reason ?? '';
          _notesController.text = stockMovement.notes ?? '';
          // Set movement date to created date or current date
          _selectedMovementDate = stockMovement.createdAt;
        });
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing form: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _unitCostController.dispose();
    super.dispose();
  }

  // Helper method to map old type to new source_type
  String _mapOldTypeToSourceType(String oldType) {
    switch (oldType) {
      case 'in':
        return 'manual_adjustment';
      case 'out':
        return 'manual_adjustment';
      case 'adjustment':
        return 'manual_adjustment';
      default:
        return 'manual_adjustment';
    }
  }

  Future<void> _saveStockMovement() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedProductId == null) {
      _showErrorSnackBar('Pilih produk terlebih dahulu');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final provider = Provider.of<StockMovementProvider>(context, listen: false);
      int quantity = int.parse(_quantityController.text.trim());
      
      // Adjust quantity based on source type
      if (_selectedSourceType == 'sale' || _selectedSourceType == 'transfer_out' || 
          _selectedSourceType == 'damage' || _selectedSourceType == 'expired' || 
          _selectedSourceType == 'lost' || _selectedSourceType == 'return_out') {
        quantity = -quantity.abs();
      } else {
        quantity = quantity.abs();
      }
      
      final request = CreateStockMovementRequest(
        productId: _selectedProductId!,
        sourceType: _selectedSourceType!,
        quantity: quantity,
        reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        movementDate: _selectedMovementDate ?? DateTime.now(),
        unitCost: _unitCostController.text.trim().isEmpty ? null : double.tryParse(_unitCostController.text.trim()),
      );
      
      bool success = false;
      if (isEditing) {
        success = await provider.updateStockMovement(widget.stockMovement!.id, request);
      } else {
        success = await provider.createStockMovement(request);
      }
      
      if (success) {
        _showSuccessSnackBar(
          isEditing ? 'Pergerakan stok berhasil diperbarui' : 'Pergerakan stok berhasil dibuat'
        );
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar(provider.error ?? 'Gagal menyimpan pergerakan stok');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Pergerakan Stok' : 'Tambah Pergerakan Stok'),
          backgroundColor: ApiConfig.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Pergerakan Stok' : 'Tambah Pergerakan Stok'),
        backgroundColor: ApiConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveStockMovement,
              child: const Text(
                'SIMPAN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductSelection(),
              const SizedBox(height: 20),
              _buildMovementTypeSelection(),
              const SizedBox(height: 20),
              _buildQuantityInput(),
              const SizedBox(height: 20),
              _buildMovementDateInput(),
              const SizedBox(height: 20),
              _buildUnitCostInput(),
              const SizedBox(height: 20),
              _buildReasonInput(),
              const SizedBox(height: 20),
              _buildNotesInput(),
              const SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSelection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: ApiConfig.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pilih Produk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading && productProvider.products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (productProvider.products.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Tidak ada produk tersedia',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return DropdownButtonFormField<int>(
                  value: _selectedProductId,
                  decoration: InputDecoration(
                    hintText: 'Pilih produk...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: ApiConfig.primaryColor,
                    ),
                  ),
                  isExpanded: true,
                  items: productProvider.products.map((Product product) {
                    return DropdownMenuItem<int>(
                      value: product.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (product.sku != null && product.sku!.isNotEmpty)
                            Text(
                              'SKU: ${product.sku}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          Text(
                            'Stok: ${product.stock}',
                            style: TextStyle(
                              fontSize: 12,
                              color: product.stock > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProductId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih produk';
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementTypeSelection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: ApiConfig.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Jenis Pergerakan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_sourceTypes.map((type) {
              final isSelected = _selectedSourceType == type['value'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSourceType = type['value'];
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? type['color'] : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? type['color'].withOpacity(0.1) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          type['icon'],
                          color: isSelected ? type['color'] : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type['label'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? type['color'] : Colors.black87,
                                ),
                              ),
                              Text(
                                type['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: type['color'],
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityInput() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.numbers,
                  color: ApiConfig.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Jumlah',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Masukkan jumlah...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(
                  Icons.numbers,
                  color: ApiConfig.primaryColor,
                ),
                suffixText: _selectedSourceType == 'manual_adjustment' ? '(+/-)' : null,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Masukkan jumlah';
                }
                final quantity = int.tryParse(value.trim());
                if (quantity == null) {
                  return 'Jumlah harus berupa angka';
                }
                if (quantity == 0) {
                  return 'Jumlah tidak boleh nol';
                }
                return null;
              },
            ),
            if (_selectedSourceType == 'manual_adjustment')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Untuk penyesuaian, gunakan angka positif untuk menambah dan negatif untuk mengurangi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementDateInput() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: ApiConfig.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tanggal Pergerakan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedMovementDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedMovementDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: ApiConfig.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedMovementDate.day}/${_selectedMovementDate.month}/${_selectedMovementDate.year}',
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCostInput() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: ApiConfig.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Harga Satuan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' (Opsional)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unitCostController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Masukkan harga satuan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: ApiConfig.primaryColor,
                ),
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final cost = double.tryParse(value.trim());
                  if (cost == null || cost < 0) {
                    return 'Harga satuan harus berupa angka positif';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonInput() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: ApiConfig.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Alasan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' (Opsional)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Masukkan alasan pergerakan stok...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(
                  Icons.description,
                  color: ApiConfig.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note_alt,
                  color: ApiConfig.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Catatan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' (Opsional)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan catatan tambahan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(
                  Icons.note_alt,
                  color: ApiConfig.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveStockMovement,
        style: ElevatedButton.styleFrom(
          backgroundColor: ApiConfig.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isEditing ? 'PERBARUI PERGERAKAN STOK' : 'SIMPAN PERGERAKAN STOK',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}