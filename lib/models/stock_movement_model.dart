import 'package:flutter/material.dart';
import '../utils/format_utils.dart';

class StockMovement {
  final int id;
  final int productId;
  final String productName;
  final String? productSku;
  final String type; // 'in', 'out', 'adjustment'
  final int quantity;
  final int? previousStock;
  final int? currentStock;
  final String? reason;
  final String? notes;
  final String? referenceType; // 'sale', 'purchase', 'adjustment', 'transfer'
  final int? referenceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int userId;
  final String userName;
  
  // New fields from API response
  final double? quantityBefore;
  final double? quantityChange;
  final double? quantityAfter;
  final String? movementType;
  final String? sourceType;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    required this.type,
    required this.quantity,
    this.previousStock,
    this.currentStock,
    this.reason,
    this.notes,
    this.referenceType,
    this.referenceId,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.userName,
    this.quantityBefore,
    this.quantityChange,
    this.quantityAfter,
    this.movementType,
    this.sourceType,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    try {
      return StockMovement(
        id: FormatUtils.safeParseInt(json['id']),
        productId: FormatUtils.safeParseInt(json['product_id']),
        productName: json['product_name'] ?? '',
        productSku: json['product_sku'],
        type: json['type'] ?? '',
        quantity: FormatUtils.safeParseInt(json['quantity']),
        previousStock: json['previous_stock'] != null 
            ? FormatUtils.safeParseInt(json['previous_stock']) 
            : null,
        currentStock: json['current_stock'] != null 
            ? FormatUtils.safeParseInt(json['current_stock']) 
            : null,
        reason: json['reason'],
        notes: json['notes'],
        referenceType: json['reference_type'],
        referenceId: json['reference_id'] != null 
            ? FormatUtils.safeParseInt(json['reference_id']) 
            : null,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        userId: FormatUtils.safeParseInt(json['user_id']),
        userName: json['user_name'] ?? '',
        // New fields from API
        quantityBefore: json['quantity_before'] != null 
            ? double.tryParse(json['quantity_before'].toString()) 
            : null,
        quantityChange: json['quantity_change'] != null 
            ? double.tryParse(json['quantity_change'].toString()) 
            : null,
        quantityAfter: json['quantity_after'] != null 
            ? double.tryParse(json['quantity_after'].toString()) 
            : null,
        movementType: json['movement_type'],
        sourceType: json['source_type'],
      );
    } catch (e) {
      print('Error parsing StockMovement JSON: $e');
      print('Problematic JSON: $json');
      // Return a default stock movement with minimal data to prevent app crashes
      return StockMovement(
        id: json['id'] is int ? json['id'] : 0,
        productId: json['product_id'] is int ? json['product_id'] : 0,
        productName: json['product_name'] ?? 'Unknown Product',
        type: json['type'] ?? 'adjustment',
        quantity: json['quantity'] is int ? json['quantity'] : 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: json['user_id'] is int ? json['user_id'] : 0,
        userName: json['user_name'] ?? 'Unknown User',
        quantityBefore: null,
        quantityChange: null,
        quantityAfter: null,
        movementType: null,
        sourceType: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_sku': productSku,
      'type': type,
      'quantity': quantity,
      'previous_stock': previousStock,
      'current_stock': currentStock,
      'reason': reason,
      'notes': notes,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'user_name': userName,
      'quantity_before': quantityBefore?.toString(),
      'quantity_change': quantityChange?.toString(),
      'quantity_after': quantityAfter?.toString(),
      'movement_type': movementType,
      'source_type': sourceType,
    };
  }

  // Helper methods
  String get formattedCreatedAt => _formatDateTime(createdAt);
  String get formattedUpdatedAt => _formatDateTime(updatedAt);
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  String get typeDisplayName {
    switch (type) {
      case 'in':
        return 'Masuk';
      case 'out':
        return 'Keluar';
      case 'adjustment':
        return 'Penyesuaian';
      default:
        return type;
    }
  }

  String get referenceTypeDisplayName {
    switch (referenceType) {
      case 'sale':
        return 'Penjualan';
      case 'purchase':
        return 'Pembelian';
      case 'adjustment':
        return 'Penyesuaian';
      case 'transfer':
        return 'Transfer';
      default:
        return referenceType ?? '-';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'in':
        return Icons.add_circle;
      case 'out':
        return Icons.remove_circle;
      case 'adjustment':
        return Icons.tune;
      default:
        return Icons.swap_horiz;
    }
  }

  Color get typeColor {
    switch (type) {
      case 'in':
        return Colors.green;
      case 'out':
        return Colors.red;
      case 'adjustment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String get quantityDisplay {
    String prefix = '';
    switch (type) {
      case 'in':
        prefix = '+';
        break;
      case 'out':
        prefix = '-';
        break;
      case 'adjustment':
        prefix = quantity >= 0 ? '+' : '';
        break;
    }
    return '$prefix$quantity';
  }

  StockMovement copyWith({
    int? id,
    int? productId,
    String? productName,
    String? productSku,
    String? type,
    int? quantity,
    int? previousStock,
    int? currentStock,
    String? reason,
    String? notes,
    String? referenceType,
    int? referenceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? userId,
    String? userName,
  }) {
    return StockMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      previousStock: previousStock ?? this.previousStock,
      currentStock: currentStock ?? this.currentStock,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
    );
  }
}

// Model untuk request create stock movement
class CreateStockMovementRequest {
  final int productId;
  final int quantity; // Can be positive or negative
  final String sourceType; // Laravel uses source_type instead of type
  final String? reason;
  final String? notes;
  final DateTime movementDate; // Required by Laravel API
  final double? unitCost; // Optional unit cost

  CreateStockMovementRequest({
    required this.productId,
    required this.quantity,
    required this.sourceType,
    this.reason,
    this.notes,
    required this.movementDate,
    this.unitCost,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'source_type': sourceType,
      'reason': reason,
      'notes': notes,
      'movement_date': movementDate.toIso8601String(),
      'unit_cost': unitCost,
    };
  }
}

// Model untuk bulk create stock movements
class BulkCreateStockMovementRequest {
  final DateTime movementDate;
  final String? notes;
  final List<BulkStockMovementItem> stockItems;

  BulkCreateStockMovementRequest({
    required this.movementDate,
    this.notes,
    required this.stockItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'movement_date': movementDate.toIso8601String(),
      'notes': notes,
      'stock_items': stockItems.map((item) => item.toJson()).toList(),
    };
  }
}

// Model untuk item dalam bulk stock movement
class BulkStockMovementItem {
  final int productId;
  final double quantityChange; // Can be positive or negative
  final String sourceType;
  final double? unitCost;
  final String? notes;

  BulkStockMovementItem({
    required this.productId,
    required this.quantityChange,
    required this.sourceType,
    this.unitCost,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity_change': quantityChange,
      'source_type': sourceType,
      'unit_cost': unitCost,
      'notes': notes,
    };
  }
}