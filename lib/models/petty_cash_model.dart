class PettyCash {
  final int? id;
  final String name;
  final double amount;
  final String type; // 'opening' atau 'closing'
  final String status; // 'active', 'closed'
  final DateTime? date;
  final int? userId;
  final String? userName;
  final int? warehouseId;
  final String? warehouseName;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PettyCash({
    this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.status,
    this.date,
    this.userId,
    this.userName,
    this.warehouseId,
    this.warehouseName,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory PettyCash.fromJson(Map<String, dynamic> json) {
    return PettyCash(
      id: json['id'],
      name: json['name'] ?? '',
      amount: (json['amount'] is String) 
          ? double.tryParse(json['amount']) ?? 0.0
          : (json['amount'] ?? 0.0).toDouble(),
      type: json['type'] ?? 'opening',
      status: json['status'] ?? 'active',
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      userId: json['user_id'],
      userName: json['user'] != null && json['user'] is Map
          ? json['user']['name']
          : json['user_name'],
      warehouseId: json['warehouse_id'],
      warehouseName: json['warehouse'] != null && json['warehouse'] is Map
          ? json['warehouse']['name']
          : json['warehouse_name'],
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'type': type,
      'status': status,
      'date': date?.toIso8601String(),
      'user_id': userId,
      'user_name': userName,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods
  bool get isOpening => type == 'opening';
  bool get isClosing => type == 'closing';
  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';

  @override
  String toString() {
    return 'PettyCash{id: $id, name: $name, amount: $amount, type: $type, status: $status}';
  }
}

class PettyCashRequest {
  final String name;
  final double amount;
  final String type;
  final String date;
  final String? notes;
  final int? warehouseId;

  PettyCashRequest({
    required this.name,
    required this.amount,
    required this.type,
    required this.date,
    this.notes,
    this.warehouseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'type': type,
      'date': date,
      'notes': notes,
      'warehouse_id': warehouseId,
    };
  }
}

class PettyCashResponse {
  final bool success;
  final String message;
  final PettyCash? data;

  PettyCashResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PettyCashResponse.fromJson(Map<String, dynamic> json) {
    return PettyCashResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PettyCash.fromJson(json['data']) : null,
    );
  }
}