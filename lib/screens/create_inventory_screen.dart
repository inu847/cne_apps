import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cne_pos_apps/models/daily_inventory_stock_model.dart';
import 'package:cne_pos_apps/models/daily_inventory_stock_item_model.dart';
import 'package:cne_pos_apps/providers/daily_inventory_stock_provider.dart';
import 'package:cne_pos_apps/services/daily_inventory_stock_service.dart';
import 'package:cne_pos_apps/services/warehouse_service.dart';
import 'package:cne_pos_apps/services/inventory_item_service.dart';

class CreateInventoryScreen extends StatefulWidget {
  const CreateInventoryScreen({Key? key}) : super(key: key);

  @override
  State<CreateInventoryScreen> createState() => _CreateInventoryScreenState();
}

class _CreateInventoryScreenState extends State<CreateInventoryScreen> {
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
      
      // Tambahkan item pertama
      _addNewItem();
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
    
    // Validasi apakah ada item yang dipilih
    bool hasValidItems = false;
    for (var item in _inventoryItems) {
      if (item['inventory_item_id'] != null) {
        hasValidItems = true;
        break;
      }
    }
    
    if (!hasValidItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal satu item persediaan')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Persiapkan data item untuk dikirim ke API
      final items = _inventoryItems
          .where((item) => item['inventory_item_id'] != null)
          .map((item) => {
                'inventory_item_id': item['inventory_item_id'],
                'inventory_uom_id': item['inventory_uom_id'],
                'quantity_in': item['quantity_in'],
                'quantity_out': item['quantity_out'],
                'notes': item['notes'],
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

  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;
    final isMobile = screenWidth < 650;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Persediaan Baru'),
        backgroundColor: const Color(0xFF1E2A78),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInitialData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Header section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informasi Persediaan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Tanggal Stok',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_dateFormat.format(_selectedDate)),
                                          Icon(Icons.calendar_today),
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
                                      border: OutlineInputBorder(),
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
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      
                      // Item list section
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Daftar Item',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _addNewItem,
                                    icon: Icon(Icons.add),
                                    label: Text('Tambah Item'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E2A78),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: _inventoryItems.isEmpty
                                    ? Center(
                                        child: Text('Belum ada item. Tambahkan item baru.'),
                                      )
                                    : isMobile || isTablet
                                        ? _buildMobileItemList()
                                        : _buildDesktopItemTable(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Bottom action buttons
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Batal'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1E2A78),
                                side: BorderSide(color: const Color(0xFF1E2A78)),
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _saveInventory,
                              child: Text('Simpan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E2A78),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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