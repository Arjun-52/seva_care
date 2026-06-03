class Senior {
  final String id;
  final String name;
  final String city;
  final String phone;

  Senior({
    required this.id,
    required this.name,
    required this.city,
    required this.phone,
  });

  factory Senior.fromJson(Map<String, dynamic> json) {
    return Senior(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'phone': phone,
    };
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
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

class EmergencyAlert {
  final String id;
  final String seniorId;
  final String type;
  final String severity;
  final String status;
  final String triggeredBy;
  final String? responderId;
  final int? etaMinutes;
  final double? locationLat;
  final double? locationLng;
  final String? resolvedAt;
  final String? resolutionNotes;
  final int? responseTimeMinutes;
  final String? escalatedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Senior? senior;
  final Map<String, dynamic>? responder;

  EmergencyAlert({
    required this.id,
    required this.seniorId,
    required this.type,
    required this.severity,
    required this.status,
    required this.triggeredBy,
    this.responderId,
    this.etaMinutes,
    this.locationLat,
    this.locationLng,
    this.resolvedAt,
    this.resolutionNotes,
    this.responseTimeMinutes,
    this.escalatedTo,
    required this.createdAt,
    required this.updatedAt,
    this.senior,
    this.responder,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'] as String? ?? '',
      seniorId: json['seniorId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'pending',
      triggeredBy: json['triggeredBy'] as String? ?? 'family',
      responderId: json['responderId'] as String?,
      etaMinutes: json['etaMinutes'] as int?,
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLng: (json['locationLng'] as num?)?.toDouble(),
      resolvedAt: json['resolvedAt'] as String?,
      resolutionNotes: json['resolutionNotes'] as String?,
      responseTimeMinutes: json['responseTimeMinutes'] as int?,
      escalatedTo: json['escalatedTo'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      senior: json['senior'] != null ? Senior.fromJson(json['senior'] as Map<String, dynamic>) : null,
      responder: json['responder'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seniorId': seniorId,
      'type': type,
      'severity': severity,
      'status': status,
      'triggeredBy': triggeredBy,
      'responderId': responderId,
      'etaMinutes': etaMinutes,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'resolvedAt': resolvedAt,
      'resolutionNotes': resolutionNotes,
      'responseTimeMinutes': responseTimeMinutes,
      'escalatedTo': escalatedTo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'senior': senior?.toJson(),
      'responder': responder,
    };
  }
}

class EmergencyAlertsResponse {
  final bool success;
  final String message;
  final List<EmergencyAlert> alerts;
  final List<dynamic> errors;
  final Pagination pagination;

  EmergencyAlertsResponse({
    required this.success,
    required this.message,
    required this.alerts,
    required this.errors,
    required this.pagination,
  });

  factory EmergencyAlertsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] as List<dynamic>? ?? [];
    final List<EmergencyAlert> parsedAlerts = dataList
        .map((e) => EmergencyAlert.fromJson(e as Map<String, dynamic>))
        .toList();

    Map<String, dynamic> paginationJson = {};
    if (json['meta'] != null && json['meta']['pagination'] != null) {
      paginationJson = json['meta']['pagination'] as Map<String, dynamic>;
    }

    return EmergencyAlertsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      alerts: parsedAlerts,
      errors: json['errors'] as List<dynamic>? ?? [],
      pagination: Pagination.fromJson(paginationJson),
    );
  }
}
