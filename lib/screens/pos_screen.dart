import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/transaction_provider.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/payment_method_model.dart';
import '../models/receipt_model.dart';
import '../utils/format_utils.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../providers/settings_provider.dart';
import '../providers/order_provider.dart';
import '../providers/payment_method_provider.dart';
import '../providers/voucher_provider.dart';
import '../providers/petty_cash_provider.dart';
import '../widgets/payment_method_dialog.dart';
import '../widgets/petty_cash_dialog.dart';
import '../services/receipt_service.dart';
import 'saved_orders_screen.dart';
import 'receipt_screen.dart';
import 'transaction_detail_screen.dart';

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
  
  // Controller untuk input nama pelanggan dan voucher
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _voucherController = TextEditingController();
  
  // State untuk mengontrol visibility input nama pelanggan dan voucher
  bool _showCustomerVoucherInputs = false;
  
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
  
  // Color palette baru untuk aplikasi
  static const Color primaryGreen = Color(0xFF03D26F);
  static const Color lightBlue = Color(0xFFEAF4F4);
  static const Color darkBlack = Color(0xFF161514);
  
  // Legacy colors (akan diganti bertahap)
  final Color _primaryColor = primaryGreen;
  final Color _secondaryColor = primaryGreen.withOpacity(0.8);
  final Color _accentColor = lightBlue;
  final Color _lightColor = lightBlue;
  
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
  
  // Menghitung total belanja termasuk pajak dan diskon voucher
  double get _totalAmount {
    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    final discountValue = voucherProvider.activeVoucher != null ? voucherProvider.discountValue : 0;
    
    // Total setelah pajak dan diskon
    return (_subtotal + _tax) - discountValue;
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
    
    // Inisialisasi settings dan petty cash validation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSettingsAndPettyCash();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Memeriksa apakah ada order yang akan diedit
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic> && args['edit_mode'] == true) {
      final Order order = args['order'];
      
      // Hanya load order jika cart masih kosong (mencegah double loading)
      if (_cart.isEmpty) {
        setState(() {
          // Mengisi cart dengan item dari order
          for (var item in order.items) {
            // Mencari produk yang sesuai di _apiProducts
            final productIndex = _apiProducts.indexWhere((p) => p.id == item.productId);
            
            if (productIndex >= 0) {
              // Jika produk ditemukan, gunakan data produk lengkap
              final product = _apiProducts[productIndex];
              _cart.add({
                'id': item.productId,
                'name': item.productName,
                'price': item.price,
                'category': item.category,
                'icon': item.icon,
                'quantity': item.quantity,
                'stock': product.stock,
                'product_ref': product,
              });
            } else {
              // Jika produk tidak ditemukan di _apiProducts, gunakan data dari item order
              _cart.add({
                'id': item.productId,
                'name': item.productName,
                'price': item.price,
                'category': item.category,
                'icon': item.icon,
                'quantity': item.quantity,
                'stock': 999, // Default stock jika tidak diketahui
                'product_ref': null,
              });
            }
          }
          
          // Mengisi data customer jika ada
          if (order.customerName != null && order.customerName!.isNotEmpty) {
            _customerNameController.text = order.customerName!;
          }
        });
      }
    }
  }
  
  @override
  void dispose() {
    // Membersihkan controller saat widget di-dispose
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _customerNameController.dispose();
    _voucherController.dispose();
    super.dispose();
  }
  
  // Validasi voucher
  void _validateVoucher() async {
    final voucherCode = _voucherController.text.trim();
    if (voucherCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode voucher terlebih dahulu')),
      );
      return;
    }
    
    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    final customerName = _customerNameController.text.trim();
    
    // Validasi voucher dengan API
    final result = await voucherProvider.validateVoucher(
      code: voucherCode,
      orderAmount: _totalAmount,
      // Jika perlu mengirim customer_id, tambahkan di sini
      // customerId: customerId,
    );
    
    if (result) {
      // Voucher valid, update UI
      setState(() {
        // Recalculate total with discount
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher ${voucherProvider.voucherName} berhasil diterapkan'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Voucher tidak valid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(voucherProvider.error ?? 'Voucher tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Hapus voucher
  void _clearVoucher() {
    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    voucherProvider.clearVoucher();
    _voucherController.clear();
    setState(() {
      // Recalculate total without discount
    });
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

  // Inisialisasi settings dan petty cash secara berurutan
  Future<void> _initializeSettingsAndPettyCash() async {
    try {
      print('Starting settings and petty cash initialization...');
      
      // Tunggu settings selesai dimuat terlebih dahulu
      await Provider.of<SettingsProvider>(context, listen: false).initSettings();
      print('Settings initialized successfully');
      
      // Baru kemudian inisialisasi petty cash
      await _initializePettyCash();
      print('Petty cash initialization completed');
    } catch (e) {
      print('Error during initialization: $e');
    }
  }

  // Inisialisasi dan validasi petty cash
  Future<void> _initializePettyCash() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final pettyCashProvider = Provider.of<PettyCashProvider>(context, listen: false);
    
    print('=== PETTY CASH INITIALIZATION START ===');
    print('Settings object: ${settingsProvider.settings}');
    print('System settings: ${settingsProvider.system}');
    print('petty_cash_enabled: ${settingsProvider.system.pettyCashEnabled}');
    
    // Cek apakah petty cash diaktifkan di settings
    if (settingsProvider.system.pettyCashEnabled) {
      print('✓ Petty cash is enabled, checking status...');
      
      // Step 1: Cek status petty cash menggunakan /petty-cash/active-opening
      print('Fetching active petty cash...');
      final fetchResult = await pettyCashProvider.fetchActivePettyCash();
      print('Fetch result: $fetchResult');
      
      print('Active petty cash: ${pettyCashProvider.activePettyCash}');
      print('Has active petty cash: ${pettyCashProvider.hasActivePettyCash}');
      print('Can make transaction: ${pettyCashProvider.canMakeTransaction}');
      print('Petty cash status: ${pettyCashProvider.pettyCashStatus}');
      
      // Step 2: Jika status 'closing' atau data tidak ditemukan, tampilkan popup untuk Buka Kasir
      if (!pettyCashProvider.canMakeTransaction) {
        print('✗ Cannot make transaction - showing popup...');
        
        // Tampilkan popup untuk melakukan opening petty cash
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            print('✓ Widget mounted - showing petty cash dialog...');
            _showPettyCashDialog();
          } else {
            print('✗ Widget not mounted, cannot show dialog');
          }
        });
      } else {
        // Jika sudah dalam status 'opening', transaksi dapat dilakukan
        print('✓ Petty cash sudah dalam status opening, transaksi dapat dilakukan');
      }
    } else {
      print('✗ Petty cash is disabled in settings');
    }
    print('=== PETTY CASH INITIALIZATION END ===');
  }

  // Menampilkan dialog petty cash
  Future<void> _showPettyCashDialog() async {
    final pettyCashProvider = Provider.of<PettyCashProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    // Tentukan type dialog berdasarkan status petty cash
    String dialogType = 'opening';
    if (pettyCashProvider.activePettyCash != null && 
        pettyCashProvider.activePettyCash!.isOpening) {
      dialogType = 'closing';
    }
    
    final result = await showPettyCashDialog(
      context: context,
      type: dialogType,
      activePettyCash: pettyCashProvider.activePettyCash,
      warehouseId: 1, // Default warehouse ID, sesuaikan dengan kebutuhan
    );
    
    if (result == true) {
      // Step 3: Setelah opening, lakukan pengecekan ulang ke /petty-cash/active-opening
      await pettyCashProvider.fetchActivePettyCash();
      
      // Step 4: Jika status menunjukkan 'opening', transaksi dapat dilakukan
      if (pettyCashProvider.canMakeTransaction) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Petty cash berhasil dibuka, transaksi dapat dilakukan'),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Validasi petty cash sebelum melakukan transaksi
  bool _validatePettyCashForTransaction() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final pettyCashProvider = Provider.of<PettyCashProvider>(context, listen: false);
    
    // Jika petty cash tidak diaktifkan, izinkan transaksi
    if (!settingsProvider.system.pettyCashEnabled) {
      return true;
    }
    
    // Jika petty cash diaktifkan, cek apakah bisa melakukan transaksi
    if (!pettyCashProvider.canMakeTransaction) {
      _showPettyCashRequiredDialog();
      return false;
    }
    
    return true;
  }

  // Menampilkan dialog bahwa petty cash diperlukan
   void _showPettyCashRequiredDialog() {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Petty Cash Diperlukan'),
         content: const Text(
           'Anda harus membuka petty cash terlebih dahulu sebelum melakukan transaksi.',
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: const Text('Batal'),
           ),
           ElevatedButton(
             onPressed: () {
               Navigator.of(context).pop();
               _showPettyCashDialog();
             },
             child: const Text('Buka Petty Cash'),
           ),
         ],
       ),
     );
   }

   // Menampilkan dialog status petty cash
    void _showPettyCashStatusDialog() {
      final pettyCashProvider = Provider.of<PettyCashProvider>(context, listen: false);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Status Petty Cash'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               if (pettyCashProvider.activePettyCash != null) ...[
                 Text('Nama: ${pettyCashProvider.activePettyCash!.name}'),
                 const SizedBox(height: 8),
                 Text('Jumlah: ${FormatUtils.formatCurrency(pettyCashProvider.activePettyCash!.amount)}'),
                 const SizedBox(height: 8),
                 Text('Status: ${pettyCashProvider.activePettyCash!.isActive ? 'Aktif' : 'Tidak Aktif'}'),
                 const SizedBox(height: 8),
                 Text('Tipe: ${pettyCashProvider.activePettyCash!.isOpening ? 'Opening' : 'Closing'}'),
                 if (pettyCashProvider.activePettyCash!.userName != null) ...[
                   const SizedBox(height: 8),
                   Text('Penanggung Jawab: ${pettyCashProvider.activePettyCash!.userName}'),
                 ],
               ] else ...[
                 const Text('Tidak ada petty cash yang aktif'),
               ],
             ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            if (pettyCashProvider.activePettyCash == null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showPettyCashDialog();
                },
                child: const Text('Buka Petty Cash'),
              ),
          ],
        ),
      );
    }

    // Menampilkan dialog opening petty cash
    Future<void> _showPettyCashOpeningDialog() async {
      final pettyCashProvider = Provider.of<PettyCashProvider>(context, listen: false);
      
      final result = await showPettyCashDialog(
        context: context,
        type: 'opening',
        activePettyCash: pettyCashProvider.activePettyCash,
        warehouseId: 1,
      );
      
      if (result == true) {
        // Refresh status petty cash setelah dialog ditutup
        await pettyCashProvider.fetchActivePettyCash();
      }
    }

    // Menampilkan dialog closing petty cash (Tutup Kasir)
    Future<void> _showPettyCashClosingDialog() async {
      final pettyCashProvider = Provider.of<PettyCashProvider>(context, listen: false);
      
      final result = await showPettyCashDialog(
        context: context,
        type: 'closing',
        activePettyCash: pettyCashProvider.activePettyCash,
        warehouseId: 1,
      );
      
      if (result == true) {
        // Refresh status petty cash setelah dialog ditutup
        await pettyCashProvider.fetchActivePettyCash();
        
        // Tampilkan notifikasi bahwa kasir telah ditutup
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kasir berhasil ditutup'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // TUTUP POPUP
        Navigator.of(context).pop();
      }
    }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            return Text(
              settingsProvider.store.storeName.isNotEmpty 
                ? '${settingsProvider.store.storeName} - POS'
                : 'Point of Sale', 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: lightBlue,
                fontSize: isMobile ? 18 : 20,
              ),
            );
          },
        ),
        backgroundColor: primaryGreen,
        foregroundColor: lightBlue,
        elevation: 4,
        shadowColor: primaryGreen.withOpacity(0.3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          // Tombol filter kategori
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Kategori',
            onSelected: (String category) {
              setState(() {
                _selectedCategory = category;
              });
            },
            itemBuilder: (BuildContext context) {
              if (_isLoadingCategories) {
                return [const PopupMenuItem<String>(
                  value: '',
                  enabled: false,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Memuat kategori...'),
                    ],
                  ),
                )];
              }
              
              if (_categoryError != null) {
                return [PopupMenuItem<String>(
                  value: '',
                  enabled: false,
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(_categoryError!, style: const TextStyle(color: Colors.red)),
                      TextButton(
                        onPressed: _fetchCategories,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )];
              }
              
              return _categories.map((category) {
                final isSelected = category == _selectedCategory;
                return PopupMenuItem<String>(
                  value: category,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? _primaryColor 
                            : (category == 'Semua' ? Colors.grey.shade200 : _categoryColors[category]?.withOpacity(0.7) ?? Colors.grey.shade200),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          // Tombol reload page
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang',
            onPressed: () {
              // Muat ulang data
              setState(() {
                _isLoadingCategories = true;
                _isLoadingProducts = true;
                _currentPage = 1;
                _hasMoreProducts = true;
              });
              _fetchCategories();
              _fetchProducts(refresh: true);
            },
          ),
          // Tombol laporan
          PopupMenuButton<String>(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Laporan',
            onSelected: (String value) {
              if (value == 'daily-recap') {
                Navigator.of(context).pushNamed('/reports/daily-recap');
              } else if (value == 'sales') {
                Navigator.of(context).pushNamed('/reports/sales');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'daily-recap',
                child: Text('Rekap Harian'),
              ),
              const PopupMenuItem<String>(
                value: 'sales',
                child: Text('Laporan Penjualan'),
              ),
            ],
          ),
          // Tombol petty cash
          Consumer2<SettingsProvider, PettyCashProvider>(
            builder: (context, settingsProvider, pettyCashProvider, child) {
              // Hanya tampilkan jika petty cash diaktifkan
              if (!settingsProvider.system.pettyCashEnabled) {
                return const SizedBox.shrink();
              }
              
              return PopupMenuButton<String>(
                icon: Icon(
                  Icons.account_balance_wallet,
                  color: pettyCashProvider.canMakeTransaction 
                      ? primaryGreen 
                      : Colors.red.shade400,
                ),
                tooltip: 'Petty Cash',
                onSelected: (String value) {
                   if (value == 'status') {
                     _showPettyCashStatusDialog();
                   } else if (value == 'open') {
                     _showPettyCashOpeningDialog();
                   } else if (value == 'close') {
                     _showPettyCashClosingDialog();
                   }
                 },
                itemBuilder: (BuildContext context) {
                  final List<PopupMenuEntry<String>> items = [];
                  
                  // Status petty cash
                  items.add(
                    PopupMenuItem<String>(
                      value: 'status',
                      child: Row(
                        children: [
                          Icon(
                            pettyCashProvider.canMakeTransaction 
                                ? Icons.check_circle 
                                : Icons.cancel,
                            color: pettyCashProvider.canMakeTransaction 
                                ? primaryGreen 
                                : Colors.red.shade400,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${pettyCashProvider.pettyCashStatus == 'open' ? 'Terbuka' : 'Tertutup'}',
                          ),
                        ],
                      ),
                    ),
                  );
                  
                  items.add(const PopupMenuDivider());
                  
                  // Tombol buka/tutup petty cash
                   if (pettyCashProvider.canMakeTransaction) {
                     items.add(
                       const PopupMenuItem<String>(
                         value: 'close',
                         child: Row(
                           children: [
                             Icon(Icons.lock, size: 16),
                             SizedBox(width: 8),
                             Text('Tutup Kasir'),
                           ],
                         ),
                       ),
                     );
                   } else {
                     items.add(
                       const PopupMenuItem<String>(
                         value: 'open',
                         child: Row(
                           children: [
                             Icon(Icons.lock_open, size: 16),
                             SizedBox(width: 8),
                             Text('Buka Petty Cash'),
                           ],
                         ),
                       ),
                     );
                   }
                  
                  return items;
                },
              );
            },
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
                // Kategori sudah dipindahkan ke header sebagai dropdown
                const SizedBox(height: 16),
                
                // Daftar produk (grid)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      isMobile ? 8 : 16, 
                      8, 
                      isMobile ? 8 : 16, 
                      16
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          lightBlue,
                          lightBlue.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.1),
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
                        color: primaryGreen.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _selectedCategory == 'Semua' ? 'Semua Produk' : 'Kategori: $_selectedCategory',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: darkBlack,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _isLoadingProducts
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                                        strokeWidth: 3,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Memuat produk...', 
                                        style: TextStyle(
                                          color: darkBlack.withOpacity(0.7),
                                          fontSize: isMobile ? 14 : 16,
                                        ),
                                      ),
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
                                            backgroundColor: Theme.of(context).colorScheme.primary,
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
                                                    // Optimasi physics untuk scrolling yang lebih smooth
                                                    physics: const BouncingScrollPhysics(
                                                      parent: AlwaysScrollableScrollPhysics(),
                                                    ),
                                                    // Optimasi caching untuk performa yang lebih baik
                                                    cacheExtent: 500.0,
                                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                                                      childAspectRatio: isMobile ? 0.68 : (isTablet ? 0.8 : 0.85),
                                                      crossAxisSpacing: isMobile ? 8 : (isTablet ? 16 : 16),
                                                      mainAxisSpacing: isMobile ? 8 : (isTablet ? 16 : 16),
                                                    ),
                                                    itemCount: _filteredProducts.length,
                                                    itemBuilder: (context, index) {
                                                      final product = _filteredProducts[index];
                                                      // Optimasi dengan key untuk widget recycling yang lebih baik
                                                      return _buildOptimizedProductCard(product, index);
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
                                              // if (!_hasMoreProducts && _currentPage > 1 && !_isLoadingProducts)
                                              //   Padding(
                                              //     padding: const EdgeInsets.symmetric(vertical: 16),
                                              //     child: Text(
                                              //       'Semua produk telah ditampilkan',
                                              //       style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                              //     ),
                                              //   ),
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
              width: isTablet ? 320 : 350, // Lebih proporsional untuk tablet
              margin: EdgeInsets.only(
                left: isTablet ? 8 : 8, 
                right: isTablet ? 16 : 16, 
                top: 16, 
                bottom: 16
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    lightBlue,
                    lightBlue.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.1),
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
                  color: primaryGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: _buildCartSection(isTablet: isTablet),
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
                  const Icon(Icons.shopping_cart, color: Colors.white),
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
                FormatUtils.formatCurrency(_totalAmount.toInt()),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: _buildMobileCartSection(scrollController),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget untuk kartu produk
  Widget _buildProductCard(Product product) {
    final productColors = getProductColors();
    final categoryColor = productColors[product.categoryName] ?? Colors.grey;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;
    
    return InkWell(
      onTap: () => _addToCart(product),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              offset: const Offset(0, 6),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Area warna produk (menggantikan gambar)
            Expanded(
              flex: isMobile ? 3 : (isTablet ? 3 : 2),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryGreen,
                      primaryGreen.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                width: double.infinity,
                child: Stack(
                  children: [
                    // Lingkaran dekoratif di pojok kanan atas
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: isMobile ? 40 : (isTablet ? 45 : 60),
                        height: isMobile ? 40 : (isTablet ? 45 : 60),
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
                        width: isMobile ? 30 : (isTablet ? 35 : 40),
                        height: isMobile ? 30 : (isTablet ? 35 : 40),
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
                        size: isMobile ? 32 : (isTablet ? 36 : 48),
                        color: Colors.white,
                      ),
                    ),
                    // Badge kategori
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : (isTablet ? 6 : 8), 
                          vertical: isMobile ? 2 : (isTablet ? 2 : 4)
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.categoryName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 8 : (isTablet ? 8 : 10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Badge stok
                    if (product.stock > 0)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 6 : (isTablet ? 6 : 8), 
                            vertical: isMobile ? 2 : (isTablet ? 2 : 4)
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Stok: ${product.stock}',
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: isMobile ? 8 : (isTablet ? 8 : 10),
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
            Expanded(
              flex: isMobile ? 2 : (isTablet ? 2 : 3),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 8 : (isTablet ? 10 : 12)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: isMobile ? 12 : (isTablet ? 13 : 16),
                              color: darkBlack,
                            ),
                            maxLines: isMobile ? 2 : (isTablet ? 2 : 1),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (product.sku != null && !isMobile && !isTablet)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'SKU: ${product.sku}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                              ),
                            ),
                          SizedBox(height: isMobile ? 1 : (isTablet ? 2 : 4)),
                          Text(
                            '${FormatUtils.formatCurrency(product.price)}',
                            style: TextStyle(
                              color: primaryGreen, 
                              fontWeight: FontWeight.bold, 
                              fontSize: isMobile ? 12 : (isTablet ? 13 : 16)
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 2 : (isTablet ? 4 : 8)),
                    SizedBox(
                      width: double.infinity,
                      height: isMobile ? 28 : (isTablet ? 32 : 40),
                      child: ElevatedButton.icon(
                        onPressed: () => _addToCart(product),
                        icon: Icon(Icons.add_shopping_cart, size: isMobile ? 12 : (isTablet ? 14 : 16)),
                        label: Text(
                          'Tambah',
                          style: TextStyle(fontSize: isMobile ? 10 : (isTablet ? 11 : 14)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: lightBlue,
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 6 : (isTablet ? 8 : 10),
                            horizontal: isMobile ? 8 : (isTablet ? 10 : 12),
                          ),
                          elevation: 2,
                          shadowColor: primaryGreen.withOpacity(0.3),
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: Size(double.infinity, isMobile ? 32 : (isTablet ? 36 : 40)),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  // Optimized product card dengan caching dan const widgets
  Widget _buildOptimizedProductCard(Product product, int index) {
    final productColors = getProductColors();
    final categoryColor = productColors[product.categoryName] ?? Colors.grey;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;
    
    return RepaintBoundary(
      key: ValueKey('product_${product.id}_$index'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: InkWell(
          onTap: () => _addToCart(product),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFE3F2FD),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A4CAF50),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: Offset(0, 2),
                ),
              ],
              border: const Border.fromBorderSide(
                BorderSide(
                  color: Color(0x264CAF50),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Area warna produk (menggantikan gambar)
                Expanded(
                  flex: isMobile ? 3 : (isTablet ? 3 : 2),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4CAF50),
                          Color(0xB34CAF50),
                        ],
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Lingkaran dekoratif di pojok kanan atas
                        Positioned(
                          top: -15,
                          right: -15,
                          child: Container(
                            width: isMobile ? 40 : (isTablet ? 45 : 60),
                            height: isMobile ? 40 : (isTablet ? 45 : 60),
                            decoration: const BoxDecoration(
                              color: Color(0x33FFFFFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Lingkaran dekoratif di pojok kiri bawah
                        Positioned(
                          bottom: -10,
                          left: -10,
                          child: Container(
                            width: isMobile ? 30 : (isTablet ? 35 : 40),
                            height: isMobile ? 30 : (isTablet ? 35 : 40),
                            decoration: const BoxDecoration(
                              color: Color(0x1AFFFFFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Icon produk
                        Center(
                          child: Icon(
                            product.icon,
                            size: isMobile ? 32 : (isTablet ? 36 : 48),
                            color: Colors.white,
                          ),
                        ),
                        // Badge kategori
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 6 : (isTablet ? 6 : 8), 
                              vertical: isMobile ? 2 : (isTablet ? 2 : 4)
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x99000000),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.categoryName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 8 : (isTablet ? 8 : 10),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Badge stok
                        if (product.stock > 0)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 6 : (isTablet ? 6 : 8), 
                                vertical: isMobile ? 2 : (isTablet ? 2 : 4)
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xCCFFFFFF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Stok: ${product.stock}',
                                style: TextStyle(
                                  color: categoryColor,
                                  fontSize: isMobile ? 8 : (isTablet ? 8 : 10),
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
                Expanded(
                  flex: isMobile ? 2 : (isTablet ? 2 : 3),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 8 : (isTablet ? 10 : 12)),
                    decoration: const BoxDecoration(
                      color: Color(0xE6FFFFFF),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: isMobile ? 12 : (isTablet ? 13 : 16),
                                  color: const Color(0xFF212121),
                                ),
                                maxLines: isMobile ? 2 : (isTablet ? 2 : 1),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (product.sku != null && !isMobile && !isTablet)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'SKU: ${product.sku}',
                                    style: const TextStyle(
                                      color: Color(0xFF757575), 
                                      fontSize: 10
                                    ),
                                  ),
                                ),
                              SizedBox(height: isMobile ? 1 : (isTablet ? 2 : 4)),
                              Text(
                                '${FormatUtils.formatCurrency(product.price)}',
                                style: TextStyle(
                                  color: const Color(0xFF4CAF50), 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: isMobile ? 12 : (isTablet ? 13 : 16)
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 2 : (isTablet ? 4 : 8)),
                        SizedBox(
                          width: double.infinity,
                          height: isMobile ? 28 : (isTablet ? 32 : 40),
                          child: ElevatedButton.icon(
                            onPressed: () => _addToCart(product),
                            icon: Icon(
                              Icons.add_shopping_cart, 
                              size: isMobile ? 12 : (isTablet ? 14 : 16)
                            ),
                            label: Text(
                              'Tambah',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : (isTablet ? 11 : 14)
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: const Color(0xFFE3F2FD),
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 6 : (isTablet ? 8 : 10),
                                horizontal: isMobile ? 8 : (isTablet ? 10 : 12),
                              ),
                              elevation: 2,
                              shadowColor: const Color(0x4D4CAF50),
                              disabledBackgroundColor: const Color(0xFFE0E0E0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: Size(
                                double.infinity, 
                                isMobile ? 32 : (isTablet ? 36 : 40)
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        ),
      ),
    );
  }

  // Proses checkout
  void _checkout() async {
    // Jika keranjang kosong, tidak perlu melakukan apa-apa
    if (_cart.isEmpty) return;
    
    // Validasi petty cash sebelum melakukan transaksi
    if (!_validatePettyCashForTransaction()) {
      return;
    }
    
    // Tambahkan log untuk debugging
    print('Menampilkan dialog pemilihan metode pembayaran');
    print('totalAmount: $_totalAmount');
    
    // Tampilkan dialog pemilihan metode pembayaran
    showDialog(
      context: context,
      barrierDismissible: false, // Pastikan dialog tidak bisa ditutup dengan tap di luar
      builder: (context) => PaymentMethodDialog(
        totalAmount: _totalAmount,
        onPaymentSelected: (PaymentMethod paymentMethod, double amount) {
          print('Metode pembayaran dipilih: ${paymentMethod.name}, amount: $amount');
          _processCheckout(paymentMethod, amount);
        },
      ),
    );
  }
  
  // Proses checkout dengan metode pembayaran yang dipilih
  void _processCheckout(PaymentMethod paymentMethod, double amount) async {
    try {
      // Tambahkan log untuk debugging
      print('Memproses checkout dengan metode pembayaran: ${paymentMethod.name}');
      print('Amount: $amount');
      
      // Simpan jumlah item dan total untuk ditampilkan di pesan sukses
      final itemCount = _totalItems;
      final totalAmount = _totalAmount;
      final customerName = _customerNameController.text.trim();
      
      print('itemCount: $itemCount');
      print('totalAmount: $totalAmount');
      print('customerName: $customerName');
      
      // Dapatkan OrderProvider, TransactionProvider, dan VoucherProvider
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      
      // Konversi item keranjang ke OrderItem
      final List<OrderItem> orderItems = _cart.map((item) => OrderItem.fromCartItem(item)).toList();
      
      // Cek apakah ini mode edit
      final args = ModalRoute.of(context)?.settings.arguments;
      final bool isEditMode = args != null && args is Map<String, dynamic> && args['edit_mode'] == true;
      final Order? existingOrder = isEditMode ? args['order'] as Order : null;
      
      // Buat objek Order baru atau update yang sudah ada
      final Order order = existingOrder != null
          ? existingOrder.copyWith(
              items: orderItems,
              subtotal: _subtotal,
              tax: _tax,
              total: _totalAmount,
              // Pertahankan orderNumber dan createdAt yang sudah ada
              status: 'completed',
              customerName: customerName.isNotEmpty ? customerName : null,
            )
          : Order(
              orderNumber: orderProvider.generateOrderNumber(),
              items: orderItems,
              subtotal: _subtotal,
              tax: _tax,
              total: _totalAmount,
              createdAt: DateTime.now(),
              status: 'completed',
              customerName: customerName.isNotEmpty ? customerName : null,
            );
      
      // Siapkan informasi pembayaran
      final List<Map<String, dynamic>> payments = [
        {
          'payment_method_id': paymentMethod.id,
          'payment_method_name': paymentMethod.name,
          'amount': amount,
          'reference_number': 'REF-${DateTime.now().millisecondsSinceEpoch}'
        }
      ];
      
      // Kirim transaksi ke API
      final result = await transactionProvider.createTransaction(
        order,
        isParked: false, // Transaksi langsung selesai
        customerName: customerName.isNotEmpty ? customerName : null,
        payments: payments,
        voucherCode: voucherProvider.activeVoucher != null ? voucherProvider.voucherCode : null,
      );
      
      // Tambahkan log untuk debugging
      print('Hasil createTransaction: $result');
      print('lastTransaction setelah createTransaction: ${transactionProvider.lastTransaction}');
      
      if (result) {
        // Bersihkan keranjang, nama pelanggan, dan voucher
        setState(() {
          _cart = [];
          _customerNameController.clear();
          _voucherController.clear();
        });
        
        // Bersihkan voucher di provider
        final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
        voucherProvider.clearVoucher();
        
        print('Sebelum menampilkan dialog sukses transaksi');
        print('lastTransaction: ${transactionProvider.lastTransaction}');
        
        // Gunakan Future.delayed untuk memastikan state sudah diperbarui sebelum menampilkan dialog
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            // Tampilkan popup konfirmasi transaksi berhasil
            _showTransactionSuccessDialog(
              itemCount: itemCount,
              totalAmount: totalAmount,
              paymentMethod: paymentMethod,
              customerName: customerName,
              order: order,
              transactionProvider: transactionProvider,
              settingsProvider: settingsProvider,
            );
          }
        });
        
        // Cek apakah ini mode edit, jika ya, kembali ke halaman sebelumnya
        final args = ModalRoute.of(context)?.settings.arguments;
        final bool isEditMode = args != null && args is Map<String, dynamic> && args['edit_mode'] == true;
        
        if (isEditMode) {
          Navigator.pop(context, true); // Kembali dengan hasil true untuk refresh daftar pesanan
        }
        // Hapus logika Navigator.pop untuk mobile agar tetap di halaman POS
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
      // Dapatkan OrderProvider, TransactionProvider, dan VoucherProvider
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
      final customerName = _customerNameController.text.trim();
      
      // Konversi item keranjang ke OrderItem
      final List<OrderItem> orderItems = _cart.map((item) => OrderItem.fromCartItem(item)).toList();
      
      // Cek apakah ini mode edit
      final args = ModalRoute.of(context)?.settings.arguments;
      final bool isEditMode = args != null && args is Map<String, dynamic> && args['edit_mode'] == true;
      final Order? existingOrder = isEditMode ? args['order'] as Order : null;
      
      // Buat objek Order baru atau update yang sudah ada
      final Order order = existingOrder != null
          ? existingOrder.copyWith(
              items: orderItems,
              subtotal: _subtotal,
              tax: _tax,
              total: _totalAmount,
              // Pertahankan orderNumber dan createdAt yang sudah ada
              status: 'saved',
              customerName: customerName.isNotEmpty ? customerName : null,
            )
          : Order(
              orderNumber: orderProvider.generateOrderNumber(),
              items: orderItems,
              subtotal: _subtotal,
              tax: _tax,
              total: _totalAmount,
              createdAt: DateTime.now(),
              status: 'saved',
              customerName: customerName.isNotEmpty ? customerName : null,
            );
      
      // Kirim transaksi ke API dengan status parked
      final apiResult = await transactionProvider.createTransaction(
        order,
        isParked: true, // Transaksi disimpan/parked
        customerName: customerName.isNotEmpty ? customerName : null,
        notes: 'Pesanan disimpan',
        voucherCode: voucherProvider.activeVoucher != null ? voucherProvider.voucherCode : null,
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
                  Text('${order.totalItems} item dengan total ${FormatUtils.formatCurrency(order.total.toInt())}'),
                  const SizedBox(height: 4),
                  Text('Nomor Pesanan: ${order.orderNumber}'),
                  if (customerName.isNotEmpty)
                    Text('Pelanggan: $customerName'),
                  // Get voucher information from provider
                  if (Provider.of<VoucherProvider>(context, listen: false).activeVoucher != null)
                    Text('Voucher: ${Provider.of<VoucherProvider>(context, listen: false).voucherName} (${Provider.of<VoucherProvider>(context, listen: false).voucherCode})'),
                  if (transactionProvider.lastTransaction != null)
                    Text('Invoice: ${transactionProvider.lastTransaction!['invoice_number']}'),
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
          
          // Bersihkan keranjang, nama pelanggan, dan voucher
          setState(() {
            _cart = [];
            _customerNameController.clear();
            _voucherController.clear();
          });
          
          // Bersihkan voucher di provider
          final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
          voucherProvider.clearVoucher();
          
          // Cek apakah ini mode edit, jika ya, kembali ke halaman sebelumnya
          final args = ModalRoute.of(context)?.settings.arguments;
          final bool isEditMode = args != null && args is Map<String, dynamic> && args['edit_mode'] == true;
          
          if (isEditMode) {
            Navigator.pop(context, true); // Kembali dengan hasil true untuk refresh daftar pesanan
          }
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
  
  // Menampilkan dialog konfirmasi transaksi berhasil
  void _showTransactionSuccessDialog({
    required int itemCount,
    required double totalAmount,
    required PaymentMethod paymentMethod,
    required String customerName,
    required Order order,
    required TransactionProvider transactionProvider,
    required SettingsProvider settingsProvider,
  }) {
    // Tambahkan log untuk debugging
    print('Menampilkan dialog transaksi berhasil');
    print('itemCount: $itemCount');
    print('totalAmount: $totalAmount');
    print('paymentMethod: ${paymentMethod.name}');
    print('customerName: $customerName');
    print('lastTransaction: ${transactionProvider.lastTransaction != null}');
    print('lastTransaction detail: ${transactionProvider.lastTransaction}');
    
    // Tampilkan dialog langsung tanpa delay
    if (!mounted) {
      print('Widget tidak mounted, tidak bisa menampilkan dialog');
      return;
    }
    
    // Tampilkan dialog dengan animasi dan layout yang lebih menarik
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animasi checklist
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Lottie.asset(
                    'assets/animations/success_check.json',
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 10),
                // Judul dengan style yang lebih menarik
                const Text(
                  'Transaksi Berhasil!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                // Detail transaksi dalam card
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total item dan harga
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$itemCount item',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${FormatUtils.formatCurrency(totalAmount.toInt())}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      // Metode pembayaran
                      Row(
                        children: [
                          const Icon(Icons.payment, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Metode Pembayaran:',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                          Text(
                            paymentMethod.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Pelanggan (jika ada)
                      if (customerName.isNotEmpty) ...[                        
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pelanggan:',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                            Text(
                              customerName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Voucher (jika ada)
                      if (Provider.of<VoucherProvider>(context, listen: false).activeVoucher != null) ...[                        
                        Row(
                          children: [
                            const Icon(Icons.discount, color: Colors.purple, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Voucher:',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                            Text(
                              '${Provider.of<VoucherProvider>(context, listen: false).voucherName}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Invoice (jika ada)
                      if (transactionProvider.lastTransaction != null) ...[                        
                        Row(
                          children: [
                            const Icon(Icons.receipt, color: Colors.indigo, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Invoice:',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                            Text(
                              '${transactionProvider.lastTransaction!["invoice_number"]}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                // Tombol aksi dengan style yang lebih menarik
                Row(
                  children: [
                    // Tombol Transaksi Lagi
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(); // Tutup dialog
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Transaksi Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tombol Lihat Transaksi
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(); // Tutup dialog
                          if (transactionProvider.lastTransaction != null) {
                            final transactionId = transactionProvider.lastTransaction!['id'];
                            if (transactionId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionDetailScreen(
                                    transactionId: int.parse(transactionId.toString()),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Lihat Transaksi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Tombol Cetak Transaksi
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop(); // Tutup dialog
                      await _printTransactionReceipt(
                        order: order,
                        transactionProvider: transactionProvider,
                        settingsProvider: settingsProvider,
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Cetak Transaksi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Mencetak struk transaksi
  Future<void> _printTransactionReceipt({
    required Order order,
    required TransactionProvider transactionProvider,
    required SettingsProvider settingsProvider,
  }) async {
    try {
      if (transactionProvider.lastTransaction != null) {
        // Buat objek Receipt dari data transaksi
        final receipt = Receipt.fromTransaction(
          transaction: transactionProvider.lastTransaction!,
          order: order,
          receiptSettings: settingsProvider.receipt,
          cashierName: settingsProvider.general.cashierName ?? 'Kasir',
          storeName: settingsProvider.store.storeName ?? 'Toko',
          storeAddress: settingsProvider.store.storeAddress ?? 'Alamat Toko',
          storePhone: settingsProvider.store.storePhone ?? '-',
          storeEmail: settingsProvider.general.storeEmail ?? '-',
        );
        
        // Panggil ReceiptService untuk cetak struk
        final receiptService = ReceiptService();
        await receiptService.printReceipt(context, receipt);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak struk: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget untuk bagian keranjang mobile yang dioptimalkan
  Widget _buildMobileCartSection(ScrollController scrollController) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      children: [
        // Header keranjang yang compact
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _lightColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart, color: _primaryColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Keranjang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  if (_totalItems > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _totalItems.toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  if (_totalItems > 0)
                    IconButton(
                      onPressed: _clearCart,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Bersihkan',
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedOrdersScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long, size: 18),
                    tooltip: 'Lihat Pesanan Tersimpan',
                    color: _primaryColor,
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Daftar item keranjang dengan scroll yang dioptimalkan
        Expanded(
          child: _totalItems == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Keranjang kosong',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text('Tambahkan Produk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  // Optimasi physics untuk scrolling yang lebih smooth
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  // Optimasi caching untuk performa yang lebih baik
                  cacheExtent: 300.0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final item = _cart[index];
                    final categoryColor = _categoryColors[item['category']] ?? Colors.grey;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 2,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            // Icon produk yang lebih kecil
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Icon(
                                  item['icon'] ?? Icons.fastfood,
                                  size: 16,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Informasi produk yang compact
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['name'],
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '${FormatUtils.formatCurrency(item['price'])}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '× ${item['quantity']}',
                                        style: TextStyle(color: _primaryColor, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${FormatUtils.formatCurrency((item['price'] * item['quantity']).toInt())}',
                                        style: TextStyle(color: _primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Kontrol jumlah yang compact
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _decreaseQuantity(item['id']),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(Icons.remove, size: 16, color: Colors.red.shade600),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text(
                                      item['quantity'].toString(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _addToCart(item['product_ref']),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(Icons.add, size: 16, color: Colors.green.shade600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        
        // Footer dengan total dan tombol yang dioptimalkan untuk mobile
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _lightColor,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Ringkasan total yang compact
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal ($_totalItems item)',
                          style: TextStyle(color: _primaryColor, fontSize: 12),
                        ),
                        Text(
                          '${FormatUtils.formatCurrency(_subtotal.toInt())}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            );
                          },
                        ),
                        Text(
                          '${FormatUtils.formatCurrency(_tax.toInt())}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _primaryColor),
                        ),
                        Text(
                          '${FormatUtils.formatCurrency(_totalAmount.toInt())}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Input fields yang lebih compact
              ExpansionTile(
                title: const Text('Detail Tambahan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                initiallyExpanded: false,
                childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  // Input nama pelanggan
                  TextField(
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Pelanggan',
                      hintText: 'Opsional',
                      prefixIcon: Icon(Icons.person, color: _primaryColor, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      labelStyle: const TextStyle(fontSize: 12),
                      hintStyle: const TextStyle(fontSize: 12),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  // Input kode voucher
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _voucherController,
                          decoration: InputDecoration(
                            labelText: 'Kode Voucher',
                            hintText: 'Opsional',
                            prefixIcon: Icon(Icons.discount, color: _primaryColor, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _primaryColor),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            labelStyle: const TextStyle(fontSize: 12),
                            hintStyle: const TextStyle(fontSize: 12),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _validateVoucher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          minimumSize: const Size(60, 40),
                        ),
                        child: const Text('Terapkan', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  // Tampilkan informasi voucher jika ada
                  Consumer<VoucherProvider>(
                    builder: (context, voucherProvider, child) {
                      if (voucherProvider.activeVoucher != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Voucher ${voucherProvider.voucherName}',
                                      style: const TextStyle(color: Colors.green, fontSize: 11),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '- ${FormatUtils.formatCurrency(voucherProvider.discountValue.toInt())}',
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                    InkWell(
                                      onTap: _clearVoucher,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(Icons.close, size: 14, color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Tombol aksi yang dioptimalkan
              Row(
                children: [
                  // Tombol simpan
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _totalItems == 0 ? null : () {
                          _saveOrder();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('SIMPAN', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor),
                          disabledForegroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol checkout
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _totalItems == 0 ? null : () {
                          Navigator.pop(context);
                          _checkout();
                        },
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('CHECKOUT', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  // Widget untuk bagian keranjang desktop
  Widget _buildCartSection({bool isTablet = false}) {
    return Column(
      children: [
        // Header keranjang
        Container(
          padding: EdgeInsets.all(isTablet ? 12 : 16),
          decoration: BoxDecoration(
            color: _lightColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart, color: _primaryColor, size: isTablet ? 18 : 20),
                  SizedBox(width: isTablet ? 6 : 8),
                  Text(
                    'Keranjang',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  SizedBox(width: isTablet ? 6 : 8),
                  if (_totalItems > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 6 : 8, 
                        vertical: isTablet ? 2 : 2
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _totalItems.toString(),
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: isTablet ? 11 : 12
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  if (_totalItems > 0)
                    IconButton(
                      onPressed: _clearCart,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Bersihkan',
                      style: IconButton.styleFrom(
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
                  // Optimasi physics untuk scrolling yang lebih smooth
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  // Optimasi caching untuk performa yang lebih baik
                  cacheExtent: 300.0,
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final item = _cart[index];
                    final categoryColor = _categoryColors[item['category']] ?? Colors.grey;
                    
                    return Card(
                      margin: EdgeInsets.symmetric(
                        horizontal: isTablet ? 6 : 8, 
                        vertical: isTablet ? 3 : 6
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 8 : 12),
                        child: Row(
                          children: [
                            // Warna produk (menggantikan gambar)
                            Container(
                              width: isTablet ? 32 : 40,
                              height: isTablet ? 32 : 40,
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Icon(
                                  item['icon'] ?? Icons.fastfood,
                                  size: isTablet ? 16 : 20,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                            SizedBox(width: isTablet ? 8 : 12),
                            // Informasi produk
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 12 : 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isTablet ? 2 : 4),
                                  Text(
                                    '${FormatUtils.formatCurrency(item['price'])}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700, 
                                      fontSize: isTablet ? 10 : 12
                                    ),
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
                                  iconSize: isTablet ? 16 : 20,
                                  padding: EdgeInsets.all(isTablet ? 1 : 0),
                                  constraints: BoxConstraints(
                                    minWidth: isTablet ? 24 : 24,
                                    minHeight: isTablet ? 24 : 24,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 6 : 8, 
                                    vertical: isTablet ? 2 : 4
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    item['quantity'].toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 11 : 14,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _addToCart(item['product_ref']),
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: Colors.green,
                                  iconSize: isTablet ? 16 : 20,
                                  padding: EdgeInsets.all(isTablet ? 1 : 0),
                                  constraints: BoxConstraints(
                                    minWidth: isTablet ? 24 : 24,
                                    minHeight: isTablet ? 24 : 24,
                                  ),
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
          padding: EdgeInsets.all(isTablet ? 10 : 16),
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
                padding: EdgeInsets.all(isTablet ? 10 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Subtotal', 
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: isTablet ? 13 : 14,
                              )
                            ),
                            SizedBox(width: isTablet ? 4 : 4),
                            Text(
                              '($_totalItems item)',
                              style: TextStyle(
                                fontSize: isTablet ? 11 : 12, 
                                color: Colors.grey.shade600
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${FormatUtils.formatCurrency(_subtotal.toInt())}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 13 : 14,
                          ),
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
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: isTablet ? 13 : 14,
                              ),
                            );
                          },
                        ),
                        Text(
                          '${FormatUtils.formatCurrency(_tax.toInt())}',
                          style: TextStyle(
                            fontSize: isTablet ? 13 : 14,
                          ),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: isTablet ? 16 : 16, 
                                color: _primaryColor
                              ),
                            );
                          },
                        ),
                        Text(
                          '${FormatUtils.formatCurrency(_totalAmount.toInt())}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: isTablet ? 16 : 16, 
                            color: _primaryColor
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 12 : 16),
                    
                    // Tombol toggle untuk input customer dan voucher
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showCustomerVoucherInputs = !_showCustomerVoucherInputs;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 12 : 16,
                          vertical: isTablet ? 10 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: _showCustomerVoucherInputs 
                              ? _primaryColor.withOpacity(0.1) 
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _showCustomerVoucherInputs 
                                ? _primaryColor 
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _showCustomerVoucherInputs 
                                      ? Icons.person 
                                      : Icons.person_add_outlined,
                                  color: _primaryColor,
                                  size: isTablet ? 16 : 18,
                                ),
                                SizedBox(width: isTablet ? 6 : 8),
                                Text(
                                  _showCustomerVoucherInputs 
                                      ? 'Sembunyikan Detail' 
                                      : 'Tambah Detail Pelanggan',
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _showCustomerVoucherInputs 
                                  ? Icons.keyboard_arrow_up 
                                  : Icons.keyboard_arrow_down,
                              color: _primaryColor,
                              size: isTablet ? 16 : 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Input customer dan voucher dengan animasi
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _showCustomerVoucherInputs ? null : 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _showCustomerVoucherInputs ? 1.0 : 0.0,
                        child: _showCustomerVoucherInputs
                            ? Container(
                                margin: EdgeInsets.only(top: isTablet ? 8 : 12),
                                padding: EdgeInsets.all(isTablet ? 12 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Input nama pelanggan
                                    TextField(
                                      controller: _customerNameController,
                                      style: TextStyle(fontSize: isTablet ? 12 : 14),
                                      decoration: InputDecoration(
                                        labelText: 'Nama Pelanggan',
                                        hintText: 'Opsional',
                                        labelStyle: TextStyle(fontSize: isTablet ? 12 : 14),
                                        hintStyle: TextStyle(fontSize: isTablet ? 12 : 14),
                                        prefixIcon: Icon(
                                          Icons.person,
                                          color: _primaryColor,
                                          size: isTablet ? 16 : 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: _primaryColor),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 12 : 16,
                                          vertical: isTablet ? 10 : 14,
                                        ),
                                        isDense: isTablet,
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 10 : 12),
                                    
                                    // Input kode voucher
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _voucherController,
                                            style: TextStyle(fontSize: isTablet ? 12 : 14),
                                            decoration: InputDecoration(
                                              labelText: 'Kode Voucher',
                                              hintText: 'Opsional',
                                              labelStyle: TextStyle(fontSize: isTablet ? 12 : 14),
                                              hintStyle: TextStyle(fontSize: isTablet ? 12 : 14),
                                              prefixIcon: Icon(
                                                Icons.discount,
                                                color: _primaryColor,
                                                size: isTablet ? 16 : 18,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.grey.shade300),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.grey.shade300),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: _primaryColor),
                                              ),
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: isTablet ? 12 : 16,
                                                vertical: isTablet ? 10 : 14,
                                              ),
                                              isDense: isTablet,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: isTablet ? 8 : 12),
                                        ElevatedButton(
                                          onPressed: _validateVoucher,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _primaryColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isTablet ? 12 : 16,
                                              vertical: isTablet ? 10 : 14,
                                            ),
                                            minimumSize: Size(isTablet ? 70 : 80, isTablet ? 40 : 48),
                                          ),
                                          child: Text(
                                            'Terapkan',
                                            style: TextStyle(fontSize: isTablet ? 11 : 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    // Tampilkan informasi voucher jika ada
                    Consumer<VoucherProvider>(
                      builder: (context, voucherProvider, child) {
                        if (voucherProvider.activeVoucher != null) {
                          return Padding(
                            padding: EdgeInsets.only(top: isTablet ? 6 : 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: isTablet ? 14 : 16),
                                    SizedBox(width: isTablet ? 3 : 4),
                                    Text(
                                      'Voucher ${voucherProvider.voucherName}',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: isTablet ? 12 : 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '- ${FormatUtils.formatCurrency(voucherProvider.discountValue.toInt())}',
                                      style: TextStyle(
                                        color: Colors.green, 
                                        fontWeight: FontWeight.bold,
                                        fontSize: isTablet ? 12 : 14,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _clearVoucher,
                                      icon: Icon(Icons.close, size: isTablet ? 14 : 16),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTablet ? 12 : 16),
              // Tombol simpan dan checkout
              Row(
                children: [
                  // Tombol simpan
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: isTablet ? 42 : 50,
                      child: OutlinedButton.icon(
                        onPressed: _totalItems == 0 ? null : _saveOrder,
                        icon: Icon(Icons.save, size: isTablet ? 16 : 18),
                        label: Text(
                          'SIMPAN',
                          style: TextStyle(fontSize: isTablet ? 12 : 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor),
                          disabledForegroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 6 : 8),
                  // Tombol checkout
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: isTablet ? 42 : 50,
                      child: ElevatedButton.icon(
                        onPressed: _totalItems == 0 ? null : _checkout,
                        icon: Icon(Icons.payment, size: isTablet ? 16 : 18),
                        label: Text(
                          'CHECKOUT',
                          style: TextStyle(fontSize: isTablet ? 12 : 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
