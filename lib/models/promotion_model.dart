class Promotion {
  final int id;
  final String title;
  final String description;
  final String content;
  final String? imageUrl;
  final String? bannerUrl;
  final String type;
  final String status;
  final double? discountPercentage;
  final String? discountAmount;
  final String? promoCode;
  final String? linkUrl;
  final String? linkText;
  final bool isFeatured;
  final int viewCount;
  final int clickCount;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> targetAudience;
  final List<String> termsConditions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    this.imageUrl,
    this.bannerUrl,
    required this.type,
    required this.status,
    this.discountPercentage,
    this.discountAmount,
    this.promoCode,
    this.linkUrl,
    this.linkText,
    required this.isFeatured,
    required this.viewCount,
    required this.clickCount,
    required this.startDate,
    required this.endDate,
    required this.targetAudience,
    required this.termsConditions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      bannerUrl: json['banner_url'],
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      discountPercentage: json['discount_percentage'] != null 
          ? double.tryParse(json['discount_percentage'].toString()) 
          : null,
      discountAmount: json['discount_amount'],
      promoCode: json['promo_code'],
      linkUrl: json['link_url'],
      linkText: json['link_text'],
      isFeatured: json['is_featured'] ?? false,
      viewCount: json['view_count'] ?? 0,
      clickCount: json['click_count'] ?? 0,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      targetAudience: List<String>.from(json['target_audience'] ?? []),
      termsConditions: List<String>.from(json['terms_conditions'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'image_url': imageUrl,
      'banner_url': bannerUrl,
      'type': type,
      'status': status,
      'discount_percentage': discountPercentage?.toString(),
      'discount_amount': discountAmount,
      'promo_code': promoCode,
      'link_url': linkUrl,
      'link_text': linkText,
      'is_featured': isFeatured,
      'view_count': viewCount,
      'click_count': clickCount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'target_audience': targetAudience,
      'terms_conditions': termsConditions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isActive => status == 'active';
  
  bool get isExpired => DateTime.now().isAfter(endDate);
  
  bool get isUpcoming => DateTime.now().isBefore(startDate);
  
  bool get isCurrentlyValid => 
      isActive && !isExpired && !isUpcoming;
  
  String get formattedDiscountText {
    if (discountPercentage != null) {
      return '${discountPercentage!.toStringAsFixed(0)}% OFF';
    } else if (discountAmount != null) {
      return 'Rp ${_formatCurrency(double.tryParse(discountAmount!) ?? 0)}';
    }
    return '';
  }
  
  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}rb';
    }
    return amount.toStringAsFixed(0);
  }
  
  String get typeDisplayName {
    switch (type) {
      case 'discount':
        return 'Diskon';
      case 'cashback':
        return 'Cashback';
      case 'special_offer':
        return 'Penawaran Khusus';
      default:
        return type;
    }
  }
  
  String get formattedEndDate {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${endDate.day} ${months[endDate.month]} ${endDate.year}';
  }
  
  String get formattedDateRange {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    final startFormatted = '${startDate.day} ${months[startDate.month]} ${startDate.year}';
    final endFormatted = '${endDate.day} ${months[endDate.month]} ${endDate.year}';
    
    return '$startFormatted - $endFormatted';
  }
}

class PromotionResponse {
  final bool success;
  final List<Promotion> data;
  final String? message;

  PromotionResponse({
    required this.success,
    required this.data,
    this.message,
  });

  factory PromotionResponse.fromJson(Map<String, dynamic> json) {
    return PromotionResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Promotion.fromJson(item))
          .toList() ?? [],
      message: json['message'],
    );
  }
}