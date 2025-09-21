class Expense {
  final int id;
  final int expenseCategoryId;
  final int warehouseId;
  final int userId;
  final String? reference;
  final DateTime date;
  final double amount;
  final String paymentMethod;
  final String? description;
  final String? attachment;
  final bool isRecurring;
  final String? recurringFrequency;
  final DateTime? recurringEndDate;
  final bool isApproved;
  final int? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ExpenseCategory? category;
  final ExpenseWarehouse? warehouse;
  final ExpenseUser? user;
  final ExpenseUser? approver;

  Expense({
    required this.id,
    required this.expenseCategoryId,
    required this.warehouseId,
    required this.userId,
    this.reference,
    required this.date,
    required this.amount,
    required this.paymentMethod,
    this.description,
    this.attachment,
    required this.isRecurring,
    this.recurringFrequency,
    this.recurringEndDate,
    required this.isApproved,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.warehouse,
    this.user,
    this.approver,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? 0,
      expenseCategoryId: json['expense_category_id'] ?? 0,
      warehouseId: json['warehouse_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      reference: json['reference'],
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      amount: double.parse(json['amount']?.toString() ?? '0'),
      paymentMethod: json['payment_method'] ?? '',
      description: json['description'],
      attachment: json['attachment'],
      isRecurring: json['is_recurring'] ?? false,
      recurringFrequency: json['recurring_frequency'],
      recurringEndDate: json['recurring_end_date'] != null 
          ? DateTime.parse(json['recurring_end_date'])
          : null,
      isApproved: json['is_approved'] ?? false,
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at'])
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      category: json['category'] != null 
          ? ExpenseCategory.fromJson(json['category'])
          : null,
      warehouse: json['warehouse'] != null 
          ? ExpenseWarehouse.fromJson(json['warehouse'])
          : null,
      user: json['user'] != null 
          ? ExpenseUser.fromJson(json['user'])
          : null,
      approver: json['approver'] != null 
          ? ExpenseUser.fromJson(json['approver'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_category_id': expenseCategoryId,
      'warehouse_id': warehouseId,
      'user_id': userId,
      'reference': reference,
      'date': date.toIso8601String(),
      'amount': amount,
      'payment_method': paymentMethod,
      'description': description,
      'attachment': attachment,
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency,
      'recurring_end_date': recurringEndDate?.toIso8601String(),
      'is_approved': isApproved,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'expense_category_id': expenseCategoryId,
      'warehouse_id': warehouseId,
      'user_id': userId, // Added missing user_id field
      'reference': reference,
      'date': date.toIso8601String().split('T')[0], // Format YYYY-MM-DD
      'amount': amount,
      'payment_method': paymentMethod,
      'description': description,
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency,
      'recurring_end_date': recurringEndDate?.toIso8601String().split('T')[0],
    };
  }
}

class ExpenseCategory {
  final int id;
  final String name;
  final String code;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.code,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }
}

class ExpenseWarehouse {
  final int id;
  final String name;
  final String code;

  ExpenseWarehouse({
    required this.id,
    required this.name,
    required this.code,
  });

  factory ExpenseWarehouse.fromJson(Map<String, dynamic> json) {
    return ExpenseWarehouse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }
}

class ExpenseUser {
  final int id;
  final String name;
  final String email;

  ExpenseUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ExpenseUser.fromJson(Map<String, dynamic> json) {
    return ExpenseUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class ExpenseResponse {
  final List<Expense> expenses;
  final ExpensePagination pagination;

  ExpenseResponse({
    required this.expenses,
    required this.pagination,
  });

  factory ExpenseResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return ExpenseResponse(
      expenses: (data['expenses'] as List<dynamic>?)
          ?.map((item) => Expense.fromJson(item))
          .toList() ?? [],
      pagination: ExpensePagination.fromJson(data['pagination'] ?? {}),
    );
  }
}

class ExpensePagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  ExpensePagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory ExpensePagination.fromJson(Map<String, dynamic> json) {
    return ExpensePagination(
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 15,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
    );
  }
}

class ExpenseStatistics {
  final ExpenseStatisticsPeriod period;
  final ExpenseStatisticsSummary summary;
  final List<ExpenseStatisticsByCategory> byCategory;
  final List<ExpenseStatisticsByPaymentMethod> byPaymentMethod;

  ExpenseStatistics({
    required this.period,
    required this.summary,
    required this.byCategory,
    required this.byPaymentMethod,
  });

  factory ExpenseStatistics.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return ExpenseStatistics(
      period: ExpenseStatisticsPeriod.fromJson(data['period'] ?? {}),
      summary: ExpenseStatisticsSummary.fromJson(data['summary'] ?? {}),
      byCategory: (data['by_category'] as List<dynamic>?)
          ?.map((item) => ExpenseStatisticsByCategory.fromJson(item))
          .toList() ?? [],
      byPaymentMethod: (data['by_payment_method'] as List<dynamic>?)
          ?.map((item) => ExpenseStatisticsByPaymentMethod.fromJson(item))
          .toList() ?? [],
    );
  }
}

class ExpenseStatisticsPeriod {
  final DateTime startDate;
  final DateTime endDate;

  ExpenseStatisticsPeriod({
    required this.startDate,
    required this.endDate,
  });

  factory ExpenseStatisticsPeriod.fromJson(Map<String, dynamic> json) {
    return ExpenseStatisticsPeriod(
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ExpenseStatisticsSummary {
  final double totalExpenses;
  final int totalCount;
  final double approvedExpenses;
  final double pendingExpenses;

  ExpenseStatisticsSummary({
    required this.totalExpenses,
    required this.totalCount,
    required this.approvedExpenses,
    required this.pendingExpenses,
  });

  factory ExpenseStatisticsSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseStatisticsSummary(
      totalExpenses: double.parse(json['total_expenses']?.toString() ?? '0'),
      totalCount: json['total_count'] ?? 0,
      approvedExpenses: double.parse(json['approved_expenses']?.toString() ?? '0'),
      pendingExpenses: double.parse(json['pending_expenses']?.toString() ?? '0'),
    );
  }
}

class ExpenseStatisticsByCategory {
  final String category;
  final double totalAmount;
  final int count;

  ExpenseStatisticsByCategory({
    required this.category,
    required this.totalAmount,
    required this.count,
  });

  factory ExpenseStatisticsByCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseStatisticsByCategory(
      category: json['category'] ?? '',
      totalAmount: double.parse(json['total_amount']?.toString() ?? '0'),
      count: json['count'] ?? 0,
    );
  }
}

class ExpenseStatisticsByPaymentMethod {
  final String paymentMethod;
  final double totalAmount;
  final int count;

  ExpenseStatisticsByPaymentMethod({
    required this.paymentMethod,
    required this.totalAmount,
    required this.count,
  });

  factory ExpenseStatisticsByPaymentMethod.fromJson(Map<String, dynamic> json) {
    return ExpenseStatisticsByPaymentMethod(
      paymentMethod: json['payment_method'] ?? '',
      totalAmount: double.parse(json['total_amount']?.toString() ?? '0'),
      count: json['count'] ?? 0,
    );
  }
}