import '../utils/format_utils.dart';

class User {
  final int id;
  final String name;
  final String email;
  final int? warehouseId;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.warehouseId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: FormatUtils.safeParseInt(json['id']),
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        warehouseId: json['warehouse_id'] != null ? FormatUtils.safeParseInt(json['warehouse_id']) : null,
      );
    } catch (e) {
      print('Error parsing User JSON: $e');
      print('Problematic JSON: $json');
      return User(
        id: 0,
        name: json['name'] ?? 'Unknown User',
        email: json['email'] ?? 'unknown@example.com',
        warehouseId: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'warehouse_id': warehouseId,
    };
  }
}

class AuthResponse {
  final bool success;
  final AuthData? data;
  final String? message;

  AuthResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'],
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
      message: json['message'],
    );
  }
}

class AuthData {
  final String token;
  final User user;

  AuthData({
    required this.token,
    required this.user,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      token: json['token'],
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}