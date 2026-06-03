import '../models/mock_data.dart';

class CareLogSummary {
  final int total;
  final int completed;
  final int active;
  final int pending;
  final int missed;

  CareLogSummary({
    required this.total,
    required this.completed,
    required this.active,
    required this.pending,
    required this.missed,
  });

  factory CareLogSummary.fromJson(Map<String, dynamic> json) {
    return CareLogSummary(
      total: json['total'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      missed: json['missed'] as int? ?? 0,
    );
  }
}

class TodayCareLogData {
  final List<CareLog> logs;
  final CareLogSummary summary;

  TodayCareLogData({
    required this.logs,
    required this.summary,
  });

  factory TodayCareLogData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> logsJson = json['logs'] as List<dynamic>? ?? [];
    final logsList = logsJson.map((e) {
      final item = e as Map<String, dynamic>;
      return CareLog(
        id: item['id'] is int ? item['id'] as int : int.parse(item['id'].toString()),
        seniorId: item['seniorId'] as String? ?? '',
        time: item['time'] as String? ?? '',
        activity: item['activity'] as String? ?? '',
        who: item['who'] as String? ?? '',
        status: item['status'] as String? ?? '',
        type: item['type'] as String? ?? '',
        notes: item['notes'] as String? ?? '',
      );
    }).toList();

    return TodayCareLogData(
      logs: logsList,
      summary: CareLogSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class CareLogTodayResponse {
  final bool success;
  final String message;
  final TodayCareLogData? data;
  final List<dynamic> errors;
  final Map<String, dynamic> meta;

  CareLogTodayResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
  });

  factory CareLogTodayResponse.fromJson(Map<String, dynamic> json) {
    return CareLogTodayResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? TodayCareLogData.fromJson(json['data'] as Map<String, dynamic>) : null,
      errors: json['errors'] as List<dynamic>? ?? [],
      meta: json['meta'] as Map<String, dynamic>? ?? {},
    );
  }
}
