import '../utils/format_utils.dart';

class ExpenseCategory {
  final int id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final int userId;
  final int? expensesCount; // Sesuai dengan API response: expenses_count
  final String? totalExpenses; // Sesuai dengan API response: total_expenses
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.isActive,
    required this.userId,
    this.expensesCount,
    this.totalExpenses,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    try {
      return ExpenseCategory(
        id: FormatUtils.safeParseInt(json['id']),
        name: json['name'] ?? '',
        code: json['code'] ?? '',
        description: json['description'],
        isActive: json['is_active'] ?? false,
        userId: FormatUtils.safeParseInt(json['user_id']),
        expensesCount: FormatUtils.safeParseIntNullable(json['expenses_count']),
        totalExpenses: json['total_expenses']?.toString(),
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at']) 
            : DateTime.now(),
        updatedAt: json['updated_at'] != null 
            ? DateTime.parse(json['updated_at']) 
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing ExpenseCategory JSON: $e');
      print('Problematic JSON: $json');
      return ExpenseCategory(
        id: 0,
        name: json['name'] ?? 'Unknown Category',
        code: json['code'] ?? '',
        description: null,
        isActive: false,
        userId: 0,
        expensesCount: null,
        totalExpenses: null,
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
      'user_id': userId,
      'expenses_count': expensesCount ?? 0,
      'total_expenses': totalExpenses ?? '0.00',
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

  // Copy with method untuk update
  ExpenseCategory copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    bool? isActive,
    int? userId,
    int? expensesCount,
    String? totalExpenses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      expensesCount: expensesCount ?? this.expensesCount,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Model untuk pagination response (reuse dari category_model.dart)
class ExpenseCategoryPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  ExpenseCategoryPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory ExpenseCategoryPagination.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryPagination(
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 15,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
    );
  }
}

// Model untuk response API expense categories
class ExpenseCategoryResponse {
  final List<ExpenseCategory> categories;
  final ExpenseCategoryPagination pagination;

  ExpenseCategoryResponse({
    required this.categories,
    required this.pagination,
  });

  factory ExpenseCategoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final categoriesJson = data['categories'] as List<dynamic>? ?? [];
    final paginationJson = data['pagination'] as Map<String, dynamic>? ?? {};

    return ExpenseCategoryResponse(
      categories: categoriesJson
          .map((categoryJson) => ExpenseCategory.fromJson(categoryJson))
          .toList(),
      pagination: ExpenseCategoryPagination.fromJson(paginationJson),
    );
  }
}

// Model untuk single expense category response
class SingleExpenseCategoryResponse {
  final ExpenseCategory category;

  SingleExpenseCategoryResponse({
    required this.category,
  });

  factory SingleExpenseCategoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return SingleExpenseCategoryResponse(
      category: ExpenseCategory.fromJson(data),
    );
  }
}