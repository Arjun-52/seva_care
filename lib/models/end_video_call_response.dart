import 'video_calls_response.dart';

class EndVideoCallResponse {
  final bool success;
  final String message;
  final VideoCall? data;
  final List<dynamic> errors;
  final Map<String, dynamic> meta;

  EndVideoCallResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
  });

  factory EndVideoCallResponse.fromJson(Map<String, dynamic> json) {
    VideoCall? parsedData;
    if (json['data'] != null && json['data'] is Map) {
      parsedData = VideoCall.fromJson(
        Map<String, dynamic>.from(json['data'] as Map),
      );
    }

    return EndVideoCallResponse(
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
