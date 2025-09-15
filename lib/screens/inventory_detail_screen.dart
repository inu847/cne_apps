import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cne_pos_apps/providers/daily_inventory_stock_provider.dart';
import 'package:cne_pos_apps/models/daily_inventory_stock_item_model.dart';
import 'package:cne_pos_apps/utils/responsive_helper.dart';
import 'package:cne_pos_apps/widgets/custom_button.dart';
import 'package:cne_pos_apps/widgets/custom_text_field.dart';

class InventoryDetailScreen extends StatefulWidget {
  final int stockId;

  const InventoryDetailScreen({Key? key, required this.stockId}) : super(key: key);

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final _dateFormat = DateFormat('dd MMM yyyy');
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  String _searchQuery = '';
  
  // Color palette sesuai tema aplikasi
  static const Color primaryGreen = Color(0xFF03D26F);
  static const Color lightBlue = Color(0xFFEAF4F4);
  static const Color darkBlack = Color(0xFF161514);
  
  // Controller untuk form edit
  List<TextEditingController> _quantityInControllers = [];
  List<TextEditingController> _quantityOutControllers = [];
  List<TextEditingController> _itemNotesControllers = [];
  
  // Flag untuk menunjukkan apakah sedang dalam proses update
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Fetch data saat screen pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DailyInventoryStockProvider>(context, listen: false)
          .fetchDailyInventoryStockDetail(widget.stockId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    _disposeItemControllers();
    super.dispose();
  }
  
  // Inisialisasi controller untuk setiap item
  void _initItemControllers(List<DailyInventoryStockItem> items) {
    _disposeItemControllers();
    
    _quantityInControllers = List.generate(
      items.length,
      (index) => TextEditingController(text: items[index].quantityIn.toString()),
    );
    
    _quantityOutControllers = List.generate(
      items.length,
      (index) => TextEditingController(text: items[index].quantityOut.toString()),
    );
    
    _itemNotesControllers = List.generate(
      items.length,
      (index) => TextEditingController(text: items[index].notes ?? ''),
    );
  }
  
  // Membersihkan controller
  void _disposeItemControllers() {
    for (var controller in _quantityInControllers) {
      controller.dispose();
    }
    for (var controller in _quantityOutControllers) {
      controller.dispose();
    }
    for (var controller in _itemNotesControllers) {
      controller.dispose();
    }
    
    _quantityInControllers = [];
    _quantityOutControllers = [];
    _itemNotesControllers = [];
  }

