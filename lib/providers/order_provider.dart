import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<Order> _savedOrders = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Order> get savedOrders => _savedOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Mengambil semua pesanan yang disimpan
  Future<void> fetchSavedOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _savedOrders = await _orderService.getSavedOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Gagal mengambil pesanan yang disimpan: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Menyimpan pesanan baru
  Future<bool> saveOrder(Order order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _orderService.saveOrder(order);
      
      if (result) {
        // Jika berhasil disimpan, perbarui daftar pesanan
        await fetchSavedOrders();
      } else {
        _error = 'Gagal menyimpan pesanan';
        _isLoading = false;
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      _error = 'Gagal menyimpan pesanan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Menghapus pesanan
  Future<bool> deleteOrder(String orderNumber) async {
    try {
      final result = await _orderService.deleteOrder(orderNumber);
      
      if (result) {
        // Jika berhasil dihapus, perbarui daftar pesanan
        await fetchSavedOrders();
      } else {
        _error = 'Gagal menghapus pesanan';
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      _error = 'Gagal menghapus pesanan: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Memperbarui status pesanan
  Future<bool> updateOrderStatus(String orderNumber, String newStatus) async {
    try {
      final result = await _orderService.updateOrderStatus(orderNumber, newStatus);
      
      if (result) {
        // Jika berhasil diperbarui, perbarui daftar pesanan
        await fetchSavedOrders();
      } else {
        _error = 'Gagal memperbarui status pesanan';
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      _error = 'Gagal memperbarui status pesanan: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Menghasilkan nomor pesanan unik
  String generateOrderNumber() {
    return _orderService.generateOrderNumber();
  }
  
  // Membersihkan error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}