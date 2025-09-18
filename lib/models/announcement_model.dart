class Announcement {
  final int id;
  final String title;
  final String content;
  final String type;
  final String status;
  final bool isActive;
  final bool isPinned;
  final int priority;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> targetAudience;
  final String? imageUrl;
  final String? linkUrl;
  final String? linkText;
  final int viewCount;
  final int clickCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.status,
    required this.isActive,
    required this.isPinned,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.targetAudience,
    this.imageUrl,
    this.linkUrl,
    this.linkText,
    required this.viewCount,
    required this.clickCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'info',
      status: json['status'] ?? 'active',
      isActive: json['is_active'] ?? true,
      isPinned: json['is_pinned'] ?? false,
      priority: json['priority'] ?? 0,
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'])
          : DateTime.now().add(const Duration(days: 30)),
      targetAudience: json['target_audience'] != null
          ? List<String>.from(json['target_audience'])
          : [],
      imageUrl: json['image_url'],
      linkUrl: json['link_url'],
      linkText: json['link_text'],
      viewCount: json['view_count'] ?? 0,
      clickCount: json['click_count'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'status': status,
      'is_active': isActive,
      'is_pinned': isPinned,
      'priority': priority,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'target_audience': targetAudience,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'link_text': linkText,
      'view_count': viewCount,
      'click_count': clickCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for display
  String get typeDisplayName {
    switch (type) {
      case 'info':
        return 'Info';
      case 'feature':
        return 'Fitur';
      case 'maintenance':
        return 'Maintenance';
      case 'promotion':
        return 'Promosi';
      case 'warning':
        return 'Peringatan';
      case 'tip':
        return 'Tips';
      default:
        return type.toUpperCase();
    }
  }

  String get formattedDate {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${createdAt.day} ${months[createdAt.month]} ${createdAt.year}';
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

  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  bool get isUpcoming {
    return DateTime.now().isBefore(startDate);
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(startDate) && 
           now.isBefore(endDate) && 
           status == 'active';
  }
}

class AnnouncementResponse {
  final bool success;
  final List<Announcement> data;
  final String? message;
  final int? total;
  final int? page;
  final int? limit;

  AnnouncementResponse({
    required this.success,
    required this.data,
    this.message,
    this.total,
    this.page,
    this.limit,
  });

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Announcement.fromJson(item))
          .toList() ?? [],
      message: json['message'],
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((item) => item.toJson()).toList(),
      'message': message,
      'total': total,
      'page': page,
      'limit': limit,
    };
  }
}