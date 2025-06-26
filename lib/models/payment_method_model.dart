class PaymentMethod {
  final int id;
  final String name;
  final String code;
  final String description;
  final bool isActive;
  final bool requiresVerification;
  final String createdAt;
  final String updatedAt;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.isActive,
    required this.requiresVerification,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
      isActive: json['is_active'],
      requiresVerification: json['requires_verification'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive,
      'requires_verification': requiresVerification,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}