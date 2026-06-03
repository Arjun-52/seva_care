import '../core/api/api_client.dart';
import '../models/mock_data.dart';
import '../utils/app_logger.dart';

class CareLogsResponse {
  final List<CareLog> logs;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  CareLogsResponse({
    required this.logs,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory CareLogsResponse.fromJson(dynamic data, Map<String, dynamic>? meta) {
    final List<dynamic> dataList = data as List<dynamic>? ?? [];
    final logsList = dataList.map((e) {
      final json = e as Map<String, dynamic>;
      return CareLog(
        id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
        seniorId: json['seniorId'] as String? ?? '',
        time: json['time'] as String? ?? '',
        activity: json['activity'] as String? ?? '',
        who: json['who'] as String? ?? '',
        status: json['status'] as String? ?? '',
        type: json['type'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );
    }).toList();

    int pageVal = 1;
    int limitVal = 20;
    int totalVal = logsList.length;
    int totalPagesVal = 1;

    if (meta != null && meta['pagination'] != null) {
      final pag = meta['pagination'] as Map<String, dynamic>;
      pageVal = pag['page'] as int? ?? 1;
      limitVal = pag['limit'] as int? ?? 20;
      totalVal = pag['total'] as int? ?? logsList.length;
      totalPagesVal = pag['totalPages'] as int? ?? 1;
    }

    return CareLogsResponse(
      logs: logsList,
      page: pageVal,
      limit: limitVal,
      total: totalVal,
      totalPages: totalPagesVal,
    );
  }
}
