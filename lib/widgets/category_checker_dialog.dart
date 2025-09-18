import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';

class CategoryCheckerDialog extends StatefulWidget {
  final Order order;
  final Function(List<String>, bool) onCategoriesSelected;

  const CategoryCheckerDialog({
    Key? key,
    required this.order,
    required this.onCategoriesSelected,
  }) : super(key: key);

  @override
  State<CategoryCheckerDialog> createState() => _CategoryCheckerDialogState();
}

class _CategoryCheckerDialogState extends State<CategoryCheckerDialog> {
  Map<String, bool> categorySelection = {};
  List<String> availableCategories = [];
  bool showPrices = true; // Default menampilkan harga

  @override
  void initState() {
    super.initState();
    _initializeCategories();
    _loadPricePreference();
  }

  void _initializeCategories() {
    // Ambil semua kategori unik dari order items
    Set<String> categoriesSet = {};
    for (var item in widget.order.items) {
      if (item.category != null && item.category!.isNotEmpty) {
        categoriesSet.add(item.category!);
      }
    }
    
    availableCategories = categoriesSet.toList()..sort();
    
    // Default semua kategori ter-checklist
    for (String category in availableCategories) {
      categorySelection[category] = true;
    }
  }

  // Load price preference from localStorage
  Future<void> _loadPricePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        showPrices = prefs.getBool('checker_show_prices') ?? true;
      });
    } catch (e) {
      print('Error loading price preference: $e');
    }
  }

  // Save price preference to localStorage
  Future<void> _savePricePreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('checker_show_prices', value);
    } catch (e) {
      print('Error saving price preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.checklist,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pilih Kategori Struk Checker',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Deskripsi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pilih kategori produk yang ingin dicetak pada struk checker. Setiap kategori akan dicetak secara terpisah.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Kontrol Select All/None
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (String category in availableCategories) {
                        categorySelection[category] = true;
                      }
                    });
                  },
                  icon: const Icon(Icons.select_all, size: 18),
                  label: const Text('Pilih Semua'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (String category in availableCategories) {
                        categorySelection[category] = false;
                      }
                    });
                  },
                  icon: const Icon(Icons.deselect, size: 18),
                  label: const Text('Batal Semua'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(),

            // Daftar kategori
            Flexible(
              child: availableCategories.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Tidak ada kategori produk\ndalam transaksi ini',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableCategories.length,
                      itemBuilder: (context, index) {
                        final category = availableCategories[index];
                        final itemCount = widget.order.items
                            .where((item) => item.category == category)
                            .length;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          child: CheckboxListTile(
                            value: categorySelection[category] ?? false,
                            onChanged: (bool? value) {
                              setState(() {
                                categorySelection[category] = value ?? false;
                              });
                            },
                            title: Text(
                              category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '$itemCount item${itemCount > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.category,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                            ),
                            activeColor: Colors.blue,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),

            // Price display option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: showPrices,
                    onChanged: (value) {
                      setState(() {
                        showPrices = value ?? true;
                      });
                      _savePricePreference(showPrices);
                    },
                    activeColor: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tampilkan Harga',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          showPrices 
                            ? 'Harga produk akan ditampilkan di struk'
                            : 'Hanya nama produk dan quantity yang ditampilkan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final selectedCategories = categorySelection.entries
                          .where((entry) => entry.value)
                          .map((entry) => entry.key)
                          .toList();

                      if (selectedCategories.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pilih minimal satu kategori'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).pop();
                      widget.onCategoriesSelected(selectedCategories, showPrices);
                    },
                    icon: const Icon(Icons.print),
                    label: Text(
                      'Cetak (${categorySelection.values.where((v) => v).length})',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
}