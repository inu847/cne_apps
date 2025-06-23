import 'package:flutter/material.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({Key? key}) : super(key: key);

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  // Kategori produk (hanya teks sesuai permintaan)
  final List<String> _categories = [
    'Semua',
    'Makanan',
    'Minuman',
    'Snack',
    'Paket',
    'Lainnya',
  ];
  
  // Color palette untuk aplikasi
  final Color _primaryColor = const Color(0xFF1E2A78);
  final Color _secondaryColor = const Color(0xFF4B56D2);
  final Color _accentColor = const Color(0xFF82C3EC);
  final Color _lightColor = const Color(0xFFEBF3FB);
  
  // Warna untuk kategori produk
  final Map<String, Color> _categoryColors = {
    'Makanan': const Color(0xFFFF6B6B),
    'Minuman': const Color(0xFF4ECDC4),
    'Snack': const Color(0xFFFFD166),
    'Paket': const Color(0xFF6A0572),
    'Lainnya': const Color(0xFF7D8491),
  };

  // Produk dummy untuk tampilan
  final List<Map<String, dynamic>> _products = [
    {
      'id': 1,
      'name': 'Nasi Goreng',
      'price': 25000,
      'category': 'Makanan',
      'icon': Icons.rice_bowl,
    },
    {
      'id': 2,
      'name': 'Mie Goreng',
      'price': 22000,
      'category': 'Makanan',
      'icon': Icons.ramen_dining,
    },
    {
      'id': 3,
      'name': 'Es Teh',
      'price': 5000,
      'category': 'Minuman',
      'icon': Icons.local_drink,
    },
    {
      'id': 4,
      'name': 'Es Jeruk',
      'price': 7000,
      'category': 'Minuman',
      'icon': Icons.emoji_food_beverage,
    },
    {
      'id': 5,
      'name': 'Kentang Goreng',
      'price': 15000,
      'category': 'Snack',
      'icon': Icons.lunch_dining,
    },
    {
      'id': 6,
      'name': 'Paket Hemat 1',
      'price': 35000,
      'category': 'Paket',
      'icon': Icons.fastfood,
    },
    {
      'id': 7,
      'name': 'Ayam Goreng',
      'price': 18000,
      'category': 'Makanan',
      'icon': Icons.set_meal,
    },
    {
      'id': 8,
      'name': 'Kopi',
      'price': 10000,
      'category': 'Minuman',
      'icon': Icons.coffee,
    },
  ];

  // Keranjang belanja
  List<Map<String, dynamic>> _cart = [];
  
  // Kategori yang dipilih saat ini
  String _selectedCategory = 'Semua';

  // Filter produk berdasarkan kategori
  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategory == 'Semua') {
      return _products;
    } else {
      return _products.where((product) => product['category'] == _selectedCategory).toList();
    }
  }

  // Menghitung total belanja
  double get _totalAmount {
    return _cart.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  // Menambahkan produk ke keranjang
  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      int index = _cart.indexWhere((item) => item['id'] == product['id']);
      if (index >= 0) {
        _cart[index]['quantity'] += 1;
      } else {
        _cart.add({
          ...product,
          'quantity': 1,
        });
      }
    });
  }

  // Mengurangi jumlah produk di keranjang
  void _decreaseQuantity(int id) {
    setState(() {
      int index = _cart.indexWhere((item) => item['id'] == id);
      if (index >= 0) {
        if (_cart[index]['quantity'] > 1) {
          _cart[index]['quantity'] -= 1;
        } else {
          _cart.removeAt(index);
        }
      }
    });
  }

  // Menghapus produk dari keranjang
  void _removeFromCart(int id) {
    setState(() {
      _cart.removeWhere((item) => item['id'] == id);
    });
  }

  // Membersihkan keranjang
  void _clearCart() {
    setState(() {
      _cart = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Row(
        children: [
          // Area produk (kiri)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Kategori produk (horizontal scrollable)
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _lightColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? _primaryColor 
                                : (category == 'Semua' ? Colors.grey.shade200 : _categoryColors[category]?.withOpacity(0.15) ?? Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ] : null,
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.white 
                                  : (category == 'Semua' ? Colors.black : _categoryColors[category] ?? Colors.black),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Daftar produk (grid)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _selectedCategory == 'Semua' ? 'Semua Produk' : 'Kategori: $_selectedCategory',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _selectedCategory == 'Semua' ? _primaryColor : _categoryColors[_selectedCategory],
                              ),
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductCard(product);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Area keranjang (kanan)
          if (!isMobile) // Sembunyikan keranjang di mobile
            Container(
              width: 350,
              margin: const EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: _buildCartSection(),
            ),
        ],
      ),
      // Tampilkan keranjang sebagai bottom sheet di mobile
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: () {
                _showCartBottomSheet();
              },
              backgroundColor: _primaryColor,
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart),
                  if (_cart.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          _cart.length.toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: Text(
                'Rp ${_totalAmount.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => '.')}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              elevation: 4,
            )
          : null,
    );
  }

  // Menampilkan keranjang sebagai bottom sheet di mobile
  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: _buildCartSection(),
        );
      },
    );
  }

  // Widget untuk kartu produk
  Widget _buildProductCard(Map<String, dynamic> product) {
    final categoryColor = _categoryColors[product['category']] ?? Colors.grey;
    
    return InkWell(
      onTap: () => _addToCart(product),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Area warna produk (menggantikan gambar)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                width: double.infinity,
                child: Stack(
                  children: [
                    // Lingkaran dekoratif di pojok kanan atas
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Icon produk
                    Center(
                      child: Icon(
                        product['icon'] ?? Icons.fastfood,
                        size: 48,
                        color: categoryColor,
                      ),
                    ),
                    // Badge kategori
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          product['category'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Informasi produk
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${product['price'].toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => '.')}',
                    style: TextStyle(color: categoryColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _addToCart(product),
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('Tambah'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  // Widget untuk bagian keranjang
  Widget _buildCartSection() {
    return Column(
      children: [
        // Header keranjang
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _lightColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart, color: _primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Keranjang',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  if (_cart.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _cart.length.toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ],
              ),
              if (_cart.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearCart,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Bersihkan'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ),
        ),
        
        // Daftar item keranjang
        Expanded(
          child: _cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Keranjang kosong',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Tambahkan Produk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final item = _cart[index];
                    final categoryColor = _categoryColors[item['category']] ?? Colors.grey;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Warna produk (menggantikan gambar)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  item['icon'] ?? Icons.fastfood,
                                  size: 20,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Informasi produk
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Rp ${item['price'].toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => '.')}',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            // Kontrol jumlah
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _decreaseQuantity(item['id']),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: Colors.red,
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item['quantity'].toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _addToCart(item),
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: Colors.green,
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        
        // Footer keranjang dengan total dan tombol checkout
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _lightColor,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Informasi total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text(
                          'Rp ${_totalAmount.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => '.')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pajak (10%)'),
                        Text(
                          'Rp ${(_totalAmount * 0.1).toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => '.')}',
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Rp ${(_totalAmount * 1.1).toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => '.')}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tombol checkout
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _cart.isEmpty ? null : () {},
                  icon: const Icon(Icons.payment),
                  label: const Text('CHECKOUT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  // Efek gradien dengan shader mask
                  // Ini akan memberikan efek visual yang lebih menarik pada tombol
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}