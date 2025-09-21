import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense_model.dart';
import '../config/api_config.dart';

class ExpenseService {
  final String expensesEndpoint = '${ApiConfig.baseUrl}/expenses';
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Menambahkan token ke header
  void setToken(String token) {
    headers['Authorization'] = 'Bearer $token';
    print('ExpenseService: Token set in headers - Bearer ${token.substring(0, 10)}...');
    headers.forEach((key, value) {
      print('ExpenseService: Header - $key: ${key.toLowerCase() == 'authorization' ? "Bearer ${value.substring(7, 17)}..." : value}');
    });
  }

  // 1. Get All Expenses - GET /api/expenses
  Future<ExpenseResponse> getExpenses({
    String? search,
    String? startDate,
    String? endDate,
    int? expenseCategoryId,
    int? warehouseId,
    String? paymentMethod,
    bool? isApproved,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      // Membangun query parameters
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }
      if (expenseCategoryId != null) {
        queryParams['expense_category_id'] = expenseCategoryId.toString();
      }
      if (warehouseId != null) {
        queryParams['warehouse_id'] = warehouseId.toString();
      }
      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        queryParams['payment_method'] = paymentMethod;
      }
      if (isApproved != null) {
        queryParams['is_approved'] = isApproved.toString();
      }
      if (minAmount != null) {
        queryParams['min_amount'] = minAmount.toString();
      }
      if (maxAmount != null) {
        queryParams['max_amount'] = maxAmount.toString();
      }
      queryParams['page'] = page.toString();
      queryParams['per_page'] = perPage.toString();

      // Membuat URL dengan query parameters
      final uriComponents = Uri.parse(expensesEndpoint);
      
      Uri uri;
      if (uriComponents.scheme == 'https') {
        uri = Uri.https(
          uriComponents.authority,
          uriComponents.path,
          queryParams,
        );
      } else {
        uri = Uri.http(
          uriComponents.authority,
          uriComponents.path,
          queryParams,
        );
      }

      print('ExpenseService: Making GET request to: $uri');
      print('ExpenseService: Query params: $queryParams');

      final response = await http.get(uri, headers: headers);

      print('ExpenseService: Response status: ${response.statusCode}');
      print('ExpenseService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return ExpenseResponse.fromJson(jsonData);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch expenses');
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error occurred';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('ExpenseService: Error in getExpenses - $e');
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  // 2. Create Expense - POST /api/expenses
  Future<Expense> createExpense(Expense expense) async {
    try {
      print('ExpenseService: Creating expense with data: ${expense.toCreateJson()}');

      final response = await http.post(
        Uri.parse(expensesEndpoint),
        headers: headers,
        body: json.encode(expense.toCreateJson()),
      );

      print('ExpenseService: Create response status: ${response.statusCode}');
      print('ExpenseService: Create response body: ${response.body}');

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return Expense.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to create expense');
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          String errorMessage = errorData['message'] ?? 'Unknown error occurred';
          
          // Handle validation errors specifically
          if (response.statusCode == 422 && errorData['errors'] != null) {
            Map<String, dynamic> errors = errorData['errors'];
            List<String> errorMessages = [];
            errors.forEach((field, messages) {
              if (messages is List) {
                errorMessages.addAll(messages.map((msg) => '$field: $msg'));
              } else {
                errorMessages.add('$field: $messages');
              }
            });
            errorMessage = 'Validation Failed: ${errorMessages.join(', ')}';
          }
          
          throw Exception(errorMessage);
        } catch (jsonError) {
          // If response body is not valid JSON
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      print('ExpenseService: Error in createExpense - $e');
      if (e.toString().contains('Exception:')) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception('Failed to create expense: $e');
    }
  }

  // 3. Get Expense Details - GET /api/expenses/{id}
  Future<Expense> getExpenseById(int id) async {
    try {
      print('ExpenseService: Getting expense by ID: $id');

      final response = await http.get(
        Uri.parse('$expensesEndpoint/$id'),
        headers: headers,
      );

      print('ExpenseService: Get by ID response status: ${response.statusCode}');
      print('ExpenseService: Get by ID response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return Expense.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch expense');
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error occurred';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('ExpenseService: Error in getExpenseById - $e');
      throw Exception('Failed to fetch expense: $e');
    }
  }

