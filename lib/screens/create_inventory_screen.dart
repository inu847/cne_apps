import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cne_pos_apps/models/daily_inventory_stock_model.dart';
import 'package:cne_pos_apps/models/daily_inventory_stock_item_model.dart';
import 'package:cne_pos_apps/providers/daily_inventory_stock_provider.dart';
import 'package:cne_pos_apps/services/daily_inventory_stock_service.dart';
import 'package:cne_pos_apps/services/warehouse_service.dart';
import 'package:cne_pos_apps/services/inventory_item_service.dart';
import '../config/api_config.dart';

class CreateInventoryScreen extends StatefulWidget {
  const CreateInventoryScreen({Key? key}) : super(key: key);

  @override
  State<CreateInventoryScreen> createState() => _CreateInventoryScreenState();
}

class _CreateInventoryScreenState extends State<CreateInventoryScreen> {
  // Theme colors - menggunakan warna dari ApiConfig
  
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  int? _selectedWarehouseId;
  List<Map<String, dynamic>> _warehouseList = [];
  List<Map<String, dynamic>> _inventoryItemList = [];
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // State untuk quick input dan bulk operations
  bool _isBulkInputMode = false;
  bool _isQuickAddMode = false;
  
  // State untuk templates dan presets
  List<Map<String, dynamic>> _itemTemplates = [];
  String _selectedTemplate = '';
  
  // Controllers untuk quick add
  final TextEditingController _quickQuantityController = TextEditingController();
  final TextEditingController _quickNotesController = TextEditingController();
  final TextEditingController _searchItemController = TextEditingController();
  
  // State untuk keyboard shortcuts
  final FocusNode _mainFocusNode = FocusNode();
  