  // Filter items berdasarkan pencarian
  List<DailyInventoryStockItem> _getFilteredItems(List<DailyInventoryStockItem> items) {
    if (_searchQuery.isEmpty) return items;

    return items.where((item) {
      return item.inventoryItemName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }
  
  // Menampilkan dialog edit persediaan
  void _showEditDialog(DailyInventoryStockDetail stockDetail) {
    // Inisialisasi controller untuk notes
    _notesController.text = stockDetail.notes ?? '';
    
    // Inisialisasi controller untuk setiap item
    _initItemControllers(stockDetail.items);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Persediaan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informasi dasar
                    Text('Tanggal: ${stockDetail.stockDate}'),
                    Text('Gudang: ${stockDetail.warehouseName}'),
                    const SizedBox(height: 16),
                    
                    // Field untuk catatan
                    CustomTextField(
                      controller: _notesController,
                      labelText: 'Catatan',
                      hintText: 'Masukkan catatan persediaan',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Daftar item
                    const Text(
                      'Daftar Item',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    
                    // List item yang dapat diedit
                    ...List.generate(
                      stockDetail.items.length,
                      (index) {
                        final item = stockDetail.items[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.inventoryItemName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Satuan: ${item.inventoryUomName}'),
                                const SizedBox(height: 8),
                                
                                // Field untuk quantity in
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _quantityInControllers[index],
                                        labelText: 'Masuk',
                                        hintText: 'Jumlah masuk',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _quantityOutControllers[index],
                                        labelText: 'Keluar',
                                        hintText: 'Jumlah keluar',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Field untuk catatan item
                                CustomTextField(
                                  controller: _itemNotesControllers[index],
                                  labelText: 'Catatan Item',
                                  hintText: 'Masukkan catatan item',
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: _isUpdating
                      ? null
                      : () => _updateInventoryStock(stockDetail),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2A78),
                    foregroundColor: Colors.white,
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Menyimpan perubahan persediaan
  void _updateInventoryStock(DailyInventoryStockDetail stockDetail) async {
    // Validasi input
    for (int i = 0; i < stockDetail.items.length; i++) {
      final quantityInText = _quantityInControllers[i].text.trim();
      final quantityOutText = _quantityOutControllers[i].text.trim();
      
      if (quantityInText.isEmpty || quantityOutText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah masuk dan keluar harus diisi')),
        );
        return;
      }
      
      final quantityIn = double.tryParse(quantityInText);
      final quantityOut = double.tryParse(quantityOutText);
      
      if (quantityIn == null || quantityOut == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah masuk dan keluar harus berupa angka')),
        );
        return;
      }
      
      if (quantityIn < 0 || quantityOut < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah masuk dan keluar tidak boleh negatif')),
        );
        return;
      }
    }
    
    // Persiapkan data untuk update
    final List<Map<String, dynamic>> itemsData = [];
    
    for (int i = 0; i < stockDetail.items.length; i++) {
      final item = stockDetail.items[i];
      final quantityIn = double.parse(_quantityInControllers[i].text.trim());
      final quantityOut = double.parse(_quantityOutControllers[i].text.trim());
      final notes = _itemNotesControllers[i].text.trim();
      
      final itemData = {
        'inventory_item_id': item.inventoryItemId,
        'inventory_uom_id': item.inventoryUomId,
        'quantity_in': quantityIn,
        'quantity_out': quantityOut,
        'notes': notes,
      };
      
      // Tambahkan ID jika item sudah ada sebelumnya
      if (item.id > 0) {
        itemData['id'] = item.id;
      }
      
      itemsData.add(itemData);
    }
    
    // Set state loading
    setState(() {
      _isUpdating = true;
    });
    
    // Panggil provider untuk update
    final success = await Provider.of<DailyInventoryStockProvider>(context, listen: false)
        .updateDailyInventoryStock(
      stockId: stockDetail.id,
      notes: _notesController.text.trim(),
      items: itemsData,
    );
    
    // Reset state loading
    setState(() {
      _isUpdating = false;
    });
    
    // Tutup dialog
    Navigator.of(context).pop();
    
    // Tampilkan pesan hasil
    if (success) {
      // Reload data setelah update berhasil
      Provider.of<DailyInventoryStockProvider>(context, listen: false)
          .fetchDailyInventoryStockDetail(widget.stockId);
          
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Persediaan berhasil diperbarui')),
      );
    } else {
      final provider = Provider.of<DailyInventoryStockProvider>(context, listen: false);
      final errorMessage = provider.error ?? 'Gagal memperbarui persediaan';
      
      // Tampilkan dialog error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gagal Memperbarui Persediaan'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  
  // Menampilkan dialog konfirmasi kunci persediaan
  void _showLockConfirmationDialog(DailyInventoryStockDetail stockDetail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kunci Persediaan'),
        content: const Text(
          'Persediaan yang sudah dikunci tidak dapat diubah lagi. Apakah Anda yakin ingin mengunci persediaan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _lockInventoryStock(stockDetail.id);
            },
            child: const Text('Kunci'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
  
  // Mengunci persediaan
  Future<void> _lockInventoryStock(int stockId) async {
    // Set loading state
    setState(() {
      _isUpdating = true;
    });
    
    try {
      // Panggil provider untuk mengunci
      final success = await Provider.of<DailyInventoryStockProvider>(context, listen: false)
          .lockDailyInventoryStock(stockId);
      
      // Reset loading state
      setState(() {
        _isUpdating = false;
      });
      
      // Tampilkan pesan sukses/error
      if (success) {
        // Reload data setelah lock berhasil
        Provider.of<DailyInventoryStockProvider>(context, listen: false)
            .fetchDailyInventoryStockDetail(widget.stockId);
            
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Persediaan berhasil dikunci')),
        );
      } else {
        final errorMessage = Provider.of<DailyInventoryStockProvider>(context, listen: false).error ?? 'Gagal mengunci persediaan';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      // Reset loading state
      setState(() {
        _isUpdating = false;
      });
      
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }
  
  // Menampilkan dialog konfirmasi hapus persediaan
  void _showDeleteConfirmationDialog(DailyInventoryStockDetail stockDetail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Persediaan'),
        content: const Text(
          'Persediaan yang sudah dihapus tidak dapat dikembalikan. Apakah Anda yakin ingin menghapus persediaan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteInventoryStock(stockDetail.id);
            },
            child: const Text('Hapus'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
  
  // Menghapus persediaan
  Future<void> _deleteInventoryStock(int stockId) async {
    // Set loading state
    setState(() {
      _isUpdating = true;
    });
    
    try {
      // Panggil provider untuk menghapus
      final success = await Provider.of<DailyInventoryStockProvider>(context, listen: false)
          .deleteDailyInventoryStock(stockId);
      
      // Reset loading state
      setState(() {
        _isUpdating = false;
      });
      
      // Jika berhasil, kembali ke halaman sebelumnya
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Persediaan berhasil dihapus')),
        );
        Navigator.of(context).pop(); // Kembali ke halaman daftar persediaan
      } else {
        final errorMessage = Provider.of<DailyInventoryStockProvider>(context, listen: false).error ?? 'Gagal menghapus persediaan';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      // Reset loading state
      setState(() {
        _isUpdating = false;
      });
      
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
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
        title: const Text(
          'Detail Persediaan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<DailyInventoryStockProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.fetchDailyInventoryStockDetail(widget.stockId);
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final stockDetail = provider.selectedStockDetail;
          if (stockDetail == null) {
            return const Center(
              child: Text('Data persediaan tidak ditemukan'),
            );
          }

          // Filter items berdasarkan pencarian
          final filteredItems = _getFilteredItems(stockDetail.items);

          return Column(
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      lightBlue,
                      lightBlue.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border(
                    bottom: BorderSide(
                      color: primaryGreen.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveHelper.responsiveWidget(
                      context: context,
                      mobile: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Informasi stok
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stok Tanggal: ${stockDetail.stockDate}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: darkBlack,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.warehouse, 'Gudang', stockDetail.warehouseName),
                              const SizedBox(height: 8),
                              if (stockDetail.notes != null && stockDetail.notes!.isNotEmpty)
                                _buildInfoRow(Icons.note, 'Catatan', stockDetail.notes!),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.person, 'Dibuat oleh', stockDetail.createdBy),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.schedule, 'Dibuat pada', _dateFormat.format(stockDetail.createdAt)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Status dan tombol aksi
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: stockDetail.statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: stockDetail.statusColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      stockDetail.statusIcon,
                                      size: 16,
                                      color: stockDetail.statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      stockDetail.statusText,
                                      style: TextStyle(color: stockDetail.statusColor),
                                    ),
                                  ],
                                ),
                              ),
                              if (!stockDetail.isLocked) ...[  
                                _buildActionButton(
                                  onPressed: () => _showEditDialog(stockDetail),
                                  text: 'Edit',
                                  icon: Icons.edit_outlined,
                                  backgroundColor: primaryGreen,
                                ),
                                _buildActionButton(
                                  onPressed: () => _showLockConfirmationDialog(stockDetail),
                                  text: 'Kunci',
                                  icon: Icons.lock_outline,
                                  backgroundColor: Colors.orange,
                                ),
                                _buildActionButton(
                                  onPressed: () => _showDeleteConfirmationDialog(stockDetail),
                                  text: 'Hapus',
                                  icon: Icons.delete_outline,
                                  backgroundColor: Colors.red,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      tablet: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Informasi stok
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stok Tanggal: ${stockDetail.stockDate}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Gudang: ${stockDetail.warehouseName}'),
                              if (stockDetail.notes != null && stockDetail.notes!.isNotEmpty)
                                Text('Catatan: ${stockDetail.notes}'),
                              Text('Dibuat oleh: ${stockDetail.createdBy}'),
                              Text(
                                'Dibuat pada: ${_dateFormat.format(stockDetail.createdAt)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Status dan tombol aksi
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: stockDetail.statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: stockDetail.statusColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      stockDetail.statusIcon,
                                      size: 16,
                                      color: stockDetail.statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      stockDetail.statusText,
                                      style: TextStyle(color: stockDetail.statusColor),
                                    ),
                                  ],
                                ),
                              ),
                              if (!stockDetail.isLocked) ...[  
                                CustomButton(
                                  onPressed: () => _showEditDialog(stockDetail),
                                  text: 'Edit',
                                  icon: Icons.edit,
                                  backgroundColor: const Color(0xFF1E2A78),
                                  textColor: Colors.white,
                                ),
                                CustomButton(
                                  onPressed: () => _showLockConfirmationDialog(stockDetail),
                                  text: 'Kunci',
                                  icon: Icons.lock,
                                  backgroundColor: const Color(0xFF1E2A78),
                                  textColor: Colors.white,
                                ),
                                CustomButton(
                                  onPressed: () => _showDeleteConfirmationDialog(stockDetail),
                                  text: 'Hapus',
                                  icon: Icons.delete,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      desktop: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stok Tanggal: ${stockDetail.stockDate}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Gudang: ${stockDetail.warehouseName}'),
                                if (stockDetail.notes != null && stockDetail.notes!.isNotEmpty)
                                  Text('Catatan: ${stockDetail.notes}'),
                                Text('Dibuat oleh: ${stockDetail.createdBy}'),
                                Text(
                                  'Dibuat pada: ${_dateFormat.format(stockDetail.createdAt)}',
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: stockDetail.statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: stockDetail.statusColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      stockDetail.statusIcon,
                                      size: 16,
                                      color: stockDetail.statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      stockDetail.statusText,
                                      style: TextStyle(color: stockDetail.statusColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Tombol Edit hanya ditampilkan jika persediaan belum terkunci
                              if (!stockDetail.isLocked)
                                Row(
                                  children: [
                                    CustomButton(
                                      onPressed: () => _showEditDialog(stockDetail),
                                      text: 'Edit',
                                      icon: Icons.edit,
                                      backgroundColor: const Color(0xFF1E2A78),
                                      textColor: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    CustomButton(
                                      onPressed: () => _showLockConfirmationDialog(stockDetail),
                                      text: 'Kunci',
                                      icon: Icons.lock,
                                      backgroundColor: const Color(0xFF1E2A78),
                                      textColor: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    CustomButton(
                                      onPressed: () => _showDeleteConfirmationDialog(stockDetail),
                                      text: 'Hapus',
                                      icon: Icons.delete,
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: darkBlack,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Cari Item Persediaan',
                          hintText: 'Masukkan nama item untuk mencari...',
                          labelStyle: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                          hintStyle: TextStyle(
                            color: darkBlack.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: primaryGreen,
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: darkBlack.withOpacity(0.6),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: primaryGreen.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: primaryGreen.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: primaryGreen,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Content section
              Expanded(
                child: isMobile || isTablet
                    ? _buildMobileList(filteredItems)
                    : _buildDesktopTable(filteredItems),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget untuk tampilan list pada mobile
  Widget _buildMobileList(List<DailyInventoryStockItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Tidak ada item yang ditemukan'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                lightBlue.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: primaryGreen.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.inventoryItemName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoItem('Satuan', item.inventoryUomName),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text('Masuk: ${item.quantityIn}'),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                        const SizedBox(width: 4),
                        Text('Keluar: ${item.quantityOut}'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.netQuantity > 0
                          ? Icons.add_circle
                          : item.netQuantity < 0
                              ? Icons.remove_circle
                              : Icons.remove,
                      size: 16,
                      color: item.netQuantityColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bersih: ${item.netQuantity}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.netQuantityColor,
                      ),
                    ),
                  ],
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[  
                  const SizedBox(height: 8),
                  Text(
                    'Catatan: ${item.notes}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Helper widget untuk item informasi
  Widget _buildInfoItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Widget untuk tampilan tabel pada desktop
  Widget _buildDesktopTable(List<DailyInventoryStockItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Tidak ada item yang ditemukan'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              lightBlue.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: primaryGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: DataTable(
                columnSpacing: 16,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                dataRowMinHeight: 64,
                dataRowMaxHeight: 80,
                columns: const [
                  DataColumn(label: Text('No')),
                  DataColumn(label: Text('Nama Item')),
                  DataColumn(label: Text('Satuan')),
                  DataColumn(label: Text('Masuk')),
                  DataColumn(label: Text('Keluar')),
                  DataColumn(label: Text('Bersih')),
                  DataColumn(label: Text('Catatan')),
                ],
                rows: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(
                            item.inventoryItemName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      DataCell(Text(item.inventoryUomName)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text('${item.quantityIn}'),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                            const SizedBox(width: 4),
                            Text('${item.quantityOut}'),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.netQuantity > 0
                                  ? Icons.add_circle
                                  : item.netQuantity < 0
                                      ? Icons.remove_circle
                                      : Icons.remove,
                              size: 16,
                              color: item.netQuantityColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.netQuantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.netQuantityColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            item.notes != null && item.notes!.isNotEmpty ? item.notes! : '-',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper widget untuk tombol aksi dengan desain modern
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
  
  // Helper widget untuk menampilkan informasi dengan icon
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: primaryGreen,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: darkBlack.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: darkBlack,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}