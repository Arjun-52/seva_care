class Caller {
  final String id;
  final String name;
  final String role;

  Caller({
    required this.id,
    required this.name,
    required this.role,
  });

  factory Caller.fromJson(Map<String, dynamic> json) {
    return Caller(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
    };
  }
}

class VideoCall {
  final String id;
  final String seniorId;
  final String callerId;
  final String meetUrl;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Caller? caller;

  VideoCall({
    required this.id,
    required this.seniorId,
    required this.callerId,
    required this.meetUrl,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.caller,
  });

  factory VideoCall.fromJson(Map<String, dynamic> json) {
    return VideoCall(
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
      caller: json['caller'] != null && json['caller'] is Map
          ? Caller.fromJson(Map<String, dynamic>.from(json['caller'] as Map))
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
      'caller': caller?.toJson(),
    };
  }
}

class VideoCallsResponse {
  final bool success;
  final String message;
  final List<VideoCall> videoCalls;
  final List<dynamic> errors;
  final Map<String, dynamic> meta;

  VideoCallsResponse({
    required this.success,
    required this.message,
    required this.videoCalls,
    required this.errors,
    required this.meta,
  });

  factory VideoCallsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] as List<dynamic>? ?? [];
    final List<VideoCall> parsedCalls = dataList
        .map((e) => VideoCall.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return VideoCallsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      videoCalls: parsedCalls,
      errors: json['errors'] as List<dynamic>? ?? [],
      meta: json['meta'] != null && json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : {},
    );
  }
}