  // Scroll controller untuk infinite scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    // Tambahkan listener untuk infinite scroll
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _quickQuantityController.dispose();
    _quickNotesController.dispose();
    _searchItemController.dispose();
    _mainFocusNode.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Listener untuk infinite scroll
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Tambahkan item baru saat scroll mencapai batas bawah
      _addNewItem();
    }
  }

  // Fungsi untuk memuat data awal
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Muat daftar gudang
      await _loadWarehouses();
      
      // Muat daftar item persediaan
      await _loadInventoryItems();
      
      // Load semua item inventory sebagai form yang siap diisi
      _loadAllInventoryItems();
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Fungsi untuk memuat semua item inventory sebagai form
  void _loadAllInventoryItems() {
    setState(() {
      _inventoryItems.clear();
      for (var item in _inventoryItemList) {
        _inventoryItems.add({
          'inventory_item_id': item['id'],
          'inventory_uom_id': item['uom_id'],
          'inventory_item_name': item['name'],
          'inventory_uom_name': item['uom_name'],
          'quantity_in': 0.0,
          'quantity_out': 0.0,
          'notes': '',
          'is_enabled': false, // Flag untuk menandai item yang akan disimpan
        });
      }
    });
  }

  // Fungsi untuk memuat daftar gudang
  Future<void> _loadWarehouses() async {
    try {
      final WarehouseService service = WarehouseService();
      final result = await service.getWarehouses();
      
      if (result['success']) {
        final List<dynamic> warehouses = result['data']['warehouses'] ?? [];
        setState(() {
          _warehouseList = warehouses.map((warehouse) => {
            'id': warehouse['id'],
            'name': warehouse['name'],
          }).toList();
          
          // Set default warehouse
          if (_selectedWarehouseId == null && _warehouseList.isNotEmpty) {
            _selectedWarehouseId = _warehouseList[0]['id'];
          }
        });
      } else {
        // Jika gagal, gunakan data dummy
        print('Failed to load warehouses: ${result['message']}');
        setState(() {
          _warehouseList = [
            {'id': 1, 'name': 'Gudang Pusat'},
            {'id': 2, 'name': 'Gudang Cabang 1'},
            {'id': 3, 'name': 'Gudang Cabang 2'},
          ];
          
          // Set default warehouse
          if (_selectedWarehouseId == null && _warehouseList.isNotEmpty) {
            _selectedWarehouseId = _warehouseList[0]['id'];
          }
        });
      }
    } catch (e) {
      print('Error loading warehouses: $e');
      // Gunakan data dummy jika terjadi error
      setState(() {
        _warehouseList = [
          {'id': 1, 'name': 'Gudang Pusat'},
          {'id': 2, 'name': 'Gudang Cabang 1'},
          {'id': 3, 'name': 'Gudang Cabang 2'},
        ];
        
        // Set default warehouse
        if (_selectedWarehouseId == null && _warehouseList.isNotEmpty) {
          _selectedWarehouseId = _warehouseList[0]['id'];
        }
      });
    }
  }

  // Fungsi untuk memuat daftar item persediaan
  Future<void> _loadInventoryItems() async {
    try {
      final InventoryItemService service = InventoryItemService();
      // Gunakan parameter query untuk mendapatkan item yang aktif
      final result = await service.getInventoryItems(
        isActive: true,
        perPage: 50, // Ambil lebih banyak item untuk mengurangi paging
      );
      
      if (result['success']) {
        final List<dynamic> items = result['data']['inventory_items'] ?? [];
        setState(() {
          _inventoryItemList = items.map((item) => {
            'id': item['id'],
            'name': item['name'],
            'code': item['code'] ?? '',
            'description': item['description'] ?? '',
            'uom_id': item['default_uom_id'] ?? item['inventory_uom_id'],
            'uom_name': item['default_uom_name'] ?? item['inventory_uom_name'],
          }).toList();
        });
        
        print('Loaded ${_inventoryItemList.length} inventory items from API');
      } else {
        // Jika gagal, gunakan data dummy
        print('Failed to load inventory items: ${result['message']}');
        setState(() {
          _inventoryItemList = [
            {'id': 101, 'name': 'Beras', 'uom_id': 1, 'uom_name': 'Kg'},
            {'id': 102, 'name': 'Gula', 'uom_id': 1, 'uom_name': 'Kg'},
            {'id': 103, 'name': 'Minyak Goreng', 'uom_id': 2, 'uom_name': 'Liter'},
            {'id': 104, 'name': 'Tepung Terigu', 'uom_id': 1, 'uom_name': 'Kg'},
            {'id': 105, 'name': 'Telur', 'uom_id': 3, 'uom_name': 'Butir'},
          ];
        });
      }
    } catch (e) {
      print('Error loading inventory items: $e');
      // Gunakan data dummy jika terjadi error
      setState(() {
        _inventoryItemList = [
          {'id': 101, 'name': 'Beras', 'uom_id': 1, 'uom_name': 'Kg'},
          {'id': 102, 'name': 'Gula', 'uom_id': 1, 'uom_name': 'Kg'},
          {'id': 103, 'name': 'Minyak Goreng', 'uom_id': 2, 'uom_name': 'Liter'},
          {'id': 104, 'name': 'Tepung Terigu', 'uom_id': 1, 'uom_name': 'Kg'},
          {'id': 105, 'name': 'Telur', 'uom_id': 3, 'uom_name': 'Butir'},
        ];
      });
    }
  }

  // Fungsi untuk menambahkan item baru
  void _addNewItem() {
    if (_inventoryItemList.isEmpty) return;
    
    setState(() {
      _inventoryItems.add({
        'inventory_item_id': null,
        'inventory_uom_id': null,
        'inventory_item_name': '',
        'inventory_uom_name': '',
        'quantity_in': 0.0,
        'quantity_out': 0.0,
        'notes': '',
      });
    });
  }

  // Fungsi untuk menghapus item
  void _removeItem(int index) {
    setState(() {
      _inventoryItems.removeAt(index);
    });
  }
  
  // Fungsi untuk toggle bulk input mode
  void _toggleBulkInputMode() {
    setState(() {
      _isBulkInputMode = !_isBulkInputMode;
      if (_isBulkInputMode) {
        _isQuickAddMode = false;
      }
    });
  }
  
  // Fungsi untuk toggle quick add mode
  void _toggleQuickAddMode() {
    setState(() {
      _isQuickAddMode = !_isQuickAddMode;
      if (_isQuickAddMode) {
        _isBulkInputMode = false;
      }
    });
  }
  
  // Fungsi untuk quick add item
  void _quickAddItem(Map<String, dynamic> item) {
    final quantity = double.tryParse(_quickQuantityController.text) ?? 0.0;
    final notes = _quickNotesController.text;
    
    setState(() {
      _inventoryItems.add({
        'inventory_item_id': item['id'],
        'inventory_uom_id': item['uom_id'],
        'inventory_item_name': item['name'],
        'inventory_uom_name': item['uom_name'],
        'quantity_in': quantity,
        'quantity_out': 0.0,
        'notes': notes,
      });
    });
    
    // Clear controllers untuk input berikutnya
    _quickQuantityController.clear();
    _quickNotesController.clear();
    _searchItemController.clear();
  }
  
  // Fungsi untuk load template
  void _loadTemplate(String templateName) {
    switch (templateName) {
      case 'daily_stock':
        _loadDailyStockTemplate();
        break;
      case 'weekly_stock':
        _loadWeeklyStockTemplate();
        break;
      case 'monthly_stock':
        _loadMonthlyStockTemplate();
        break;
    }
  }
  
  // Template untuk stock harian
  void _loadDailyStockTemplate() {
    setState(() {
      _inventoryItems.clear();
      for (var item in _inventoryItemList.take(5)) {
        _inventoryItems.add({
          'inventory_item_id': item['id'],
          'inventory_uom_id': item['uom_id'],
          'inventory_item_name': item['name'],
          'inventory_uom_name': item['uom_name'],
          'quantity_in': 0.0,
          'quantity_out': 0.0,
          'notes': 'Stock harian',
        });
      }
    });
  }
  
  // Template untuk stock mingguan
  void _loadWeeklyStockTemplate() {
    setState(() {
      _inventoryItems.clear();
      for (var item in _inventoryItemList.take(10)) {
        _inventoryItems.add({
          'inventory_item_id': item['id'],
          'inventory_uom_id': item['uom_id'],
          'inventory_item_name': item['name'],
          'inventory_uom_name': item['uom_name'],
          'quantity_in': 0.0,
          'quantity_out': 0.0,
          'notes': 'Stock mingguan',
        });
      }
    });
  }
  
  // Template untuk stock bulanan
  void _loadMonthlyStockTemplate() {
    setState(() {
      _inventoryItems.clear();
      for (var item in _inventoryItemList) {
        _inventoryItems.add({
          'inventory_item_id': item['id'],
          'inventory_uom_id': item['uom_id'],
          'inventory_item_name': item['name'],
          'inventory_uom_name': item['uom_name'],
          'quantity_in': 0.0,
          'quantity_out': 0.0,
          'notes': 'Stock bulanan',
        });
      }
    });
  }

  // Fungsi untuk memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Fungsi untuk menyimpan persediaan
  Future<void> _saveInventory() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validasi apakah ada item yang dipilih dan dicentang
    final enabledItems = _inventoryItems.where((item) => item['is_enabled'] == true).toList();
    
    if (enabledItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu item persediaan')),
      );
      return;
    }
    
    // Validasi apakah item yang dipilih memiliki quantity
    bool hasValidQuantity = false;
    for (var item in enabledItems) {
      if ((item['quantity_in'] ?? 0.0) > 0 || (item['quantity_out'] ?? 0.0) > 0) {
        hasValidQuantity = true;
        break;
      }
    }
    
    if (!hasValidQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan quantity untuk item yang dipilih')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Persiapkan data item untuk dikirim ke API (hanya item yang dicentang)
      final items = enabledItems
          .map((item) => {
                'inventory_item_id': item['inventory_item_id'],
                'inventory_uom_id': item['inventory_uom_id'],
                'quantity_in': item['quantity_in'] ?? 0.0,
                'quantity_out': item['quantity_out'] ?? 0.0,
                'notes': item['notes'] ?? '',
              })
          .toList();
      
      // Panggil service untuk membuat persediaan baru
      final DailyInventoryStockService service = DailyInventoryStockService();
      final result = await service.createDailyInventoryStock(
        stockDate: _dateFormat.format(_selectedDate),
        warehouseId: _selectedWarehouseId!,
        notes: _notesController.text,
        items: items,
      );
      
      if (result['success']) {
        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Persediaan berhasil disimpan')),
        );
        
        // Kembali ke halaman sebelumnya dengan status berhasil
        Navigator.pop(context, true);
      } else {
        // Tampilkan pesan error dalam popup dialog
        final errorMessage = result['message'] ?? 'Gagal menyimpan persediaan';
        setState(() {
          _errorMessage = errorMessage;
        });
        
        // Tampilkan dialog error dan redirect ke halaman create persediaan setelah ditutup
        showDialog(
          context: context,
          barrierDismissible: false, // Mencegah dialog ditutup dengan tap di luar dialog
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Gagal Menyimpan Persediaan'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog
                    // Reset form dan state untuk membuat persediaan baru
                    setState(() {
                      _errorMessage = null;
                      _inventoryItems.clear();
                      _addNewItem(); // Tambahkan item baru kosong
                    });
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      final errorMessage = 'Terjadi kesalahan: $e';
      setState(() {
        _errorMessage = errorMessage;
      });
      
      // Tampilkan dialog error untuk exception dan redirect ke halaman create persediaan setelah ditutup
      showDialog(
        context: context,
        barrierDismissible: false, // Mencegah dialog ditutup dengan tap di luar dialog
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Gagal Menyimpan Persediaan'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  // Reset form dan state untuk membuat persediaan baru
                  setState(() {
                    _errorMessage = null;
                    _inventoryItems.clear();
                    _addNewItem(); // Tambahkan item baru kosong
                  });
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Widget untuk menampilkan daftar item inventory dengan checkbox
  Widget _buildInventoryItemsList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    // Filter items berdasarkan search
    final filteredItems = _inventoryItems.where((item) {
      if (_searchItemController.text.isEmpty) return true;
      return item['inventory_item_name']
          .toString()
          .toLowerCase()
          .contains(_searchItemController.text.toLowerCase());
    }).toList();
    
    return Padding(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      child: Column(
        children: filteredItems.map((item) {
          final isEnabled = item['is_enabled'] ?? false;
          
          return Container(
            margin: EdgeInsets.only(
              bottom: isMobile ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: isEnabled ? ApiConfig.primaryColor.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEnabled ? ApiConfig.primaryColor.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                width: isEnabled ? 2 : 1,
              ),
              boxShadow: isEnabled ? [
                BoxShadow(
                  color: ApiConfig.primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ] : [],
            ),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 4 : 8,
              ),
              childrenPadding: EdgeInsets.zero,
              leading: Checkbox(
                value: isEnabled,
                onChanged: (value) {
                  setState(() {
                    item['is_enabled'] = value ?? false;
                    if (!value!) {
                      item['quantity_in'] = 0.0;
                      item['quantity_out'] = 0.0;
                      item['notes'] = '';
                    }
                  });
                },
                activeColor: ApiConfig.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              title: Text(
                item['inventory_item_name'] ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                  color: isEnabled ? ApiConfig.primaryColor : ApiConfig.textColor,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'UOM: ${item['inventory_uom_name'] ?? ''}',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: ApiConfig.textColor.withOpacity(0.7),
                  ),
                ),
              ),
              trailing: isEnabled
                  ? Icon(
                      Icons.keyboard_arrow_down,
                      color: ApiConfig.primaryColor,
                    )
                  : Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.grey,
                    ),
              children: isEnabled
                  ? [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        margin: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: ApiConfig.backgroundColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: item['quantity_in'].toString(),
                                    decoration: InputDecoration(
                                      labelText: 'Quantity In',
                                      hintText: '0',
                                      labelStyle: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                        color: ApiConfig.textColor.withOpacity(0.7),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: ApiConfig.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.add_circle_outline,
                                        color: ApiConfig.primaryColor,
                                        size: isMobile ? 20 : 24,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: isMobile ? 12 : 16,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      item['quantity_in'] = double.tryParse(value) ?? 0.0;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: item['quantity_out'].toString(),
                                    decoration: InputDecoration(
                                      labelText: 'Quantity Out',
                                      hintText: '0',
                                      labelStyle: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                        color: ApiConfig.textColor.withOpacity(0.7),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                        size: isMobile ? 20 : 24,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: isMobile ? 12 : 16,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      item['quantity_out'] = double.tryParse(value) ?? 0.0;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: item['notes'] ?? '',
                              decoration: InputDecoration(
                                labelText: 'Catatan (Opsional)',
                                hintText: 'Tambahkan catatan untuk item ini...',
                                labelStyle: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                  color: ApiConfig.textColor.withOpacity(0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: ApiConfig.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.note_outlined,
                                  color: ApiConfig.primaryColor,
                                  size: isMobile ? 20 : 24,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: isMobile ? 12 : 16,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                              ),
                              maxLines: 2,
                              onChanged: (value) {
                                item['notes'] = value;
                              },
                            ),
                          ],
                        ),
                      ),
                    ]
                  : [],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;
    final isMobile = screenWidth < 650;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dompet Kasir - POS | Buat Persediaan Baru',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ApiConfig.backgroundColor,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: ApiConfig.primaryColor,
        foregroundColor: ApiConfig.backgroundColor,
        elevation: 4,
        shadowColor: ApiConfig.primaryColor.withOpacity(0.3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Panduan Penggunaan'),
                  content: const Text(
                    'Centang item yang ingin dimasukkan ke persediaan, lalu isi quantity dan catatan sesuai kebutuhan.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Mengerti'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Bantuan',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ApiConfig.primaryColor),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat data...',
                    style: TextStyle(
                      color: ApiConfig.textColor.withOpacity(0.7),
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat data',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: ApiConfig.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: ApiConfig.textColor.withOpacity(0.7),
                          fontSize: isMobile ? 14 : 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadInitialData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ApiConfig.primaryColor,
                          foregroundColor: ApiConfig.backgroundColor,
                          elevation: 2,
                          shadowColor: ApiConfig.primaryColor.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20 : 24,
                            vertical: isMobile ? 12 : 14,
                          ),
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                      // Header section
                      Container(
                        margin: EdgeInsets.all(isMobile ? 12 : 16),
                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ApiConfig.backgroundColor,
                              ApiConfig.backgroundColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: ApiConfig.primaryColor.withOpacity(0.1),
                              blurRadius: 15,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: ApiConfig.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        ApiConfig.primaryColor,
                                        ApiConfig.primaryColor.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2,
                                    color: ApiConfig.backgroundColor,
                                    size: isMobile ? 20 : 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Informasi Persediaan',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: ApiConfig.textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Tanggal Stok',
                                        labelStyle: TextStyle(
                                          color: ApiConfig.textColor.withOpacity(0.7),
                                          fontSize: isMobile ? 14 : 16,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: ApiConfig.primaryColor.withOpacity(0.3),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: ApiConfig.primaryColor.withOpacity(0.3),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: ApiConfig.primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _dateFormat.format(_selectedDate),
                                            style: TextStyle(
                                              color: ApiConfig.textColor,
                                              fontSize: isMobile ? 14 : 16,
                                            ),
                                          ),
                                          Icon(
                                            Icons.calendar_today,
                                            color: ApiConfig.primaryColor,
                                            size: isMobile ? 20 : 24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    decoration: InputDecoration(
                                      labelText: 'Gudang',
                                      labelStyle: TextStyle(
                                        color: ApiConfig.textColor.withOpacity(0.7),
                                        fontSize: isMobile ? 14 : 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: ApiConfig.primaryColor.withOpacity(0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: ApiConfig.primaryColor.withOpacity(0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: ApiConfig.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    value: _selectedWarehouseId,
                                    items: _warehouseList.map((warehouse) {
                                      return DropdownMenuItem<int>(
                                        value: warehouse['id'],
                                        child: Text(warehouse['name']),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedWarehouseId = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Pilih gudang';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: 'Catatan',
                                labelStyle: TextStyle(
                                  color: ApiConfig.textColor.withOpacity(0.7),
                                  fontSize: isMobile ? 14 : 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: ApiConfig.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: ApiConfig.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: ApiConfig.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: TextStyle(
                                color: ApiConfig.textColor,
                                fontSize: isMobile ? 14 : 16,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      
                      // Search and Filter Panel
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: 8,
                        ),
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ApiConfig.backgroundColor,
                              ApiConfig.backgroundColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ApiConfig.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchItemController,
                              decoration: InputDecoration(
                                labelText: 'Cari Item Persediaan',
                                hintText: 'Ketik nama item untuk mencari...',
                                prefixIcon: Icon(Icons.search, color: ApiConfig.primaryColor),
                                suffixIcon: _searchItemController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear, color: ApiConfig.textColor.withOpacity(0.6)),
                                        onPressed: () {
                                          _searchItemController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        for (var item in _inventoryItems) {
                                          item['is_enabled'] = true;
                                        }
                                      });
                                    },
                                    icon: Icon(Icons.select_all, size: isMobile ? 16 : 18),
                                    label: Text(
                                      'Pilih Semua',
                                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ApiConfig.primaryColor,
                                      foregroundColor: ApiConfig.backgroundColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        for (var item in _inventoryItems) {
                                          item['is_enabled'] = false;
                                          item['quantity_in'] = 0.0;
                                          item['quantity_out'] = 0.0;
                                          item['notes'] = '';
                                        }
                                      });
                                    },
                                    icon: Icon(Icons.deselect, size: isMobile ? 16 : 18),
                                    label: Text(
                                      'Batal Semua',
                                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: ApiConfig.primaryColor,
                                      side: BorderSide(color: ApiConfig.primaryColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Item list section
                      Column(
                        children: [
                          // Header section dengan informasi
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: 8,
                            ),
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  ApiConfig.backgroundColor,
                                  ApiConfig.backgroundColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ApiConfig.primaryColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        ApiConfig.primaryColor,
                                        ApiConfig.primaryColor.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2,
                                    color: ApiConfig.backgroundColor,
                                    size: isMobile ? 18 : 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Daftar Item Persediaan',
                                        style: TextStyle(
                                          fontSize: isMobile ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: ApiConfig.textColor,
                                        ),
                                      ),
                                      Text(
                                        'Centang item yang ingin dimasukkan ke persediaan',
                                        style: TextStyle(
                                          fontSize: isMobile ? 12 : 14,
                                          color: ApiConfig.textColor.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 8 : 12,
                                    vertical: isMobile ? 4 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ApiConfig.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: ApiConfig.primaryColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${_inventoryItems.where((item) => item['is_enabled'] == true).length} dipilih',
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 12,
                                      fontWeight: FontWeight.bold,
                                      color: ApiConfig.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Item list area dengan tinggi yang sesuai
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: ApiConfig.primaryColor.withOpacity(0.1),
                                  blurRadius: 15,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: ApiConfig.primaryColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: _inventoryItems.isEmpty
                                ? Container(
                                    height: 200,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(ApiConfig.primaryColor),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Memuat item persediaan...',
                                            style: TextStyle(
                                              fontSize: isMobile ? 14 : 16,
                                              color: ApiConfig.textColor.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: _buildInventoryItemsList(),
                                  ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                      
                      // Bottom action buttons
                      Container(
                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ApiConfig.backgroundColor,
                              ApiConfig.backgroundColor.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ApiConfig.primaryColor.withOpacity(0.1),
                              blurRadius: 15,
                              spreadRadius: 0,
                              offset: const Offset(0, -8),
                            ),
                          ],
                          border: Border(
                            top: BorderSide(
                              color: ApiConfig.primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: ApiConfig.primaryColor, width: 2),
                                foregroundColor: ApiConfig.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 24,
                                  vertical: isMobile ? 12 : 14,
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _saveInventory,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ApiConfig.primaryColor,
                                foregroundColor: ApiConfig.backgroundColor,
                                elevation: 2,
                                shadowColor: ApiConfig.primaryColor.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 24,
                                  vertical: isMobile ? 12 : 14,
                                ),
                              ),
                              child: Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Widget untuk tampilan list pada mobile
  Widget _buildMobileItemList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _inventoryItems.length,
      itemBuilder: (context, index) {
        final item = _inventoryItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Item #${index + 1}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeItem(index),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Pilih Item',
                    border: OutlineInputBorder(),
                  ),
                  value: item['inventory_item_id'],
                  items: _inventoryItemList.map((invItem) {
                    return DropdownMenuItem<int>(
                      value: invItem['id'],
                      child: Text(
                        invItem['code'] != null && invItem['code'].toString().isNotEmpty
                            ? '${invItem['code']} - ${invItem['name']}'
                            : invItem['name'],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      item['inventory_item_id'] = value;
                      // Set UOM berdasarkan item yang dipilih
                      final selectedItem = _inventoryItemList.firstWhere(
                        (invItem) => invItem['id'] == value,
                        orElse: () => {'uom_id': null, 'uom_name': ''},
                      );
                      item['inventory_uom_id'] = selectedItem['uom_id'];
                      item['inventory_uom_name'] = selectedItem['uom_name'];
                      item['inventory_item_name'] = selectedItem['name'];
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih item';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Masuk',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.arrow_downward, color: Colors.green),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        initialValue: item['quantity_in'].toString(),
                        onChanged: (value) {
                          setState(() {
                            item['quantity_in'] = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Keluar',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.arrow_upward, color: Colors.red),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        initialValue: item['quantity_out'].toString(),
                        onChanged: (value) {
                          setState(() {
                            item['quantity_out'] = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Catatan Item',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: item['notes'],
                  onChanged: (value) {
                    setState(() {
                      item['notes'] = value;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget untuk tampilan tabel pada desktop
  Widget _buildDesktopItemTable() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 4, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Masuk', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 4, child: Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            
            // Items
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _inventoryItems.length,
              itemBuilder: (context, index) {
                final item = _inventoryItems[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // No
                      Expanded(
                        flex: 1,
                        child: Text('${index + 1}'),
                      ),
                      
                      // Item
                      Expanded(
                        flex: 4,
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            border: OutlineInputBorder(),
                          ),
                          value: item['inventory_item_id'],
                          items: _inventoryItemList.map((invItem) {
                            return DropdownMenuItem<int>(
                              value: invItem['id'],
                              child: Text(
                                invItem['code'] != null && invItem['code'].toString().isNotEmpty
                                    ? '${invItem['code']} - ${invItem['name']}'
                                    : invItem['name'],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              item['inventory_item_id'] = value;
                              // Set UOM berdasarkan item yang dipilih
                              final selectedItem = _inventoryItemList.firstWhere(
                                (invItem) => invItem['id'] == value,
                                orElse: () => {'uom_id': null, 'uom_name': ''},
                              );
                              item['inventory_uom_id'] = selectedItem['uom_id'];
                              item['inventory_uom_name'] = selectedItem['uom_name'];
                              item['inventory_item_name'] = selectedItem['name'];
                            });
                          },
                        ),
                      ),
                      
                      // Quantity In
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextFormField(
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            initialValue: item['quantity_in'].toString(),
                            onChanged: (value) {
                              setState(() {
                                item['quantity_in'] = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      // Quantity Out
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextFormField(
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            initialValue: item['quantity_out'].toString(),
                            onChanged: (value) {
                              setState(() {
                                item['quantity_out'] = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      // Notes
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextFormField(
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              border: OutlineInputBorder(),
                            ),
                            initialValue: item['notes'],
                            onChanged: (value) {
                              setState(() {
                                item['notes'] = value;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      // Action
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}