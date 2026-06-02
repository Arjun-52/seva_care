class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? json['body'] as String? ?? '',
      type: json['type'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['time'] != null
              ? DateTime.parse(json['time'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PaginationModel {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
    };
  }
}

class NotificationResponseModel {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final PaginationModel pagination;

  NotificationResponseModel({
    required this.notifications,
    required this.unreadCount,
    required this.pagination,
  });

  factory NotificationResponseModel.fromJson(dynamic data, Map<String, dynamic>? pagination) {
    final rawList = data as List<dynamic>? ?? [];
    final notificationsList = rawList
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final localUnreadCount = notificationsList.where((n) => !n.isRead).length;

    return NotificationResponseModel(
      notifications: notificationsList,
      unreadCount: localUnreadCount,
      pagination: PaginationModel.fromJson(pagination ?? {}),
    );
  }
}
