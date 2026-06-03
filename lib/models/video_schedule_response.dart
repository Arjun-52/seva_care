class ScheduledVideoCall {
  final String id;
  final String seniorId;
  final String callerId;
  final String meetUrl;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;

  ScheduledVideoCall({
    required this.id,
    required this.seniorId,
    required this.callerId,
    required this.meetUrl,
    required this.status,
    required this.startedAt,
    this.endedAt,
  });

  factory ScheduledVideoCall.fromJson(Map<String, dynamic> json) {
    return ScheduledVideoCall(
      id: json['id']?.toString() ?? '',
      seniorId: json['seniorId']?.toString() ?? '',
      callerId: json['callerId']?.toString() ?? '',
      meetUrl: json['meetUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? 'scheduled',
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seniorId': seniorId,
      'callerId': callerId,
      'meetUrl': meetUrl,
      'status': status,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }
}

class VideoScheduleResponse {
  final bool success;
  final String message;
  final ScheduledVideoCall? data;
  final List<dynamic> errors;
  final Map<String, dynamic> meta;

  VideoScheduleResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
  });

  factory VideoScheduleResponse.fromJson(Map<String, dynamic> json) {
    ScheduledVideoCall? parsedData;
    if (json['data'] != null && json['data'] is Map) {
      parsedData = ScheduledVideoCall.fromJson(
        Map<String, dynamic>.from(json['data'] as Map),
      );
    }

    return VideoScheduleResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      data: parsedData,
      errors: json['errors'] as List<dynamic>? ?? [],
      meta: json['meta'] != null && json['meta'] is Map 
          ? Map<String, dynamic>.from(json['meta'] as Map) 
          : {},
    );
  }
}
