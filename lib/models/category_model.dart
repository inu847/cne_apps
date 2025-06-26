import '../utils/format_utils.dart';

class Category {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final int? productCount; // Bisa null
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.productCount, // Tidak required lagi karena bisa null
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      return Category(
        id: FormatUtils.safeParseInt(json['id']),
        name: json['name'] ?? '',
        description: json['description'],
        isActive: json['is_active'] ?? false,
        productCount: FormatUtils.safeParseIntNullable(json['product_count']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing Category JSON: $e');
      print('Problematic JSON: $json');
      return Category(
        id: 0,
        name: json['name'] ?? 'Unknown Category',
        description: null,
        isActive: false,
        productCount: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'product_count': productCount ?? 0, // Default ke 0 jika null
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}