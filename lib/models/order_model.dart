import 'package:flutter/material.dart';
import '../utils/format_utils.dart';
import 'product_model.dart';

class Order {
  final int? id;
  final String orderNumber;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final DateTime createdAt;
  final String status; // 'saved', 'completed', 'cancelled'

  Order({
    this.id,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.createdAt,
    required this.status,
  });

  // Menghitung total item dalam pesanan
  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Mengkonversi Order ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  // Membuat Order dari JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      subtotal: json['subtotal'].toDouble(),
      tax: json['tax'].toDouble(),
      total: json['total'].toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'],
    );
  }

  // Membuat salinan Order dengan nilai yang diperbarui
  Order copyWith({
    int? id,
    String? orderNumber,
    List<OrderItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    DateTime? createdAt,
    String? status,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

class OrderItem {
  final int? id;
  final int productId;
  final String productName;
  final int price;
  final int quantity;
  final String category;
  final IconData icon;

  OrderItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.category,
    required this.icon,
  });

  // Menghitung total harga item
  int get total => price * quantity;

  // Mengkonversi OrderItem ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'category': category,
      // Tidak menyimpan icon karena tidak dapat dikonversi ke JSON
    };
  }

  // Membuat OrderItem dari JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Menentukan icon berdasarkan kategori
    IconData getIconForCategory(String category) {
      switch (category.toLowerCase()) {
        case 'elektronik':
          return Icons.devices;
        case 'pakaian':
          return Icons.checkroom;
        case 'makanan':
          return Icons.restaurant;
        case 'minuman':
          return Icons.local_drink;
        case 'kesehatan':
          return Icons.health_and_safety;
        case 'kecantikan':
          return Icons.face;
        case 'rumah tangga':
          return Icons.home;
        case 'olahraga':
          return Icons.sports_soccer;
        case 'mainan':
          return Icons.toys;
        case 'buku':
          return Icons.book;
        default:
          return Icons.inventory_2;
      }
    }

    return OrderItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      price: json['price'],
      quantity: json['quantity'],
      category: json['category'],
      icon: getIconForCategory(json['category']),
    );
  }

  // Membuat OrderItem dari item keranjang
  factory OrderItem.fromCartItem(Map<String, dynamic> cartItem) {
    return OrderItem(
      productId: cartItem['id'],
      productName: cartItem['name'],
      price: cartItem['price'],
      quantity: cartItem['quantity'],
      category: cartItem['category'],
      icon: cartItem['icon'],
    );
  }

  // Membuat salinan OrderItem dengan nilai yang diperbarui
  OrderItem copyWith({
    int? id,
    int? productId,
    String? productName,
    int? price,
    int? quantity,
    String? category,
    IconData? icon,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      icon: icon ?? this.icon,
    );
  }
}