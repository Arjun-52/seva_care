class SosAlert {
  final String alertId;
  final String status;
  final String? responder;
  final String emergencyNumber;

  SosAlert({
    required this.alertId,
    required this.status,
    this.responder,
    required this.emergencyNumber,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    return SosAlert(
      alertId: json['alertId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      responder: json['responder'] as String?,
      emergencyNumber: json['emergencyNumber'] as String? ?? '112',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'status': status,
      'responder': responder,
      'emergencyNumber': emergencyNumber,
    };
  }
}

class SosResponse {
  final bool success;
  final String message;
  final SosAlert? data;
  final List<dynamic> errors;
  final Map<String, dynamic> meta;

  SosResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
  });

  factory SosResponse.fromJson(Map<String, dynamic> json) {
    return SosResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? SosAlert.fromJson(json['data'] as Map<String, dynamic>) : null,
      errors: json['errors'] as List<dynamic>? ?? [],
      meta: json['meta'] as Map<String, dynamic>? ?? {},
    );
  }
}
