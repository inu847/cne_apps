import 'package:flutter/material.dart';

class DailyInventoryStockItem {
  final int id;
  final int inventoryItemId;
  final String inventoryItemName;
  final int inventoryUomId;
  final String inventoryUomName;
  final double quantityIn;
  final double quantityOut;
  final String? notes;

  DailyInventoryStockItem({
    required this.id,
    required this.inventoryItemId,
    required this.inventoryItemName,
    required this.inventoryUomId,
    required this.inventoryUomName,
    required this.quantityIn,
    required this.quantityOut,
    this.notes,
  });

  factory DailyInventoryStockItem.fromJson(Map<String, dynamic> json) {
    try {
      // Pastikan notes tidak null dan bukan 'null' string
      String? notesValue;
      if (json['notes'] != null && json['notes'] != 'null') {
        notesValue = json['notes'].toString();
      }
      
      // Pastikan inventory_item_name ada dan tidak null
      String itemName = 'Unknown Item';
      if (json['inventory_item_name'] != null) {
        itemName = json['inventory_item_name'].toString();
      }
      
      return DailyInventoryStockItem(
        id: json['id'],
        inventoryItemId: json['inventory_item_id'],
        inventoryItemName: itemName,
        inventoryUomId: json['inventory_uom_id'],
        inventoryUomName: json['inventory_uom_name'],
        quantityIn: json['quantity_in'] is String 
            ? double.tryParse(json['quantity_in']) ?? 0.0 
            : json['quantity_in'] is int 
                ? (json['quantity_in'] as int).toDouble() 
                : json['quantity_in'] ?? 0.0,
        quantityOut: json['quantity_out'] is String 
            ? double.tryParse(json['quantity_out']) ?? 0.0 
            : json['quantity_out'] is int 
                ? (json['quantity_out'] as int).toDouble() 
                : json['quantity_out'] ?? 0.0,
        notes: notesValue,
      );
    } catch (e) {
      print('Error parsing DailyInventoryStockItem JSON: $e');
      print('Problematic JSON: $json');
      return DailyInventoryStockItem(
        id: 0,
        inventoryItemId: 0,
        inventoryItemName: 'Unknown Item',
        inventoryUomId: 0,
        inventoryUomName: 'Unknown UOM',
        quantityIn: 0,
        quantityOut: 0,
        notes: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_item_id': inventoryItemId,
      'inventory_item_name': inventoryItemName,
      'inventory_uom_id': inventoryUomId,
      'inventory_uom_name': inventoryUomName,
      'quantity_in': quantityIn,
      'quantity_out': quantityOut,
      'notes': notes,
    };
  }

  // Helper method untuk mendapatkan stok bersih (masuk - keluar)
  double get netQuantity => quantityIn - quantityOut;

  // Helper method untuk mendapatkan warna berdasarkan stok bersih
  Color get netQuantityColor => netQuantity > 0 ? Colors.green : netQuantity < 0 ? Colors.red : Colors.grey;
}

class DailyInventoryStockDetail {
  final int id;
  final String stockDate;
  final int warehouseId;
  final String warehouseName;
  final String? notes;
  final bool isLocked;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DailyInventoryStockItem> items;

  DailyInventoryStockDetail({
    required this.id,
    required this.stockDate,
    required this.warehouseId,
    required this.warehouseName,
    this.notes,
    required this.isLocked,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory DailyInventoryStockDetail.fromJson(Map<String, dynamic> json) {
    try {
      // Pastikan notes tidak null dan bukan 'null' string
      String? notesValue;
      if (json['notes'] != null && json['notes'] != 'null') {
        notesValue = json['notes'].toString();
      }
      
      // Pastikan items ada dan merupakan List
      List<DailyInventoryStockItem> itemsList = [];
      if (json['items'] != null && json['items'] is List) {
        itemsList = (json['items'] as List)
            .map((item) => DailyInventoryStockItem.fromJson(item))
            .toList();
      }
      
      // Pastikan warehouse_name ada dan tidak null
      String warehouseName = 'Unknown Warehouse';
      if (json['warehouse_name'] != null) {
        warehouseName = json['warehouse_name'].toString();
      }
      
      // Pastikan created_by ada dan tidak null
      String createdBy = 'Unknown';
      if (json['created_by'] != null) {
        createdBy = json['created_by'].toString();
      }
      
      return DailyInventoryStockDetail(
        id: json['id'] ?? 0,
        stockDate: json['stock_date'] ?? 'Unknown Date',
        warehouseId: json['warehouse_id'] ?? 0,
        warehouseName: warehouseName,
        notes: notesValue,
        isLocked: json['is_locked'] ?? false,
        createdBy: createdBy,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
        items: itemsList,
      );
    } catch (e) {
      print('Error parsing DailyInventoryStockDetail JSON: $e');
      print('Problematic JSON: $json');
      return DailyInventoryStockDetail(
        id: 0,
        stockDate: 'Unknown Date',
        warehouseId: 0,
        warehouseName: 'Unknown Warehouse',
        notes: null,
        isLocked: false,
        createdBy: 'Unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [],
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
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Helper method untuk mendapatkan status dalam bentuk yang lebih user-friendly
  String get statusText => isLocked ? 'Terkunci' : 'Belum Terkunci';

  // Helper method untuk mendapatkan warna status
  Color get statusColor => isLocked ? Colors.red : Colors.green;

  // Helper method untuk mendapatkan icon status
  IconData get statusIcon => isLocked ? Icons.lock : Icons.lock_open;
}

class DailyInventoryStockDetailResponse {
  final bool success;
  final DailyInventoryStockDetailData? data;
  final String? message;

  DailyInventoryStockDetailResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory DailyInventoryStockDetailResponse.fromJson(Map<String, dynamic> json) {
    try {
      return DailyInventoryStockDetailResponse(
        success: json['success'] ?? false,
        data: json['data'] != null ? DailyInventoryStockDetailData.fromJson(json['data']) : null,
        message: json['message'] as String?,
      );
    } catch (e) {
      print('Error parsing DailyInventoryStockDetailResponse JSON: $e');
      print('Problematic JSON: $json');
      
      return DailyInventoryStockDetailResponse(
        success: false,
        data: null,
        message: 'Error parsing response: $e',
      );
    }
  }
}

class DailyInventoryStockDetailData {
  final DailyInventoryStockDetail dailyInventoryStock;

  DailyInventoryStockDetailData({
    required this.dailyInventoryStock,
  });

  factory DailyInventoryStockDetailData.fromJson(Map<String, dynamic> json) {
    try {
      if (json['daily_inventory_stock'] == null) {
        throw Exception('daily_inventory_stock is null');
      }
      
      return DailyInventoryStockDetailData(
        dailyInventoryStock: DailyInventoryStockDetail.fromJson(json['daily_inventory_stock']),
      );
    } catch (e) {
      print('Error parsing DailyInventoryStockDetailData JSON: $e');
      print('Problematic JSON: $json');
      
      // Buat objek kosong dengan nilai default
      return DailyInventoryStockDetailData(
        dailyInventoryStock: DailyInventoryStockDetail(
          id: 0,
          stockDate: 'Unknown Date',
          warehouseId: 0,
          warehouseName: 'Unknown Warehouse',
          notes: null,
          isLocked: false,
          createdBy: 'Unknown',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
        ),
      );
    }
  }
}