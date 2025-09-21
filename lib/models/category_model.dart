import '../utils/format_utils.dart';

class Category {
  final int id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final int? productsCount; // Sesuai dengan API response: products_count
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.isActive,
    this.productsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      return Category(
        id: FormatUtils.safeParseInt(json['id']),
        name: json['name'] ?? '',
        code: json['code'] ?? '',
        description: json['description'],
        isActive: json['is_active'] ?? false,
        productsCount: FormatUtils.safeParseIntNullable(json['products_count']),
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
        code: json['code'] ?? '',
        description: null,
        isActive: false,
        productsCount: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive,
      'products_count': productsCount ?? 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Method untuk create request body
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive,
    };
  }

  // Method untuk update request body
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive,
    };
  }
}

// Model untuk pagination response
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
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 15,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
    );
  }
}

// Model untuk response API categories
class CategoryResponse {
  final List<Category> categories;
  final Pagination pagination;

  CategoryResponse({
    required this.categories,
    required this.pagination,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final categoriesJson = data['categories'] as List<dynamic>? ?? [];
    final paginationJson = data['pagination'] as Map<String, dynamic>? ?? {};

    return CategoryResponse(
      categories: categoriesJson
          .map((categoryJson) => Category.fromJson(categoryJson))
          .toList(),
      pagination: Pagination.fromJson(paginationJson),
    );
  }
}