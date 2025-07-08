import 'package:flutter/material.dart';

class DailyInventoryStock {
  final int id;
  final String stockDate;
  final int warehouseId;
  final String warehouseName;
  final String? notes;
  final bool isLocked;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int itemsCount;

  DailyInventoryStock({
    required this.id,
    required this.stockDate,
    required this.warehouseId,
    required this.warehouseName,
    this.notes,
    required this.isLocked,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.itemsCount,
  });

  factory DailyInventoryStock.fromJson(Map<String, dynamic> json) {
    try {
      return DailyInventoryStock(
        id: json['id'],
        stockDate: json['stock_date'],
        warehouseId: json['warehouse_id'],
        warehouseName: json['warehouse_name'],
        notes: json['notes'],
        isLocked: json['is_locked'],
        createdBy: json['created_by'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        itemsCount: json['items_count'],
      );
    } catch (e) {
      print('Error parsing DailyInventoryStock JSON: $e');
      print('Problematic JSON: $json');
      return DailyInventoryStock(
        id: 0,
        stockDate: 'Unknown Date',
        warehouseId: 0,
        warehouseName: 'Unknown Warehouse',
        notes: 'Error parsing data',
        isLocked: false,
        createdBy: 'Unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        itemsCount: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stock_date': stockDate,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'notes': notes,
      'is_locked': isLocked,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items_count': itemsCount,
    };
  }

  // Helper method untuk mendapatkan status dalam bentuk yang lebih user-friendly
  String get statusText => isLocked ? 'Terkunci' : 'Belum Terkunci';

  // Helper method untuk mendapatkan warna status
  Color get statusColor => isLocked ? Colors.red : Colors.green;

  // Helper method untuk mendapatkan icon status
  IconData get statusIcon => isLocked ? Icons.lock : Icons.lock_open;
}

class DailyInventoryStockResponse {
  final bool success;
  final DailyInventoryStockData? data;
  final String? message;

  DailyInventoryStockResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory DailyInventoryStockResponse.fromJson(Map<String, dynamic> json) {
    return DailyInventoryStockResponse(
      success: json['success'],
      data: json['data'] != null ? DailyInventoryStockData.fromJson(json['data']) : null,
      message: json['message'],
    );
  }
}

class DailyInventoryStockData {
  final List<DailyInventoryStock> dailyInventoryStocks;
  final Pagination pagination;

  DailyInventoryStockData({
    required this.dailyInventoryStocks,
    required this.pagination,
  });

  factory DailyInventoryStockData.fromJson(Map<String, dynamic> json) {
    return DailyInventoryStockData(
      dailyInventoryStocks: (json['daily_inventory_stocks'] as List)
          .map((stock) => DailyInventoryStock.fromJson(stock))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class Pagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  Pagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      lastPage: json['last_page'],
    );
  }
}