  // 4. Update Expense - PUT /api/expenses/{id}
  Future<Expense> updateExpense(int id, Expense expense) async {
    try {
      print('ExpenseService: Updating expense $id with data: ${expense.toCreateJson()}');

      final response = await http.put(
        Uri.parse('$expensesEndpoint/$id'),
        headers: headers,
        body: json.encode(expense.toCreateJson()),
      );

      print('ExpenseService: Update response status: ${response.statusCode}');
      print('ExpenseService: Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return Expense.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to update expense');
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error occurred';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('ExpenseService: Error in updateExpense - $e');
      throw Exception('Failed to update expense: $e');
    }
  }

  // 5. Delete Expense - DELETE /api/expenses/{id}
  Future<bool> deleteExpense(int id) async {
    try {
      print('ExpenseService: Deleting expense with ID: $id');

      final response = await http.delete(
        Uri.parse('$expensesEndpoint/$id'),
        headers: headers,
      );

      print('ExpenseService: Delete response status: ${response.statusCode}');
      print('ExpenseService: Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error occurred';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('ExpenseService: Error in deleteExpense - $e');
      throw Exception('Failed to delete expense: $e');
    }
  }

  // 6. Approve Expense - POST /api/expenses/{id}/approve
  Future<Expense> approveExpense(int id) async {
    try {
      print('ExpenseService: Approving expense with ID: $id');

      final response = await http.post(
        Uri.parse('$expensesEndpoint/$id/approve'),
        headers: headers,
      );

      print('ExpenseService: Approve response status: ${response.statusCode}');
      print('ExpenseService: Approve response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return Expense.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to approve expense');
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error occurred';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('ExpenseService: Error in approveExpense - $e');
      throw Exception('Failed to approve expense: $e');
    }
  }

  // 7. Get Expense Statistics - GET /api/expenses/statistics/summary
  Future<ExpenseStatistics> getExpenseStatistics({
    String? startDate,
    String? endDate,
  }) async {
    try {
      // Membangun query parameters
      final queryParams = <String, String>{};
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      // Membuat URL dengan query parameters
      final statisticsEndpoint = '$expensesEndpoint/statistics/summary';
      final uriComponents = Uri.parse(statisticsEndpoint);
      
      Uri uri;
      if (uriComponents.scheme == 'https') {
        uri = Uri.https(
          uriComponents.authority,
          uriComponents.path,
          queryParams,
        );
      } else {
        uri = Uri.http(
          uriComponents.authority,
          uriComponents.path,
          queryParams,
        );
      }

      print('ExpenseService: Making GET request to statistics: $uri');

      final response = await http.get(uri, headers: headers);

      print('ExpenseService: Statistics response status: ${response.statusCode}');
      print('ExpenseService: Statistics response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return ExpenseStatistics.fromJson(jsonData);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch expense statistics');
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error occurred';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('ExpenseService: Error in getExpenseStatistics - $e');
      throw Exception('Failed to fetch expense statistics: $e');
    }
  }

  // 8. Bulk Delete Expenses
  Future<bool> bulkDeleteExpenses(List<int> expenseIds) async {
    try {
      print('ExpenseService: Bulk deleting expenses: $expenseIds');

      bool allDeleted = true;
      for (int id in expenseIds) {
        final success = await deleteExpense(id);
        if (!success) {
          allDeleted = false;
          print('ExpenseService: Failed to delete expense $id');
        }
      }

      return allDeleted;
    } catch (e) {
      print('ExpenseService: Error in bulkDeleteExpenses - $e');
      throw Exception('Failed to bulk delete expenses: $e');
    }
  }

  // 9. Get Payment Methods for Dropdown
  List<Map<String, String>> getPaymentMethods() {
    return [
      {'value': 'cash', 'label': 'Tunai'},
      {'value': 'bank_transfer', 'label': 'Transfer Bank'},
      {'value': 'credit_card', 'label': 'Kartu Kredit'},
    ];
  }

  // 10. Get Recurring Frequencies for Dropdown
  List<Map<String, String>> getRecurringFrequencies() {
    return [
      {'value': 'daily', 'label': 'Harian'},
      {'value': 'weekly', 'label': 'Mingguan'},
      {'value': 'monthly', 'label': 'Bulanan'},
      {'value': 'yearly', 'label': 'Tahunan'},
    ];
  }
}