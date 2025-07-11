import 'package:flutter/material.dart';
import 'package:cne_pos_apps/utils/format_utils.dart';

// Ensure these classes are properly exported

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
      // Handle itemsCount yang mungkin null
      int itemsCount = 0;
      if (json['items_count'] != null) {
        if (json['items_count'] is int) {
          itemsCount = json['items_count'];
        } else if (json['items_count'] is String) {
          itemsCount = int.tryParse(json['items_count']) ?? 0;
        }
      }
      
      // Handle nilai null untuk semua properti
      int id = 0;
      if (json['id'] != null) {
        if (json['id'] is int) {
          id = json['id'];
        } else if (json['id'] is String) {
          id = int.tryParse(json['id']) ?? 0;
        }
      }
      
      String stockDate = 'Unknown Date';
      if (json['stock_date'] != null) {
        stockDate = json['stock_date'].toString();
      }
      
      int warehouseId = 0;
      if (json['warehouse_id'] != null) {
        if (json['warehouse_id'] is int) {
          warehouseId = json['warehouse_id'];
        } else if (json['warehouse_id'] is String) {
          warehouseId = int.tryParse(json['warehouse_id']) ?? 0;
        }
      }
      
      String warehouseName = 'Unknown Warehouse';
      if (json['warehouse_name'] != null) {
        warehouseName = json['warehouse_name'].toString();
      }
      
      String? notes;
      if (json['notes'] != null && json['notes'] != 'null') {
        notes = json['notes'].toString();
      }
      
      bool isLocked = false;
      if (json['is_locked'] != null) {
        if (json['is_locked'] is bool) {
          isLocked = json['is_locked'];
        } else if (json['is_locked'] is int) {
          isLocked = json['is_locked'] == 1;
        } else if (json['is_locked'] is String) {
          isLocked = json['is_locked'] == '1' || json['is_locked'].toLowerCase() == 'true';
        }
      }
      
      String createdBy = 'Unknown';
      if (json['created_by'] != null) {
        createdBy = json['created_by'].toString();
      }
      
      DateTime createdAt = DateTime.now();
      if (json['created_at'] != null) {
        try {
          createdAt = DateTime.parse(json['created_at']);
        } catch (e) {
          print('Error parsing created_at: $e');
        }
      }
      
      DateTime updatedAt = DateTime.now();
      if (json['updated_at'] != null) {
        try {
          updatedAt = DateTime.parse(json['updated_at']);
        } catch (e) {
          print('Error parsing updated_at: $e');
        }
      }
      
      return DailyInventoryStock(
        id: id,
        stockDate: stockDate,
        warehouseId: warehouseId,
        warehouseName: warehouseName,
        notes: notes,
        isLocked: isLocked,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
        itemsCount: itemsCount,
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
    try {
      // Handle nilai null untuk success
      bool success = false;
      if (json['success'] != null) {
        if (json['success'] is bool) {
          success = json['success'];
        } else if (json['success'] is int) {
          success = json['success'] == 1;
        } else if (json['success'] is String) {
          success = json['success'] == '1' || json['success'].toLowerCase() == 'true';
        }
      }
      
      // Handle nilai null untuk data
      DailyInventoryStockData? data;
      if (json['data'] != null) {
        try {
          data = DailyInventoryStockData.fromJson(json['data']);
        } catch (e) {
          print('Error parsing data in DailyInventoryStockResponse: $e');
        }
      }
      
      // Handle nilai null untuk message
      String? message;
      if (json['message'] != null) {
        message = json['message'].toString();
      }
      
      return DailyInventoryStockResponse(
        success: success,
        data: data,
        message: message,
      );
    } catch (e) {
      print('Error parsing DailyInventoryStockResponse JSON: $e');
      print('Problematic JSON: $json');
      return DailyInventoryStockResponse(
        success: false,
        data: null,
        message: 'Error parsing response: $e',
      );
    }
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
    try {
      // Handle nilai null untuk daily_inventory_stocks
      List<DailyInventoryStock> stocks = [];
      if (json['daily_inventory_stocks'] != null && json['daily_inventory_stocks'] is List) {
        stocks = (json['daily_inventory_stocks'] as List)
            .map((stock) => DailyInventoryStock.fromJson(stock))
            .toList();
      }
      
      // Handle nilai null untuk pagination
      Pagination pagination;
      if (json['pagination'] != null) {
        pagination = Pagination.fromJson(json['pagination']);
      } else {
        pagination = Pagination(
          total: 0,
          perPage: 10,
          currentPage: 1,
          lastPage: 1,
        );
      }
      
      return DailyInventoryStockData(
        dailyInventoryStocks: stocks,
        pagination: pagination,
      );
    } catch (e) {
      print('Error parsing DailyInventoryStockData JSON: $e');
      print('Problematic JSON: $json');
      return DailyInventoryStockData(
        dailyInventoryStocks: [],
        pagination: Pagination(
          total: 0,
          perPage: 10,
          currentPage: 1,
          lastPage: 1,
        ),
      );
    }
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
    try {
      // Handle nilai null untuk semua properti
      int total = 0;
      if (json['total'] != null) {
        if (json['total'] is int) {
          total = json['total'];
        } else if (json['total'] is String) {
          total = int.tryParse(json['total']) ?? 0;
        }
      }
      
      int perPage = 10;
      if (json['per_page'] != null) {
        if (json['per_page'] is int) {
          perPage = json['per_page'];
        } else if (json['per_page'] is String) {
          perPage = int.tryParse(json['per_page']) ?? 10;
        }
      }
      
      int currentPage = 1;
      if (json['current_page'] != null) {
        if (json['current_page'] is int) {
          currentPage = json['current_page'];
        } else if (json['current_page'] is String) {
          currentPage = int.tryParse(json['current_page']) ?? 1;
        }
      }
      
      int lastPage = 1;
      if (json['last_page'] != null) {
        if (json['last_page'] is int) {
          lastPage = json['last_page'];
        } else if (json['last_page'] is String) {
          lastPage = int.tryParse(json['last_page']) ?? 1;
        }
      }
      
      return Pagination(
        total: total,
        perPage: perPage,
        currentPage: currentPage,
        lastPage: lastPage,
      );
    } catch (e) {
      print('Error parsing Pagination JSON: $e');
      print('Problematic JSON: $json');
      return Pagination(
        total: 0,
        perPage: 10,
        currentPage: 1,
        lastPage: 1,
      );
    }
  }
}