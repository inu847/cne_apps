import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_movement_provider.dart';
import '../providers/product_provider.dart';
import '../models/stock_movement_model.dart';
import '../config/api_config.dart';
import 'stock_movement_form_screen.dart';
import 'bulk_stock_movement_screen.dart';

class StockMovementScreen extends StatefulWidget {
  const StockMovementScreen({super.key});

  @override
  State<StockMovementScreen> createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends State<StockMovementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  bool _isFilterExpanded = false;
  bool _isSelectionMode = false;
  bool _isLoadingMore = false;
  Set<String> _selectedItems = {};
  Set<String> _expandedItems = {};
  String _quickFilter = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StockMovementProvider>(context, listen: false).fetchStockMovements();
      Provider.of<ProductProvider>(context, listen: false).initProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final provider = Provider.of<StockMovementProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading && !_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });
        provider.fetchStockMovements(page: provider.currentPage + 1).then((_) {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  void _applyFilters() {
    final provider = Provider.of<StockMovementProvider>(context, listen: false);
    provider.setFilters(
      type: _quickFilter == 'all' ? null : _quickFilter,
    );
    provider.fetchStockMovements(refresh: true);
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _quickFilter = 'all';
      _isFilterExpanded = false;
    });
    _searchController.clear();
    _applyFilters();
  }

  void _performSearch() {
    _applyFilters();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedItems.clear();
    });
  }

  void _toggleItemSelection(String movementId) {
    setState(() {
      if (_selectedItems.contains(movementId)) {
        _selectedItems.remove(movementId);
      } else {
        _selectedItems.add(movementId);
      }
    });
  }

  void _selectAllItems() {
    setState(() {
      _selectedItems.addAll(
        Provider.of<StockMovementProvider>(context, listen: false)
            .stockMovements
            .map((movement) => movement.id.toString()),
      );
    });
  }

  void _bulkDelete() async {
    if (_selectedItems.isEmpty) return;

    final confirmed = await _showDeleteDialog(
      title: 'Hapus ${_selectedItems.length} Pergerakan Stok',
      content: 'Apakah Anda yakin ingin menghapus ${_selectedItems.length} pergerakan stok yang dipilih?',
    );

    if (confirmed == true) {
      final provider = Provider.of<StockMovementProvider>(context, listen: false);
      
      for (String movementId in _selectedItems) {
        await provider.deleteStockMovement(int.parse(movementId));
      }
      
      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pergerakan stok berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<bool?> _showDeleteDialog({required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickFilterChip(String value, String label, IconData icon) {
    final isSelected = _quickFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? ApiConfig.backgroundColor : ApiConfig.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? ApiConfig.backgroundColor : ApiConfig.primaryColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      selectedColor: ApiConfig.primaryColor,
      backgroundColor: ApiConfig.backgroundColor,
      onSelected: (selected) {
        _applyQuickFilter(value);
      },
    );
  }

  void _applyQuickFilter(String filter) {
    setState(() {
      _quickFilter = filter;
    });
    _applyFilters();
  }

  void _toggleExpansion(String movementId) {
    setState(() {
      if (_expandedItems.contains(movementId)) {
        _expandedItems.remove(movementId);
      } else {
        _expandedItems.add(movementId);
      }
    });
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isMobile ? 14 : 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 13,
                  color: ApiConfig.textColor.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: ApiConfig.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockMovementItem(StockMovement movement) {
    final isSelected = _selectedItems.contains(movement.id.toString());
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isExpanded = _expandedItems.contains(movement.id.toString());

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ApiConfig.backgroundColor,
            ApiConfig.backgroundColor.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ApiConfig.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
        border: isSelected
            ? Border.all(color: ApiConfig.primaryColor, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSelectionMode 
              ? () => _toggleItemSelection(movement.id.toString())
              : () => _toggleExpansion(movement.id.toString()),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Simplified Header Row
                Row(
                  children: [
                    if (_isSelectionMode)
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? ApiConfig.primaryColor : Colors.grey,
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                    
                    // Movement Type Icon
                    Container(
                      width: isMobile ? 40 : 48,
                      height: isMobile ? 40 : 48,
                      decoration: BoxDecoration(
                        color: movement.typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        movement.typeIcon,
                        color: movement.typeColor,
                        size: isMobile ? 20 : 24,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Simplified Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movement.productName ?? 'Produk #${movement.productId}',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: ApiConfig.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                movement.typeDisplayName,
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                  color: movement.typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                movement.quantityDisplay,
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                  color: movement.typeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Additional quantity info in header
                          if (movement.quantityBefore != null && movement.quantityAfter != null)
                            Text(
                              '${movement.quantityBefore} → ${movement.quantityAfter}',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 12,
                                color: ApiConfig.textColor.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // ID Badge and Expand Icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: movement.typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: movement.typeColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            '#${movement.id}',
                            style: TextStyle(
                              fontSize: isMobile ? 9 : 11,
                              fontWeight: FontWeight.w600,
                              color: movement.typeColor,
                            ),
                          ),
                        ),
                        if (!_isSelectionMode) ...[
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: ApiConfig.textColor.withOpacity(0.6),
                            size: isMobile ? 20 : 24,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                
                // Quick Info Row
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: isMobile ? 12 : 14,
                      color: ApiConfig.textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      movement.formattedCreatedAt,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        color: ApiConfig.textColor.withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.person_outline,
                      size: isMobile ? 12 : 14,
                      color: ApiConfig.textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      movement.userName,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        color: ApiConfig.textColor.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Expandable Details Section
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SKU Info
                        if (movement.productSku != null && movement.productSku!.isNotEmpty) ...[
                          _buildDetailRow(
                            'SKU',
                            movement.productSku!,
                            Icons.qr_code,
                            Colors.grey[600]!,
                            isMobile,
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        // Quantity Information
                        _buildDetailRow(
                          'Quantity Before',
                          movement.quantityBefore != null ? '${movement.quantityBefore}' : '-',
                          Icons.inventory_2_outlined,
                          Colors.grey[600]!,
                          isMobile,
                        ),
                        const SizedBox(height: 8),
                        
                        _buildDetailRow(
                          'Quantity Change',
                          movement.quantityChange != null ? '${movement.quantityChange}' : '-',
                          Icons.swap_horiz,
                          movement.quantityChange != null && movement.quantityChange! >= 0 
                              ? Colors.green[600]! 
                              : Colors.red[600]!,
                          isMobile,
                        ),
                        const SizedBox(height: 8),
                        
                        _buildDetailRow(
                          'Quantity After',
                          movement.quantityAfter != null ? '${movement.quantityAfter}' : '-',
                          Icons.inventory,
                          ApiConfig.primaryColor,
                          isMobile,
                        ),
                        const SizedBox(height: 8),
                        
                        _buildDetailRow(
                          'Movement Type',
                          movement.movementType ?? '-',
                          movement.typeIcon,
                          movement.typeColor,
                          isMobile,
                        ),
                        const SizedBox(height: 8),
                        
                        _buildDetailRow(
                          'Source Type',
                          movement.sourceType ?? '-',
                          Icons.source,
                          Colors.purple,
                          isMobile,
                        ),
                        
                        // Reference Information
                        if (movement.referenceType != null || movement.referenceId != null) ...[
                          const SizedBox(height: 12),
                          if (movement.referenceType != null)
                            _buildDetailRow(
                              'Referensi',
                              movement.referenceTypeDisplayName,
                              Icons.link,
                              Colors.blue,
                              isMobile,
                            ),
                          if (movement.referenceId != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Ref ID',
                              '#${movement.referenceId}',
                              Icons.tag,
                              Colors.blue,
                              isMobile,
                            ),
                          ],
                        ],
                        
                        // Reason and Notes
                        if (movement.reason != null && movement.reason!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Alasan',
                            movement.reason!,
                            Icons.info_outline,
                            Colors.orange,
                            isMobile,
                          ),
                        ],
                        
                        if (movement.notes != null && movement.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Catatan',
                            movement.notes!,
                            Icons.note_outlined,
                            Colors.blue,
                            isMobile,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color, IconData icon, bool isMobile) {
    return Column(
      children: [
        Icon(
          icon,
          size: isMobile ? 16 : 18,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: ApiConfig.textColor.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: ApiConfig.backgroundColor,
      appBar: AppBar(
        backgroundColor: ApiConfig.primaryColor,
        foregroundColor: ApiConfig.backgroundColor,
        title: _isSelectionMode
            ? Text('${_selectedItems.length} dipilih')
            : const Text('Pergerakan Stok'),
        elevation: 0,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              onPressed: _selectAllItems,
              icon: const Icon(Icons.select_all),
              tooltip: 'Pilih Semua',
            ),
            IconButton(
              onPressed: _bulkDelete,
              icon: const Icon(Icons.delete),
              tooltip: 'Hapus Terpilih',
            ),
            IconButton(
              onPressed: _toggleSelectionMode,
              icon: const Icon(Icons.close),
              tooltip: 'Batal',
            ),
          ] else ...[
            IconButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BulkStockMovementScreen(),
                  ),
                );
                
                if (result == true) {
                  // Refresh the list after bulk creation
                  Provider.of<StockMovementProvider>(context, listen: false)
                      .fetchStockMovements(refresh: true);
                }
              },
              icon: const Icon(Icons.playlist_add),
              tooltip: 'Input Massal',
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isFilterExpanded = !_isFilterExpanded;
                });
              },
              icon: Icon(
                _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
              ),
              tooltip: 'Filter',
            ),
            IconButton(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ApiConfig.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: ApiConfig.backgroundColor),
                  decoration: InputDecoration(
                    hintText: 'Cari pergerakan stok...',
                    hintStyle: TextStyle(color: ApiConfig.backgroundColor.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.search, color: ApiConfig.backgroundColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _performSearch();
                            },
                            icon: Icon(Icons.clear, color: ApiConfig.backgroundColor),
                          )
                        : null,
                    filled: true,
                    fillColor: ApiConfig.backgroundColor.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onSubmitted: (value) {
                    _performSearch();
                  },
                ),
                
                // Quick Filters
                if (_isFilterExpanded) ...[
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickFilterChip('all', 'Semua', Icons.all_inclusive),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip('in', 'Masuk', Icons.add_circle_outline),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip('out', 'Keluar', Icons.remove_circle_outline),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip('adjustment', 'Penyesuaian', Icons.tune),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Consumer<StockMovementProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.stockMovements.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.stockMovements.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: ApiConfig.textColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada pergerakan stok',
                          style: TextStyle(
                            fontSize: 18,
                            color: ApiConfig.textColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan pergerakan stok pertama Anda',
                          style: TextStyle(
                            fontSize: 14,
                            color: ApiConfig.textColor.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 16, bottom: 80),
                  itemCount: provider.stockMovements.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.stockMovements.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    return _buildStockMovementItem(provider.stockMovements[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StockMovementFormScreen(),
            ),
          );
          
          if (result == true) {
            // Refresh the list after creating a new stock movement
            Provider.of<StockMovementProvider>(context, listen: false)
                .fetchStockMovements(refresh: true);
          }
        },
        backgroundColor: ApiConfig.primaryColor,
        child: Icon(
          Icons.add,
          color: ApiConfig.backgroundColor,
        ),
      ),
    );
  }
}