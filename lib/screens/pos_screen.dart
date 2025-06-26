import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/payment_method_model.dart';
import '../utils/format_utils.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../providers/settings_provider.dart';
import '../providers/order_provider.dart';
import '../providers/payment_method_provider.dart';
import '../widgets/payment_method_dialog.dart';
import 'saved_orders_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({Key? key}) : super(key: key);

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  // Services
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  
  // ScrollController untuk infinite scroll
  final ScrollController _scrollController = ScrollController();
  
  // Kategori produk dari API
  List<Category> _apiCategories = [];
  bool _isLoadingCategories = true;
  String? _categoryError;
  
  // Produk dari API
  List<Product> _apiProducts = [];
  bool _isLoadingProducts = true;
  String? _productError;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreProducts = true;
  
  // Kategori yang ditampilkan (termasuk 'Semua')
  List<String> get _categories {
    return ['Semua', ..._apiCategories.map((c) => c.name)];
  }
  
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

  // Warna untuk produk berdasarkan kategori
  Map<String, Color> getProductColors() {
    // Warna default untuk kategori yang belum didefinisikan
    final Map<String, Color> colors = {
      'Elektronik': const Color(0xFF3498DB),  // Biru
      'Pakaian': const Color(0xFF9B59B6),     // Ungu
      'Makanan': const Color(0xFFFF6B6B),     // Merah Muda
      'Minuman': const Color(0xFF4ECDC4),     // Cyan
      'Kesehatan': const Color(0xFF2ECC71),   // Hijau
      'Kecantikan': const Color(0xFFE84393),  // Pink
      'Rumah Tangga': const Color(0xFFE67E22), // Oranye
      'Olahraga': const Color(0xFF1ABC9C),    // Turquoise
      'Mainan': const Color(0xFFFFD166),      // Kuning
      'Buku': const Color(0xFF34495E),        // Navy
    };
    
    // Tambahkan warna dari _categoryColors yang sudah ada
    colors.addAll(_categoryColors);
    
    return colors;
  }

  // Keranjang belanja
  List<Map<String, dynamic>> _cart = [];
  
  // Kategori yang dipilih saat ini
  String _selectedCategory = 'Semua';

  // Filter produk berdasarkan kategori
  List<Product> get _filteredProducts {
    if (_selectedCategory == 'Semua') {
      return _apiProducts;
    } else {
      return _apiProducts.where((product) => product.categoryName == _selectedCategory).toList();
    }
  }

  // Menghitung total belanja
  double get _subtotal {
    return _cart.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }
  
  // Menghitung pajak berdasarkan pengaturan
  double get _tax {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final taxSettings = settingsProvider.tax;
    
    // Jika pajak diaktifkan, hitung berdasarkan persentase dari pengaturan
    if (taxSettings.enableTax) {
      final taxPercentage = double.tryParse(taxSettings.taxPercentage) ?? 10.0;
      return _subtotal * (taxPercentage / 100);
    }
    
    // Jika pajak tidak diaktifkan, kembalikan 0
    return 0.0;
  }
  
  // Menghitung total belanja termasuk pajak
  double get _totalAmount {
    return _subtotal + _tax;
  }
  
  // Menghitung total item di keranjang
  int get _totalItems {
    return _cart.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  // Menambahkan produk ke keranjang
  void _addToCart(Product product) {
    // Jika stok habis, jangan tambahkan ke keranjang
    // if (product.stock <= 0) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Maaf, stok ${product.name} habis'),
    //       backgroundColor: Colors.red,
    //       duration: const Duration(seconds: 2),
    //     ),
    //   );
    //   return;
    // }
    
    setState(() {
      // Cek apakah produk sudah ada di keranjang
      final existingIndex = _cart.indexWhere((item) => item['id'] == product.id);
      
      if (existingIndex >= 0) {
        // Jika sudah ada, tambahkan quantity
        final currentQuantity = _cart[existingIndex]['quantity'] as int;
        
        // Cek apakah penambahan melebihi stok
        // if (currentQuantity < product.stock) {
          _cart[existingIndex]['quantity'] = currentQuantity + 1;
        // } else {
        //   // Tampilkan pesan jika melebihi stok
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text('Jumlah ${product.name} dalam keranjang telah mencapai batas stok'),
        //       backgroundColor: Colors.orange,
        //       duration: const Duration(seconds: 2),
        //     ),
        //   );
        //   return;
        // }
      } else {
        // Jika belum ada, tambahkan ke keranjang dengan quantity 1
        final cartItem = {
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'category': product.categoryName,
          'icon': product.icon,
          'quantity': 1,
          'stock': product.stock,
          'product_ref': product, // Simpan referensi ke objek product asli
        };
        _cart.add(cartItem);
      }
      
      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} ditambahkan ke keranjang'),
          backgroundColor: _primaryColor,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  // Mengurangi jumlah produk di keranjang
  void _decreaseQuantity(int id) {
    setState(() {
      final index = _cart.indexWhere((item) => item['id'] == id);
      if (index >= 0) {
        if (_cart[index]['quantity'] > 1) {
          _cart[index]['quantity'] -= 1;
          
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Jumlah ${_cart[index]['name']} dikurangi'),
              backgroundColor: _primaryColor,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          // Jika quantity = 1, hapus dari keranjang
          final productName = _cart[index]['name'];
          _cart.removeAt(index);
          
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$productName dihapus dari keranjang'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  // Menghapus produk dari keranjang
  void _removeFromCart(int id) {
    setState(() {
      final index = _cart.indexWhere((item) => item['id'] == id);
      if (index >= 0) {
        final productName = _cart[index]['name'];
        _cart.removeAt(index);
        
        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$productName dihapus dari keranjang'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  // Membersihkan keranjang
  void _clearCart() {
    // Jika keranjang kosong, tidak perlu melakukan apa-apa
    if (_cart.isEmpty) return;
    
    setState(() {
      _cart = [];
      
      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Keranjang telah dibersihkan'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  }
  
  // Mengambil data kategori dari API
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });
    
    // Debug: Print semua endpoint untuk memastikan URL yang benar
    ApiConfig.printEndpoints();
    
    try {
      print('POSScreen: Fetching categories...');
      // Mendapatkan token dari AuthService
      final token = await _authService.getToken();
      
      if (token != null) {
        print('POSScreen: Token retrieved successfully');
        // Set token ke CategoryService
        _categoryService.setToken(token);
        
        // Mendapatkan kategori dari API
        print('POSScreen: Calling CategoryService.getCategories()...');
        final categories = await _categoryService.getCategories(
          status: 'active', // Hanya kategori aktif
          perPage: 50, // Jumlah kategori per halaman
        );
        
        print('POSScreen: Categories fetched successfully: ${categories.length} items');
        setState(() {
          _apiCategories = categories;
          _isLoadingCategories = false;
        });
      } else {
        print('POSScreen: Token is null');
        setState(() {
          _categoryError = 'Token tidak ditemukan. Silakan login kembali.';
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('POSScreen: Error fetching categories - ${e.toString()}');
      setState(() {
        _categoryError = 'Gagal memuat kategori: ${e.toString()}';
        _isLoadingCategories = false;
      });
    }
  }
  
  // Mengambil data produk dari API dengan infinite scroll
  Future<void> _fetchProducts({bool refresh = false}) async {
    // Jika sedang memuat atau tidak ada lagi produk (kecuali refresh), jangan lakukan apa-apa
    // if ((_isLoadingProducts || !_hasMoreProducts) && !refresh) {
    //   print('POSScreen: Already loading or no more products to fetch');
    //   return;
    // }
    
    // Reset state jika refresh
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreProducts = true;
        _apiProducts = [];
      });
    }
    
    setState(() {
      _isLoadingProducts = true;
      _productError = null;
    });
    
    try {
      print('POSScreen: Fetching products (page $_currentPage)...');
      // Mendapatkan token dari AuthService
      final token = await _authService.getToken();
      
      if (token != null) {
        // Set token ke ProductService
        _productService.setToken(token);
        
        // Parameter untuk filter produk
        int? categoryId;
        if (_selectedCategory != 'Semua') {
          // Cari ID kategori berdasarkan nama yang dipilih
          final selectedCategoryObj = _apiCategories.firstWhere(
            (category) => category.name == _selectedCategory,
            orElse: () => Category(id: 0, name: '', productCount: 0, isActive: false, createdAt: DateTime.now(), updatedAt: DateTime.now()),
          );
          
          if (selectedCategoryObj.id != 0) {
            categoryId = selectedCategoryObj.id;
          }
        }
        
        // Mendapatkan produk dari API
        final products = await _productService.getProducts(
          categoryId: categoryId,
          isActive: true,
          hasStock: true,
          page: _currentPage,
          perPage: 20,
        );
        
        print('POSScreen: Products fetched successfully: ${products.length} items');
        
        // Jika tidak ada produk yang dikembalikan, berarti tidak ada lagi produk
        if (products.isEmpty) {
          setState(() {
            _isLoadingProducts = false;
            _hasMoreProducts = false;
          });
          return;
        }
        
        setState(() {
          if (refresh || _currentPage == 1) {
            _apiProducts = products;
          } else {
            _apiProducts.addAll(products);
          }
          
          _isLoadingProducts = false;
          _currentPage++;
          
          // Jika jumlah produk yang diterima kurang dari perPage, berarti tidak ada lagi produk
          if (products.length < 20) {
            _hasMoreProducts = false;
          }
        });
      } else {
        print('POSScreen: Token is null');
        setState(() {
          _productError = 'Token tidak ditemukan. Silakan login kembali.';
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      print('POSScreen: Error fetching products - ${e.toString()}');
      setState(() {
        _productError = 'Gagal memuat produk: ${e.toString()}';
        _isLoadingProducts = false;
      });
    }
  }
  
  @override
  void initState() {
    super.initState();
    // Mengambil data kategori dan produk saat screen diinisialisasi
    _fetchCategories().then((_) => _fetchProducts());
    
    // Menambahkan listener untuk infinite scroll
    _scrollController.addListener(_scrollListener);
    
    // Inisialisasi settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).initSettings();
    });
  }
  
  @override
  void dispose() {
    // Membersihkan controller saat widget di-dispose
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Listener untuk infinite scroll
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingProducts &&
        _hasMoreProducts) {
      // Memuat lebih banyak produk ketika pengguna mendekati akhir scroll
      _fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            return Text(
              settingsProvider.store.storeName.isNotEmpty 
                ? '${settingsProvider.store.storeName} - POS'
                : 'Point of Sale', 
              style: const TextStyle(fontWeight: FontWeight.bold)
            );
          },
        ),
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
                  child: _isLoadingCategories
                    ? Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Memuat kategori...',
                              style: TextStyle(color: _primaryColor),
                            ),
                          ],
                        ),
                      )
                    : _categoryError != null
                      ? Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _categoryError!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: _fetchCategories,
                                child: const Text('Coba Lagi'),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
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
                            child: _isLoadingProducts
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                                      const SizedBox(height: 16),
                                      Text('Memuat produk...', style: TextStyle(color: _primaryColor)),
                                    ],
                                  ),
                                )
                              : _productError != null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Gagal memuat produk: $_productError',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.red),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () => _fetchProducts(refresh: true),
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Coba Lagi'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _primaryColor,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _filteredProducts.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                                          const SizedBox(height: 16),
                                          Text(
                                            _selectedCategory == 'Semua'
                                                ? 'Tidak ada produk tersedia'
                                                : 'Tidak ada produk dalam kategori $_selectedCategory',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.grey.shade600),
                                          ),
                                          if (_selectedCategory != 'Semua') ...[  
                                            const SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                  setState(() {
                                                    _selectedCategory = 'Semua';
                                                    // Reset scroll position ketika kategori berubah
                                                    if (_scrollController.hasClients) {
                                                      _scrollController.jumpTo(0);
                                                    }
                                                  });
                                                  _fetchProducts(refresh: true);
                                                },
                                              icon: const Icon(Icons.category),
                                              label: const Text('Lihat Semua Produk'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _primaryColor,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: RefreshIndicator(
                                                  onRefresh: () async {
                                                    // Refresh data produk
                                                    await _fetchProducts(refresh: true);
                                                  },
                                                  color: _primaryColor,
                                                  child: GridView.builder(
                                                    controller: _scrollController,
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
                                              ),
                                              // Indikator loading untuk infinite scroll
                                              if (_isLoadingProducts && _currentPage > 1)
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  child: Center(
                                                    child: Column(
                                                      children: [
                                                        SizedBox(
                                                          height: 24,
                                                          width: 24,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2.5,
                                                            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          'Memuat produk...',
                                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              // Pesan ketika tidak ada lagi produk
                                              if (!_hasMoreProducts && _currentPage > 1 && !_isLoadingProducts)
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  child: Text(
                                                    'Semua produk telah ditampilkan',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
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
                  if (_totalItems > 0)
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
                          _totalItems.toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: Text(
                'Rp ${FormatUtils.formatCurrency(_totalAmount.toInt())}',
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
  Widget _buildProductCard(Product product) {
    final productColors = getProductColors();
    final categoryColor = productColors[product.categoryName] ?? Colors.grey;
    
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      categoryColor.withOpacity(0.7),
                      categoryColor.withOpacity(0.3),
                    ],
                  ),
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
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Lingkaran dekoratif di pojok kiri bawah
                    Positioned(
                      bottom: -10,
                      left: -10,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Icon produk
                    Center(
                      child: Icon(
                        product.icon,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    // Badge kategori
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          product.categoryName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Badge stok
                    if (product.stock > 0)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Stok: ${product.stock}',
                            style: TextStyle(
                              color: categoryColor,
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.sku != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'SKU: ${product.sku}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${FormatUtils.formatCurrency(product.price)}',
                    style: TextStyle(color: categoryColor, fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: product.stock > 0 ? () => _addToCart(product) : null,
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: Text(product.stock > 0 ? 'Tambah' : 'Stok Habis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade300,
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

  // Proses checkout
  void _checkout() async {
    // Jika keranjang kosong, tidak perlu melakukan apa-apa
    if (_cart.isEmpty) return;
    
    // Tampilkan dialog pemilihan metode pembayaran
    showDialog(
      context: context,
      builder: (context) => PaymentMethodDialog(
        totalAmount: _totalAmount,
        onPaymentSelected: (PaymentMethod paymentMethod, double amount) {
          _processCheckout(paymentMethod, amount);
        },
      ),
    );
  }
  
  // Proses checkout dengan metode pembayaran yang dipilih
  void _processCheckout(PaymentMethod paymentMethod, double amount) async {
    try {
      // Simpan jumlah item dan total untuk ditampilkan di pesan sukses
      final itemCount = _totalItems;
      final totalAmount = _totalAmount;
      
      // Dapatkan OrderProvider dan TransactionProvider
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      // Konversi item keranjang ke OrderItem
      final List<OrderItem> orderItems = _cart.map((item) => OrderItem.fromCartItem(item)).toList();
      
      // Buat objek Order baru
      final Order order = Order(
        orderNumber: orderProvider.generateOrderNumber(),
        items: orderItems,
        subtotal: _subtotal,
        tax: _tax,
        total: _totalAmount,
        createdAt: DateTime.now(),
        status: 'completed',
      );
      
      // Siapkan informasi pembayaran
      final List<Map<String, dynamic>> payments = [
        {
          'payment_method_id': paymentMethod.id,
          'amount': amount,
          'reference_number': 'REF-${DateTime.now().millisecondsSinceEpoch}'
        }
      ];
      
      // Kirim transaksi ke API
      final result = await transactionProvider.createTransaction(
        order,
        isParked: false, // Transaksi langsung selesai
        payments: payments,
      );
      
      if (result) {
        // Bersihkan keranjang
        setState(() {
          _cart = [];
        });
        
        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pembayaran Berhasil!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('$itemCount item dengan total Rp ${FormatUtils.formatCurrency(totalAmount.toInt())}'),
                Text('Metode Pembayaran: ${paymentMethod.name}'),
                if (transactionProvider.lastTransaction != null)
                  Text('No. Invoice: ${transactionProvider.lastTransaction!["invoice_number"]}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        
        // Tutup bottom sheet jika di mobile
        if (MediaQuery.of(context).size.width < 650) {
          Navigator.pop(context);
        }
      } else {
        // Tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(transactionProvider.error ?? 'Gagal melakukan checkout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Menyimpan pesanan
  void _saveOrder() async {
    // Jika keranjang kosong, tidak perlu melakukan apa-apa
    if (_cart.isEmpty) return;
    
    try {
      // Dapatkan OrderProvider dan TransactionProvider
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      // Konversi item keranjang ke OrderItem
      final List<OrderItem> orderItems = _cart.map((item) => OrderItem.fromCartItem(item)).toList();
      
      // Buat objek Order baru
      final Order order = Order(
        orderNumber: orderProvider.generateOrderNumber(),
        items: orderItems,
        subtotal: _subtotal,
        tax: _tax,
        total: _totalAmount,
        createdAt: DateTime.now(),
        status: 'saved',
      );
      
      // Kirim transaksi ke API dengan status parked
      final apiResult = await transactionProvider.createTransaction(
        order,
        isParked: true, // Transaksi disimpan/parked
        notes: 'Pesanan disimpan',
      );
      
      if (apiResult) {
        // Jika API berhasil, simpan juga di lokal
        final localResult = await orderProvider.saveOrder(order);
        
        if (localResult) {
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pesanan Berhasil Disimpan!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text('${order.totalItems} item dengan total Rp ${FormatUtils.formatCurrency(order.total.toInt())}'),
                  const SizedBox(height: 4),
                  Text('Nomor Pesanan: ${order.orderNumber}'),
                  if (transactionProvider.lastTransaction != null)
                    Text('No. Invoice: ${transactionProvider.lastTransaction!['invoice_number']}'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Lihat',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedOrdersScreen(),
                    ),
                  );
                },
              ),
            ),
          );
          
          // Bersihkan keranjang
          setState(() {
            _cart = [];
          });
        } else {
          // Tampilkan pesan error lokal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderProvider.error ?? 'Gagal menyimpan pesanan secara lokal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Tampilkan pesan error API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(transactionProvider.error ?? 'Gagal menyimpan pesanan ke server'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                  if (_totalItems > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _totalItems.toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  if (_totalItems > 0)
                    TextButton.icon(
                      onPressed: _clearCart,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Bersihkan'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedOrdersScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long),
                    tooltip: 'Lihat Pesanan Tersimpan',
                    color: _primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Daftar item keranjang
        Expanded(
          child: _totalItems == 0
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
                                    'Rp ${FormatUtils.formatCurrency(item['price'])}',
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
                                  onPressed: () => _addToCart(item['product_ref']),
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
                        Row(
                          children: [
                            Text('Subtotal', style: TextStyle(color: _primaryColor)),
                            const SizedBox(width: 4),
                            Text(
                              '($_totalItems item)',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Text(
                          'Rp ${FormatUtils.formatCurrency(_subtotal.toInt())}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Consumer<SettingsProvider>(
                          builder: (context, settingsProvider, child) {
                            final taxSettings = settingsProvider.tax;
                            final taxPercentage = double.tryParse(taxSettings.taxPercentage) ?? 10.0;
                            return Text(
                              taxSettings.enableTax 
                                ? '${taxSettings.taxName} (${taxPercentage.toStringAsFixed(0)}%)'
                                : 'Pajak (0%)',
                              style: TextStyle(color: _primaryColor),
                            );
                          },
                        ),
                        Text(
                          'Rp ${FormatUtils.formatCurrency(_tax.toInt())}',
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Consumer<SettingsProvider>(
                          builder: (context, settingsProvider, child) {
                            return Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryColor),
                            );
                          },
                        ),
                        Text(
                          'Rp ${FormatUtils.formatCurrency(_totalAmount.toInt())}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tombol simpan dan checkout
              Row(
                children: [
                  // Tombol simpan
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _totalItems == 0 ? null : _saveOrder,
                        icon: const Icon(Icons.save),
                        label: const Text('SIMPAN'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor),
                          disabledForegroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol checkout
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _totalItems == 0 ? null : _checkout,
                        icon: const Icon(Icons.payment),
                        label: const Text('CHECKOUT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
