import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';

class OrderService {
  static const String _savedOrdersKey = 'saved_orders';
  
  // Menyimpan pesanan ke SharedPreferences
  Future<bool> saveOrder(Order order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ambil daftar pesanan yang sudah ada
      final List<Order> existingOrders = await getSavedOrders();
      
      // Tambahkan pesanan baru
      existingOrders.add(order);
      
      // Konversi daftar pesanan ke JSON
      final List<String> ordersJsonList = existingOrders
          .map((order) => jsonEncode(order.toJson()))
          .toList();
      
      // Simpan daftar pesanan yang diperbarui
      await prefs.setStringList(_savedOrdersKey, ordersJsonList);
      
      return true;
    } catch (e) {
      print('Error saving order: $e');
      return false;
    }
  }
  
  // Mengambil semua pesanan yang disimpan dari SharedPreferences
  Future<List<Order>> getSavedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ambil daftar pesanan dari SharedPreferences
      final List<String>? ordersJsonList = prefs.getStringList(_savedOrdersKey);
      
      // Jika tidak ada pesanan yang disimpan, kembalikan daftar kosong
      if (ordersJsonList == null || ordersJsonList.isEmpty) {
        return [];
      }
      
      // Konversi daftar JSON ke daftar Order
      final List<Order> orders = ordersJsonList
          .map((orderJson) => Order.fromJson(jsonDecode(orderJson)))
          .toList();
      
      // Urutkan pesanan berdasarkan tanggal pembuatan (terbaru dulu)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return orders;
    } catch (e) {
      print('Error getting saved orders: $e');
      return [];
    }
  }
  
  // Menghapus pesanan dari SharedPreferences
  Future<bool> deleteOrder(String orderNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ambil daftar pesanan yang sudah ada
      final List<Order> existingOrders = await getSavedOrders();
      
      // Hapus pesanan dengan nomor pesanan yang sesuai
      existingOrders.removeWhere((order) => order.orderNumber == orderNumber);
      
      // Konversi daftar pesanan ke JSON
      final List<String> ordersJsonList = existingOrders
          .map((order) => jsonEncode(order.toJson()))
          .toList();
      
      // Simpan daftar pesanan yang diperbarui
      await prefs.setStringList(_savedOrdersKey, ordersJsonList);
      
      return true;
    } catch (e) {
      print('Error deleting order: $e');
      return false;
    }
  }
  
  // Memperbarui status pesanan
  Future<bool> updateOrderStatus(String orderNumber, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ambil daftar pesanan yang sudah ada
      final List<Order> existingOrders = await getSavedOrders();
      
      // Cari pesanan dengan nomor pesanan yang sesuai
      final int orderIndex = existingOrders.indexWhere(
        (order) => order.orderNumber == orderNumber
      );
      
      // Jika pesanan ditemukan, perbarui statusnya
      if (orderIndex != -1) {
        existingOrders[orderIndex] = existingOrders[orderIndex].copyWith(
          status: newStatus
        );
        
        // Konversi daftar pesanan ke JSON
        final List<String> ordersJsonList = existingOrders
            .map((order) => jsonEncode(order.toJson()))
            .toList();
        
        // Simpan daftar pesanan yang diperbarui
        await prefs.setStringList(_savedOrdersKey, ordersJsonList);
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }
  
  // Menghasilkan nomor pesanan unik
  String generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    final random = timestamp.substring(timestamp.length - 6);
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    return 'ORD-$date-$random';
  }
}